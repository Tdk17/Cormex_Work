'use strict';
const { DateTime } = require('luxon');
const C = require('./core');

const activeStates = ['pending', 'confirmed', 'in_progress'];
const transitions = Object.freeze({
  pending: ['confirmed', 'canceled_by_customer', 'canceled_by_business'],
  confirmed: ['in_progress', 'completed', 'canceled_by_customer', 'canceled_by_business', 'no_show'],
  in_progress: ['completed', 'canceled_by_business'],
  completed: [], canceled_by_customer: [], canceled_by_business: [], no_show: [],
});

const view = b => ({ id: b.id, workspaceId: b.get('workspace').id,
  serviceId: b.get('service').id, customerId: b.get('customer').id,
  resourceId: b.get('resource')?.id || null, status: b.get('status'),
  startAt: b.get('startAtUTC').toISOString(), endAt: b.get('endAtUTC').toISOString(),
  timezone: b.get('timezone'), serviceName: b.get('serviceSnapshot')?.name,
  priceAmount: b.get('priceSnapshot')?.amount, currency: b.get('priceSnapshot')?.currency,
  createdAt: b.createdAt?.toISOString() });

async function publicWorkspace(id) {
  const workspace = await C.get('Workspace', C.requireText(id, 'workspaceId', 64))
    .catch(() => C.fail('WORKSPACE_NOT_FOUND', 'Empresa não encontrada.'));
  if (!workspace.get('publicProfileEnabled') ||
      !['active', 'trial'].includes(workspace.get('status')))
    C.fail('WORKSPACE_NOT_FOUND', 'Empresa não encontrada.');
  return workspace;
}

async function serviceFor(workspace, id) {
  const service = await C.get('Service', C.requireText(id, 'serviceId', 64))
    .catch(() => C.fail('SERVICE_NOT_FOUND', 'Serviço não encontrado.'));
  if (service.get('workspace')?.id !== workspace.id || service.get('active') !== true)
    C.fail('SERVICE_NOT_FOUND', 'Serviço não encontrado.');
  return service;
}

async function resourceFor(workspace, service, id) {
  const type = service.get('requiredResourceType');
  if (!id) {
    if (type) C.fail('VALIDATION_ERROR', 'Escolha um recurso disponível.');
    return null;
  }
  const resource = await C.get('Resource', C.requireText(id, 'resourceId', 64));
  if (resource.get('workspace')?.id !== workspace.id ||
      resource.get('active') !== true || (type && resource.get('type') !== type))
    C.fail('VALIDATION_ERROR', 'Recurso indisponível.');
  return resource;
}

async function bookingsInRange(workspace, start, end) {
  const query = C.q('Booking');
  query.equalTo('workspace', workspace);
  query.containedIn('status', activeStates);
  query.lessThan('startAtUTC', end.toJSDate());
  query.greaterThan('blockedUntilUTC', start.toJSDate());
  query.limit(1000);
  const results = await C.all(query);
  if (results.length >= 1000) C.fail('RATE_LIMITED', 'Agenda muito ocupada. Refine a busca.');
  return results;
}

function overlaps(existing, start, end, resource) {
  return existing.some(b => {
    const sameResource = !b.get('resource') || !resource || b.get('resource').id === resource.id;
    return sameResource && b.get('startAtUTC').getTime() < end.toMillis() &&
      b.get('blockedUntilUTC').getTime() > start.toMillis();
  });
}

async function slots(workspace, service, dayText, resource) {
  if (typeof dayText !== 'string' || !/^\d{4}-\d\d-\d\d$/.test(dayText))
    C.fail('VALIDATION_ERROR', 'Data inválida.');
  const zone = workspace.get('timezone');
  const day = DateTime.fromISO(dayText, { zone });
  if (!day.isValid || day.toISODate() !== dayText || day < DateTime.now().setZone(zone).startOf('day') ||
      day > DateTime.now().setZone(zone).plus({ days: 90 }).endOf('day'))
    C.fail('VALIDATION_ERROR', 'Escolha uma data nos próximos 90 dias.');
  const hoursQ = C.q('BusinessHours');
  hoursQ.equalTo('workspace', workspace);
  hoursQ.equalTo('weekday', day.weekday);
  const hours = await C.one(hoursQ);
  const existing = await bookingsInRange(workspace, day.startOf('day').toUTC(),
    day.plus({ days: 1 }).startOf('day').toUTC());
  const duration = service.get('durationMinutes');
  const buffer = service.get('bufferAfterMinutes') || 0;
  const result = [];
  for (const interval of hours?.get('intervals') || []) {
    let local = DateTime.fromISO(dayText + 'T' + interval.start, { zone });
    const close = DateTime.fromISO(dayText + 'T' + interval.end, { zone });
    while (local.plus({ minutes: duration + buffer }) <= close) {
      const end = local.plus({ minutes: duration + buffer });
      if (local.toISODate() === dayText && local > DateTime.now().setZone(zone) &&
          !overlaps(existing, local.toUTC(), end.toUTC(), resource)) {
        result.push(local.toUTC().toISO());
      }
      local = local.plus({ minutes: 15 });
    }
  }
  return result;
}

async function ownedOrMember(request, booking, permission = null) {
  const user = C.requireUser(request);
  const workspace = booking.get('workspace');
  const query = C.q('Membership');
  query.equalTo('workspace', workspace);
  query.equalTo('user', user);
  query.equalTo('status', 'active');
  const member = await C.one(query);
  if (member) {
    if (permission && !(C.roles[member.get('role')] || []).includes(permission))
      C.fail('FORBIDDEN', 'Acesso não autorizado.');
    return { workspace, user, member };
  }
  const customer = await C.get('CustomerProfile', booking.get('customer').id);
  if (customer.get('user')?.id !== user.id) C.fail('FORBIDDEN', 'Acesso não autorizado.');
  return { workspace, user, customer };
}

function mount() {
  C.register('availability-search', async request => {
    const p = C.exact(request.params, ['workspaceId', 'serviceId', 'resourceId', 'day']);
    await C.throttle('availability', request.ip || 'unknown', 120, 60);
    const workspace = await publicWorkspace(p.workspaceId);
    await C.ensurePlan(workspace);
    const service = await serviceFor(workspace, p.serviceId);
    const resource = await resourceFor(workspace, service, p.resourceId);
    return { slots: (await slots(workspace, service, p.day, resource)).map(startAt => ({
        startAt, localTime: DateTime.fromISO(startAt).setZone(workspace.get('timezone')).toFormat('HH:mm'),
      })),
      timezone: workspace.get('timezone') };
  });

  C.register('bookings-create', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'serviceId', 'resourceId',
      'customerId', 'startAt', 'idempotencyKey']);
    const user = C.requireUser(request);
    await C.throttle('booking', user.id, 40, 3600);
    const workspace = await C.get('Workspace', C.workspaceId(p))
      .catch(() => C.fail('WORKSPACE_NOT_FOUND', 'Empresa não encontrada.'));
    const memberQ = C.q('Membership');
    memberQ.equalTo('workspace', workspace);
    memberQ.equalTo('user', user);
    memberQ.equalTo('status', 'active');
    const member = await C.one(memberQ);
    if (!workspace.get('publicProfileEnabled') && !member)
      C.fail('WORKSPACE_NOT_FOUND', 'Empresa não encontrada.');
    if (!['active', 'trial'].includes(workspace.get('status')))
      C.fail('WORKSPACE_SUSPENDED', 'Empresa indisponível.');
    await C.ensurePlan(workspace);
    const service = await serviceFor(workspace, p.serviceId);
    const resource = await resourceFor(workspace, service, p.resourceId);
    const start = C.iso(p.startAt, 'startAt');
    const day = start.setZone(workspace.get('timezone')).toISODate();
    const key = C.requireText(p.idempotencyKey, 'idempotencyKey', 80);
    const scope = user.id + ':' + workspace.id + ':' + key;
    const hash = C.digest(JSON.stringify([workspace.id, service.id, resource?.id || null,
      p.customerId || null, start.toISO()]));
    return C.withLock('booking:' + workspace.id + ':' + day, async assertLock => {
      const repeatQ = C.q('Booking');
      repeatQ.equalTo('idempotencyScope', scope);
      const repeat = await C.one(repeatQ);
      if (repeat) {
        if (repeat.get('requestHash') !== hash) C.fail('IDEMPOTENCY_CONFLICT', 'Esta solicitação já foi utilizada.');
        return view(repeat);
      }
      if (!(await slots(workspace, service, day, resource)).includes(start.toISO()))
        C.fail('SLOT_UNAVAILABLE', 'Este horário não está mais disponível.');
      let customer;
      if (p.customerId) {
        if (!member || !(C.roles[member.get('role')] || []).includes('bookings:write'))
          C.fail('FORBIDDEN', 'Acesso não autorizado.');
        customer = await C.get('CustomerProfile', C.requireText(p.customerId, 'customerId', 64));
        if (customer.get('workspace')?.id !== workspace.id) C.fail('FORBIDDEN', 'Acesso não autorizado.');
      } else {
        const customerQ = C.q('CustomerProfile');
        customerQ.equalTo('workspace', workspace);
        customerQ.equalTo('user', user);
        customer = await C.one(customerQ);
        if (!customer) {
          customer = C.hidden(new (C.cls('CustomerProfile'))());
          customer.set({ workspace, user, name: user.get('displayName'),
            email: user.get('email') });
          assertLock();
          await C.save(customer);
        }
      }
      const booking = C.hidden(new (C.cls('Booking'))());
      const end = start.plus({ minutes: service.get('durationMinutes') });
      booking.set({ workspace, service, resource, customer, status: 'confirmed',
        startAtUTC: start.toJSDate(), endAtUTC: end.toJSDate(),
        blockedUntilUTC: end.plus({ minutes: service.get('bufferAfterMinutes') || 0 }).toJSDate(),
        timezone: workspace.get('timezone'), createdBy: user,
        source: member && p.customerId ? 'business' : 'customer',
        idempotencyScope: scope, requestHash: hash,
        serviceSnapshot: { name: service.get('name'), durationMinutes: service.get('durationMinutes') },
        priceSnapshot: { amount: service.get('priceAmount') || 0,
          currency: service.get('currency'), pricingMode: service.get('pricingMode') } });
      assertLock();
      await C.save(booking);
      await C.audit({ workspace, user, action: 'booking.created', object: booking, requestId });
      return view(booking);
    });
  });

  C.register('bookings-list', async request => {
    const p = C.exact(request.params, ['workspaceId', 'limit', 'cursor']);
    const user = C.requireUser(request);
    const workspace = await C.get('Workspace', C.workspaceId(p));
    const memberQ = C.q('Membership');
    memberQ.equalTo('workspace', workspace);
    memberQ.equalTo('user', user);
    memberQ.equalTo('status', 'active');
    const member = await C.one(memberQ);
    const query = C.q('Booking');
    query.equalTo('workspace', workspace);
    if (!member) {
      const customerQ = C.q('CustomerProfile');
      customerQ.equalTo('workspace', workspace);
      customerQ.equalTo('user', user);
      const customer = await C.one(customerQ);
      if (!customer) return { items: [], nextCursor: null };
      query.equalTo('customer', customer);
    }
    if (p.cursor) query.lessThan('objectId', C.requireText(p.cursor, 'cursor', 64));
    query.descending('objectId');
    const limit = p.limit === undefined ? 30 : C.integer(p.limit, 'limit', 1, 100);
    query.limit(limit + 1);
    const items = await C.all(query);
    return { items: items.slice(0, limit).map(view),
      nextCursor: items.length > limit ? items[limit - 1].id : null };
  });

  C.register('bookings-mine', async request => {
    C.exact(request.params || {}, []);
    const user = C.requireUser(request);
    const customerQ = C.q('CustomerProfile');
    customerQ.equalTo('user', user);
    customerQ.limit(100);
    const customers = await C.all(customerQ);
    if (customers.length >= 100) C.fail('RATE_LIMITED', 'Solicite suporte para consultar seu histórico.');
    if (!customers.length) return { items: [] };
    const query = C.q('Booking');
    query.containedIn('customer', customers);
    query.descending('createdAt');
    query.limit(100);
    const bookings = await C.all(query);
    return { items: bookings.map(view) };
  });

  C.register('bookings-transition', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'bookingId', 'status']);
    const booking = await C.get('Booking', C.requireText(p.bookingId, 'bookingId', 64));
    if (booking.get('workspace')?.id !== C.workspaceId(p)) C.fail('FORBIDDEN', 'Acesso não autorizado.');
    const { workspace, user, member } = await ownedOrMember(request, booking, 'bookings:write');
    const status = C.requireText(p.status, 'status', 40);
    if (!transitions[booking.get('status')]?.includes(status))
      C.fail('BOOKING_TRANSITION_INVALID', 'Esta mudança de estado não é permitida.');
    if (!member && status !== 'canceled_by_customer')
      C.fail('FORBIDDEN', 'Acesso não autorizado.');
    if (member && status === 'canceled_by_customer')
      C.fail('FORBIDDEN', 'Acesso não autorizado.');
    if (status === 'canceled_by_customer' &&
        booking.get('startAtUTC').getTime() - Date.now() < (workspace.get('cancelBeforeMinutes') || 0) * 60000)
      C.fail('BOOKING_TRANSITION_INVALID', 'Prazo de cancelamento encerrado.');
    return C.withLock('booking:' + workspace.id + ':' +
        DateTime.fromJSDate(booking.get('startAtUTC')).setZone(workspace.get('timezone')).toISODate(),
    async assertLock => {
      await booking.fetch({ useMasterKey: true });
      if (!transitions[booking.get('status')]?.includes(status))
        C.fail('BOOKING_TRANSITION_INVALID', 'Esta mudança de estado não é permitida.');
      booking.set('status', status);
      if (status.startsWith('canceled')) booking.set({ canceledBy: user, canceledAt: new Date() });
      assertLock();
      await C.save(booking);
      await C.audit({ workspace, user, action: 'booking.' + status, object: booking, requestId });
      return view(booking);
    });
  });

  C.register('dashboard-summary', async request => {
    const p = C.exact(request.params, ['workspaceId', 'day']);
    const { workspace } = await C.membership(request, C.workspaceId(p));
    const day = p.day ? DateTime.fromISO(p.day, { zone: workspace.get('timezone') }) :
      DateTime.now().setZone(workspace.get('timezone'));
    if (!day.isValid) C.fail('VALIDATION_ERROR', 'Data inválida.');
    const query = C.q('Booking');
    query.equalTo('workspace', workspace);
    query.greaterThanOrEqualTo('startAtUTC', day.startOf('day').toUTC().toJSDate());
    query.lessThan('startAtUTC', day.plus({ days: 1 }).startOf('day').toUTC().toJSDate());
    query.limit(1000);
    const bookings = await C.all(query);
    const counts = {};
    for (const booking of bookings) counts[booking.get('status')] = (counts[booking.get('status')] || 0) + 1;
    return { day: day.toISODate(), timezone: workspace.get('timezone'), total: bookings.length,
      byStatus: counts, upcoming: bookings.filter(b => b.get('startAtUTC') > new Date() &&
        activeStates.includes(b.get('status'))).sort((a, b) => a.get('startAtUTC') - b.get('startAtUTC'))
        .slice(0, 5).map(view) };
  });
}

module.exports = { mount, slots, overlaps, transitions };

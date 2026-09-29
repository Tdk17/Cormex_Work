'use strict';
const C = require('./core');

const viewService = s => ({ id: s.id, name: s.get('name'), description: s.get('description') || '',
  durationMinutes: s.get('durationMinutes'), bufferAfterMinutes: s.get('bufferAfterMinutes') || 0,
  priceAmount: s.get('priceAmount'), pricingMode: s.get('pricingMode'), currency: s.get('currency'),
  active: s.get('active'), requiredResourceType: s.get('requiredResourceType') || null });
const viewResource = r => ({ id: r.id, name: r.get('name'), type: r.get('type'),
  active: r.get('active'), capacity: r.get('capacity') });
function serviceFields(p, s) {
  if (p.name !== undefined) s.set('name', C.requireText(p.name, 'name', 120));
  if (p.description !== undefined) s.set('description', C.optionalText(p.description, 'description', 1000));
  if (p.durationMinutes !== undefined) s.set('durationMinutes', C.integer(p.durationMinutes, 'durationMinutes', 15, 480));
  if (p.bufferAfterMinutes !== undefined) s.set('bufferAfterMinutes', C.integer(p.bufferAfterMinutes, 'bufferAfterMinutes', 0, 120));
  if (p.pricingMode !== undefined) {
    if (!['fixed', 'quote'].includes(p.pricingMode)) C.fail('VALIDATION_ERROR', 'Tipo de preço inválido.');
    s.set('pricingMode', p.pricingMode);
  }
  if (p.priceAmount !== undefined) s.set('priceAmount', C.integer(p.priceAmount, 'priceAmount', 0, 100000000));
  if (p.requiredResourceType !== undefined) {
    s.set('requiredResourceType', p.requiredResourceType === null ? null :
      C.requireText(p.requiredResourceType, 'requiredResourceType', 40));
  }
}
const serviceAllowed = ['workspaceId', 'name', 'description', 'durationMinutes',
  'bufferAfterMinutes', 'priceAmount', 'pricingMode', 'requiredResourceType'];

function mount() {
  C.register('services-list', async request => {
    const p = C.exact(request.params, ['workspaceId', 'includeArchived', 'limit', 'cursor']);
    const { workspace } = await C.membership(request, C.workspaceId(p));
    const query = C.q('Service');
    query.equalTo('workspace', workspace);
    if (p.includeArchived !== true) query.equalTo('active', true);
    if (p.cursor) query.greaterThan('objectId', C.requireText(p.cursor, 'cursor', 64));
    query.ascending('objectId');
    const limit = p.limit === undefined ? 30 : C.integer(p.limit, 'limit', 1, 100);
    query.limit(limit + 1);
    const records = await C.all(query);
    return { items: records.slice(0, limit).map(viewService), nextCursor: records.length > limit ? records[limit - 1].id : null };
  });

  C.register('services-create', async (request, requestId) => {
    const p = C.exact(request.params, serviceAllowed);
    const { workspace, user } = await C.writable(request, C.workspaceId(p), 'services:write');
    return C.withLock('service-limit:' + workspace.id, async assertLock => {
      await C.planLimit(workspace, 'services', 'Service');
      const service = C.hidden(new (C.cls('Service'))());
      serviceFields(p, service);
      if (!service.get('name') || !service.get('durationMinutes') ||
          !service.get('pricingMode') ||
          (service.get('pricingMode') === 'fixed' && service.get('priceAmount') == null))
        C.fail('VALIDATION_ERROR', 'Informe nome, duração e preço.');
      service.set({ workspace, segmentCode: workspace.get('segmentCode'),
        active: true, currency: 'BRL', createdBy: user });
      assertLock();
      await C.save(service);
      await C.audit({ workspace, user, action: 'service.created', object: service, requestId });
      return viewService(service);
    });
  });

  C.register('services-update', async (request, requestId) => {
    const p = C.exact(request.params, [...serviceAllowed, 'serviceId']);
    const { workspace, user } = await C.writable(request, C.workspaceId(p), 'services:write');
    const service = await C.get('Service', C.requireText(p.serviceId, 'serviceId', 64));
    if (service.get('workspace')?.id !== workspace.id) C.fail('SERVICE_NOT_FOUND', 'Serviço não encontrado.');
    serviceFields(p, service);
    if (service.get('pricingMode') === 'fixed' && service.get('priceAmount') == null)
      C.fail('VALIDATION_ERROR', 'Informe o preço.');
    await C.save(service);
    await C.audit({ workspace, user, action: 'service.updated', object: service, requestId });
    return viewService(service);
  });

  C.register('services-archive', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'serviceId']);
    const { workspace, user } = await C.writable(request, C.workspaceId(p), 'services:write');
    const service = await C.get('Service', C.requireText(p.serviceId, 'serviceId', 64));
    if (service.get('workspace')?.id !== workspace.id) C.fail('SERVICE_NOT_FOUND', 'Serviço não encontrado.');
    service.set('active', false);
    await C.save(service);
    await C.audit({ workspace, user, action: 'service.archived', object: service, requestId });
    return viewService(service);
  });

  C.register('business-hours-get', async request => {
    const p = C.exact(request.params, ['workspaceId']);
    const { workspace } = await C.membership(request, C.workspaceId(p));
    const query = C.q('BusinessHours');
    query.equalTo('workspace', workspace);
    query.ascending('weekday');
    return { items: (await C.all(query)).map(h => ({ weekday: h.get('weekday'), intervals: h.get('intervals') })) };
  });

  C.register('business-hours-update', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'days']);
    const { workspace, user } = await C.writable(request, C.workspaceId(p), 'hours:write');
    if (!Array.isArray(p.days) || p.days.length !== 7) C.fail('VALIDATION_ERROR', 'Informe os sete dias da semana.');
    const normalized = p.days.map((day, index) => {
      C.exact(day, ['weekday', 'intervals']);
      if (day.weekday !== index + 1 || !Array.isArray(day.intervals) || day.intervals.length > 3)
        C.fail('VALIDATION_ERROR', 'Horários inválidos.');
      const intervals = day.intervals.map(interval => {
        C.exact(interval, ['start', 'end']);
        const time = /^\d{2}:\d{2}$/;
        if (!time.test(interval.start) || !time.test(interval.end) ||
            interval.start >= interval.end || interval.end > '23:59') C.fail('VALIDATION_ERROR', 'Horário inválido.');
        return { start: interval.start, end: interval.end };
      }).sort((a, b) => a.start.localeCompare(b.start));
      if (intervals.some((v, i) => i && intervals[i - 1].end > v.start))
        C.fail('VALIDATION_ERROR', 'Horários sobrepostos.');
      return { weekday: day.weekday, intervals };
    });
    return C.withLock('hours:' + workspace.id, async assertLock => {
      const query = C.q('BusinessHours');
      query.equalTo('workspace', workspace);
      const existing = await C.all(query);
      for (const day of normalized) {
        const record = existing.find(h => h.get('weekday') === day.weekday) ||
          C.hidden(new (C.cls('BusinessHours'))());
        record.set({ workspace, timezone: workspace.get('timezone'), ...day });
        assertLock();
        await C.save(record);
      }
      await C.audit({ workspace, user, action: 'business_hours.updated', object: workspace, requestId });
      return { items: normalized };
    });
  });

  C.register('resources-list', async request => {
    const p = C.exact(request.params, ['workspaceId']);
    const { workspace } = await C.membership(request, C.workspaceId(p));
    const query = C.q('Resource');
    query.equalTo('workspace', workspace);
    query.equalTo('active', true);
    query.limit(100);
    return { items: (await C.all(query)).map(viewResource) };
  });

  C.register('resources-create', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'name', 'type']);
    const { workspace, user } = await C.writable(request, C.workspaceId(p), 'hours:write');
    return C.withLock('resource-limit:' + workspace.id, async assertLock => {
      await C.planLimit(workspace, 'resources', 'Resource');
      const resource = C.hidden(new (C.cls('Resource'))());
      resource.set({ workspace, name: C.requireText(p.name, 'name', 120),
        type: C.requireText(p.type, 'type', 40), capacity: 1, active: true });
      assertLock();
      await C.save(resource);
      await C.audit({ workspace, user, action: 'resource.created', object: resource, requestId });
      return viewResource(resource);
    });
  });

  C.register('customers-list', async request => {
    const p = C.exact(request.params, ['workspaceId', 'limit', 'cursor']);
    const { workspace } = await C.membership(request, C.workspaceId(p), 'customers:write');
    const query = C.q('CustomerProfile');
    query.equalTo('workspace', workspace);
    if (p.cursor) query.greaterThan('objectId', C.requireText(p.cursor, 'cursor', 64));
    query.ascending('objectId');
    const limit = p.limit === undefined ? 30 : C.integer(p.limit, 'limit', 1, 100);
    query.limit(limit + 1);
    const items = await C.all(query);
    return { items: items.slice(0, limit).map(c => ({ id: c.id, name: c.get('name'),
      email: c.get('email') || '', phone: c.get('phone') || '' })),
      nextCursor: items.length > limit ? items[limit - 1].id : null };
  });

  C.register('customers-create', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'name', 'email', 'phone']);
    const { workspace, user } = await C.writable(request, C.workspaceId(p), 'customers:write');
    const customer = C.hidden(new (C.cls('CustomerProfile'))());
    customer.set({ workspace, name: C.requireText(p.name, 'name', 120),
      email: C.optionalText(p.email, 'email', 254).toLowerCase(),
      phone: C.optionalText(p.phone, 'phone', 25) });
    if (!customer.get('email') && !customer.get('phone')) C.fail('VALIDATION_ERROR', 'Informe e-mail ou telefone.');
    await C.save(customer);
    await C.audit({ workspace, user, action: 'customer.created', object: customer, requestId });
    return { id: customer.id, name: customer.get('name') };
  });
}
module.exports = { mount, viewService };

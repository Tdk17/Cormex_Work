'use strict';

const crypto = require('node:crypto');
const Redis = require('ioredis');
const { DateTime } = require('luxon');

const roles = Object.freeze({
  owner: ['workspace:write', 'services:write', 'bookings:write', 'customers:write', 'hours:write', 'team:write', 'billing:write', 'reports:read'],
  admin: ['workspace:write', 'services:write', 'bookings:write', 'customers:write', 'hours:write', 'team:write', 'reports:read'],
  manager: ['services:write', 'bookings:write', 'customers:write', 'hours:write', 'reports:read'],
  receptionist: ['bookings:write', 'customers:write'],
  staff: ['bookings:write'],
  viewer: [],
});

class ApiError extends Error {
  constructor(code, message, fields = {}) {
    super(message);
    this.code = code;
    this.fields = fields;
  }
}

const fail = (code, message, fields) => { throw new ApiError(code, message, fields); };
const requireText = (value, name, max = 120) => {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    fail('VALIDATION_ERROR', 'Confira os dados informados.', { [name]: 'Campo obrigatório ou tamanho inválido.' });
  }
  return value.trim();
};
const optionalText = (value, name, max = 500) => value == null || value === '' ? '' : requireText(value, name, max);
const integer = (value, name, min, max) => {
  if (!Number.isInteger(value) || value < min || value > max) {
    fail('VALIDATION_ERROR', 'Confira os dados informados.', { [name]: 'Valor inválido.' });
  }
  return value;
};
const exact = (input, allowed) => {
  if (!input || typeof input !== 'object' || Array.isArray(input) ||
      Object.keys(input).some(k => !allowed.includes(k))) {
    fail('VALIDATION_ERROR', 'Campos desconhecidos na solicitação.');
  }
  return input;
};
const iso = (value, name) => {
  const date = DateTime.fromISO(value, { setZone: true });
  if (!date.isValid || !/([zZ]|[+-]\d\d:\d\d)$/.test(value)) {
    fail('VALIDATION_ERROR', 'Data e horário inválidos.', { [name]: 'Informe data com fuso.' });
  }
  return date.toUTC();
};
const validZone = value => {
  const zone = requireText(value, 'timezone', 80);
  if (!DateTime.now().setZone(zone).isValid) fail('VALIDATION_ERROR', 'Fuso horário inválido.');
  return zone;
};
const hidden = object => { object.setACL(new Parse.ACL()); return object; };
const cls = name => Parse.Object.extend(name);
const pointer = (name, id) => cls(name).createWithoutData(id);
const q = name => new Parse.Query(cls(name));
const save = object => object.save(null, { useMasterKey: true });
const get = (name, id) => q(name).get(id, { useMasterKey: true });
const one = query => query.first({ useMasterKey: true });
const all = query => query.find({ useMasterKey: true });
const userId = request => request.user && request.user.id;
const requireUser = request => {
  if (!userId(request)) fail('AUTH_SESSION_EXPIRED', 'Entre novamente para continuar.');
  return request.user;
};
const workspaceId = params => requireText(params.workspaceId, 'workspaceId', 64);

async function membership(request, id, permission = null) {
  const user = requireUser(request);
  const query = q('Membership');
  query.equalTo('workspace', pointer('Workspace', id));
  query.equalTo('user', user);
  query.equalTo('status', 'active');
  const member = await one(query);
  if (!member) fail('FORBIDDEN', 'Acesso não autorizado.');
  const role = member.get('role');
  if (permission && !(roles[role] || []).includes(permission)) fail('FORBIDDEN', 'Acesso não autorizado.');
  const workspace = await get('Workspace', id).catch(() => fail('WORKSPACE_NOT_FOUND', 'Empresa não encontrada.'));
  if (['suspended', 'closed'].includes(workspace.get('status'))) {
    fail('WORKSPACE_SUSPENDED', 'Esta empresa está indisponível.');
  }
  return { member, workspace, user };
}

async function writable(request, id, permission) {
  const context = await membership(request, id, permission);
  const sub = await ensurePlan(context.workspace);
  return { ...context, subscription: sub };
}

async function ensurePlan(workspace) {
  const query = q('Subscription');
  query.equalTo('workspace', workspace);
  query.descending('createdAt');
  const sub = await one(query);
  const status = sub && sub.get('status');
  const trialEnd = sub && sub.get('trialEnd');
  const activeTrial = status === 'trial' && trialEnd instanceof Date && trialEnd.getTime() > Date.now();
  if (status !== 'active' && !activeTrial) fail('PLAN_REQUIRED', 'Escolha um plano ativo para continuar.');
  return sub;
}

async function planLimit(workspace, key, className, activeOnly = true) {
  const query = q('Subscription');
  query.equalTo('workspace', workspace);
  query.descending('createdAt');
  const sub = await one(query);
  const plan = sub && sub.get('plan') && await get('Plan', sub.get('plan').id);
  const max = plan && plan.get('limits') && plan.get('limits')[key];
  if (!Number.isInteger(max) || max < 0) fail('PLAN_REQUIRED', 'Limite do plano indisponível.');
  const countQ = q(className);
  countQ.equalTo('workspace', workspace);
  if (activeOnly) countQ.equalTo('active', true);
  const count = await countQ.count({ useMasterKey: true });
  if (count >= max) fail('PLAN_LIMIT_REACHED', 'Limite do plano atingido.');
}

let redisClient;
function redis() {
  if (!process.env.REDIS_URL) fail('INTERNAL_ERROR', 'Serviço temporariamente indisponível.');
  if (!redisClient) redisClient = new Redis(process.env.REDIS_URL, {
    maxRetriesPerRequest: 1, enableOfflineQueue: false, connectTimeout: 3000,
  });
  return redisClient;
}
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
const randomId = () => crypto.randomUUID();

async function withLock(scope, task) {
  const client = redis();
  const key = 'cw:lock:' + digest(scope);
  const owner = randomId();
  const acquired = await client.set(key, owner, 'PX', 20000, 'NX');
  if (acquired !== 'OK') fail('BOOKING_CONFLICT', 'Outra operação está em andamento. Tente novamente.');
  const refreshScript = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('pexpire', KEYS[1], ARGV[2]) else return 0 end";
  const releaseScript = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
  let valid = true;
  const timer = setInterval(async () => {
    try { if (!(await client.eval(refreshScript, 1, key, owner, '20000'))) valid = false; }
    catch (_) { valid = false; }
  }, 5000);
  try {
    return await task(() => {
      if (!valid) fail('BOOKING_CONFLICT', 'Operação interrompida. Tente novamente.');
    });
  } finally {
    clearInterval(timer);
    await client.eval(releaseScript, 1, key, owner).catch(() => {});
  }
}

async function throttle(action, subject, limit, seconds) {
  const key = 'cw:rate:' + action + ':' + digest(subject);
  const client = redis();
  const count = await client.incr(key);
  if (count === 1) await client.expire(key, seconds);
  if (count > limit) fail('RATE_LIMITED', 'Muitas tentativas. Tente novamente mais tarde.');
}

async function audit({ workspace, user, action, object, requestId }) {
  const event = hidden(new (cls('AuditEvent'))());
  event.set({ workspace, actor: user, action, objectType: object.className,
    objectId: object.id, correlationId: requestId });
  await save(event);
}

function register(name, handler) {
  Parse.Cloud.define('v1-' + name, async request => {
    const requestId = randomId();
    try {
      const data = await handler(request, requestId);
      return { ok: true, data, meta: { requestId } };
    } catch (error) {
      if (error instanceof ApiError) {
        return { ok: false, error: { code: error.code, message: error.message,
          fieldErrors: error.fields, requestId } };
      }
      console.error(JSON.stringify({ requestId, function: name, code: 'INTERNAL_ERROR' }));
      return { ok: false, error: { code: 'INTERNAL_ERROR',
        message: 'Não foi possível concluir. Tente novamente.', requestId } };
    }
  });
}

module.exports = { ApiError, fail, requireText, optionalText, integer, exact, iso,
  validZone, hidden, cls, pointer, q, save, get, one, all, requireUser, userId,
  workspaceId, membership, writable, ensurePlan, planLimit, withLock, throttle, audit,
  register, digest, roles };

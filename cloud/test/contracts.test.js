'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { DateTime } = require('luxon');
const C = require('../src/core');
const { slots, overlaps, transitions } = require('../src/bookings');

test('strict input rejects mass assignment, invalid dates and timezone', () => {
  assert.throws(() => C.exact({ workspaceId: 'a', owner: 'attacker' }, ['workspaceId']),
    { code: 'VALIDATION_ERROR' });
  assert.throws(() => C.iso('2026-10-01T09:00:00', 'startAt'),
    { code: 'VALIDATION_ERROR' });
  assert.throws(() => C.validZone('Invalid/Zone'), { code: 'VALIDATION_ERROR' });
});

test('reservation transition is terminal after cancellation or completion', () => {
  assert.deepEqual(transitions.completed, []);
  assert.deepEqual(transitions.canceled_by_customer, []);
  assert.ok(transitions.confirmed.includes('completed'));
  assert.ok(!transitions.pending.includes('completed'));
});

test('different resources may overlap but a workspace-wide booking blocks all', () => {
  const make = id => ({ get: field => ({
    resource: id ? { id } : null,
    startAtUTC: new Date('2026-10-01T12:00:00Z'),
    blockedUntilUTC: new Date('2026-10-01T13:00:00Z'),
  })[field] });
  const start = DateTime.fromISO('2026-10-01T12:15:00Z');
  const end = start.plus({ minutes: 30 });
  assert.equal(overlaps([make('chair-1')], start, end, { id: 'chair-2' }), false);
  assert.equal(overlaps([make('chair-1')], start, end, { id: 'chair-1' }), true);
  assert.equal(overlaps([make(null)], start, end, { id: 'chair-2' }), true);
});

test('workspace membership denies outsiders and roles without permission', async () => {
  const previousParse = global.Parse;
  let currentMember;
  global.Parse = {
    Object: { extend: () => ({ createWithoutData: id => ({ id }) }) },
    Query: class {
      equalTo() { return this; }
      async first() { return currentMember; }
    },
  };
  try {
    currentMember = null;
    await assert.rejects(C.membership({ user: { id: 'outsider' } }, 'workspace-a'),
      { code: 'FORBIDDEN' });
    currentMember = { get: field => ({ role: 'viewer' })[field] };
    await assert.rejects(C.membership({ user: { id: 'viewer' } }, 'workspace-a', 'services:write'),
      { code: 'FORBIDDEN' });
  } finally {
    global.Parse = previousParse;
  }
});

test('availability uses business timezone and excludes conflicting slots', async () => {
  const now = DateTime.now().setZone('America/Sao_Paulo').plus({ days: 2 });
  const dayText = now.toISODate();
  const localStart = DateTime.fromISO(dayText + 'T09:00', { zone: 'America/Sao_Paulo' });
  const collision = {
    get(field) {
      return { resource: null, startAtUTC: localStart.toJSDate(),
        blockedUntilUTC: localStart.plus({ minutes: 30 }).toJSDate() }[field];
    },
  };
  const previousOne = C.one;
  const previousAll = C.all;
  const previousQ = C.q;
  C.q = () => ({
    equalTo() { return this; }, containedIn() { return this; },
    lessThan() { return this; }, greaterThan() { return this; },
    limit() { return this; },
  });
  C.one = async () => ({ get: () => [{ start: '09:00', end: '11:00' }] });
  C.all = async () => [collision];
  try {
    const workspace = { get: key => key === 'timezone' ? 'America/Sao_Paulo' : undefined };
    const service = { get: key => key === 'durationMinutes' ? 30 : 0 };
    const result = await slots(workspace, service, dayText, null);
    assert.ok(result.length > 0);
    assert.ok(!result.includes(localStart.toUTC().toISO()));
    assert.ok(result.includes(localStart.plus({ minutes: 30 }).toUTC().toISO()));
  } finally {
    C.one = previousOne; C.all = previousAll; C.q = previousQ;
  }
});

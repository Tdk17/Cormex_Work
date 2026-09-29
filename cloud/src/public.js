'use strict';
const C = require('./core');
const { viewService } = require('./catalog');

function mount() {
  C.register('discovery-search', async request => {
    const p = C.exact(request.params || {}, ['segmentCode', 'city', 'limit', 'cursor']);
    await C.throttle('discovery', request.ip || 'unknown', 100, 60);
    const query = C.q('Workspace');
    query.equalTo('publicProfileEnabled', true);
    query.containedIn('status', ['active', 'trial']);
    if (p.segmentCode) query.equalTo('segmentCode', C.requireText(p.segmentCode, 'segmentCode', 64));
    if (p.city) query.matches('city', new RegExp('^' +
      C.requireText(p.city, 'city', 80).replace(/[.*+?^$()|[\]{}]/g, '\\$&') + '$', 'i'));
    if (p.cursor) query.greaterThan('objectId', C.requireText(p.cursor, 'cursor', 64));
    query.ascending('objectId');
    const limit = p.limit === undefined ? 20 : C.integer(p.limit, 'limit', 1, 50);
    query.limit(limit + 1);
    const items = await C.all(query);
    const eligible = [];
    for (const workspace of items.slice(0, limit)) {
      try {
        await C.ensurePlan(workspace);
        eligible.push(workspace);
      } catch (error) {
        if (!(error instanceof C.ApiError) || error.code !== 'PLAN_REQUIRED') throw error;
      }
    }
    return { items: eligible.map(w => ({ id: w.id, name: w.get('name'),
      slug: w.get('slug'), segmentCode: w.get('segmentCode'), city: w.get('city'),
      state: w.get('state'), description: w.get('description') || '' })),
      nextCursor: items.length > limit ? items[limit - 1].id : null };
  });

  C.register('workspaces-public-profile', async request => {
    const p = C.exact(request.params, ['slug']);
    const query = C.q('Workspace');
    query.equalTo('slug', C.requireText(p.slug, 'slug', 50));
    query.equalTo('publicProfileEnabled', true);
    query.containedIn('status', ['active', 'trial']);
    const workspace = await C.one(query);
    if (!workspace) C.fail('WORKSPACE_NOT_FOUND', 'Empresa não encontrada.');
    try {
      await C.ensurePlan(workspace);
    } catch (error) {
      if (error instanceof C.ApiError && error.code === 'PLAN_REQUIRED')
        C.fail('WORKSPACE_NOT_FOUND', 'Empresa não encontrada.');
      throw error;
    }
    const serviceQ = C.q('Service');
    serviceQ.equalTo('workspace', workspace);
    serviceQ.equalTo('active', true);
    serviceQ.limit(100);
    return { id: workspace.id, name: workspace.get('name'), slug: workspace.get('slug'),
      segmentCode: workspace.get('segmentCode'), city: workspace.get('city'),
      state: workspace.get('state'), description: workspace.get('description') || '',
      timezone: workspace.get('timezone'), services: (await C.all(serviceQ)).map(viewService) };
  });
}
module.exports = { mount };

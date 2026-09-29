'use strict';
const C = require('./core');

function workspaceView(w) {
  return { id: w.id, name: w.get('name'), slug: w.get('slug'),
    segmentCode: w.get('segmentCode'), timezone: w.get('timezone'),
    city: w.get('city'), state: w.get('state'), description: w.get('description') || '',
    status: w.get('status'), publicProfileEnabled: !!w.get('publicProfileEnabled') };
}
function membershipView(m) {
  return { workspaceId: m.get('workspace').id, role: m.get('role'), status: m.get('status') };
}
async function activeSegment(code) {
  const query = C.q('SegmentDefinition');
  query.equalTo('code', code);
  query.equalTo('status', 'active');
  query.descending('version');
  const segment = await C.one(query);
  if (!segment) C.fail('SEGMENT_UNAVAILABLE', 'Segmento indisponível.');
  return segment;
}

function mount() {
  C.register('auth-register', async request => {
    const p = C.exact(request.params, ['name', 'email', 'password', 'termsVersion', 'privacyVersion', 'acceptTerms']);
    await C.throttle('register', request.ip || 'unknown', 8, 3600);
    const name = C.requireText(p.name, 'name', 120);
    const email = C.requireText(p.email, 'email', 254).toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) C.fail('VALIDATION_ERROR', 'E-mail inválido.');
    if (typeof p.password !== 'string' || p.password.length < 12 || p.password.length > 128)
      C.fail('VALIDATION_ERROR', 'A senha precisa ter entre 12 e 128 caracteres.');
    if (p.acceptTerms !== true || p.termsVersion !== process.env.TERMS_VERSION ||
        p.privacyVersion !== process.env.PRIVACY_VERSION ||
        !process.env.TERMS_VERSION || !process.env.PRIVACY_VERSION)
      C.fail('VALIDATION_ERROR', 'Aceite a versão atual dos Termos e da Privacidade.');
    const user = new Parse.User();
    user.set({ username: email, email, password: p.password, displayName: name });
    try {
      await user.signUp();
    } catch (_) {
      C.fail('VALIDATION_ERROR', 'Não foi possível criar a conta. Confira os dados.');
    }
    const consent = C.hidden(new (C.cls('ConsentRecord'))());
    consent.set({ user, purpose: 'account_terms', policyVersion: p.termsVersion,
      privacyVersion: p.privacyVersion, grantedAt: new Date(), source: 'web' });
    await C.save(consent);
    return { userId: user.id, requiresEmailVerification: process.env.REQUIRE_EMAIL_VERIFICATION === 'true' };
  });

  C.register('auth-login', async request => {
    const p = C.exact(request.params, ['email', 'password']);
    const email = C.requireText(p.email, 'email', 254).toLowerCase();
    if (typeof p.password !== 'string') C.fail('AUTH_INVALID_CREDENTIALS', 'Credenciais inválidas.');
    await C.throttle('login-ip', request.ip || 'unknown', 20, 1200);
    await C.throttle('login-user', email, 8, 1200);
    let user;
    try { user = await Parse.User.logIn(email, p.password); }
    catch (_) { C.fail('AUTH_INVALID_CREDENTIALS', 'Credenciais inválidas.'); }
    if (process.env.REQUIRE_EMAIL_VERIFICATION === 'true' && !user.get('emailVerified'))
      C.fail('FORBIDDEN', 'Verifique seu e-mail antes de entrar.');
    return { sessionToken: user.getSessionToken(), user: { id: user.id,
      name: user.get('displayName'), email: user.get('email') } };
  });

  C.register('auth-password-reset-request', async request => {
    const p = C.exact(request.params, ['email']);
    const email = C.requireText(p.email, 'email', 254).toLowerCase();
    await C.throttle('reset', request.ip || 'unknown', 5, 3600);
    await Parse.User.requestPasswordReset(email).catch(() => {});
    return { message: 'Se houver uma conta, enviaremos as instruções.' };
  });

  C.register('auth-me', async request => {
    const user = C.requireUser(request);
    const query = C.q('Membership');
    query.equalTo('user', user);
    query.equalTo('status', 'active');
    const members = await C.all(query);
    return { user: { id: user.id, name: user.get('displayName'), email: user.get('email') },
      memberships: members.map(membershipView) };
  });

  C.register('auth-logout', async request => {
    const user = C.requireUser(request);
    const token = user.getSessionToken();
    if (token) {
      const query = C.q('_Session');
      query.equalTo('sessionToken', token);
      const session = await C.one(query);
      if (session) await session.destroy({ useMasterKey: true });
    }
    return { loggedOut: true };
  });

  C.register('segments-list', async request => {
    C.exact(request.params || {}, []);
    const query = C.q('SegmentDefinition');
    query.equalTo('status', 'active');
    query.descending('version');
    query.limit(100);
    const segments = await C.all(query);
    const latest = [...new Map(segments.reverse().map(s => [s.get('code'), s])).values()]
      .sort((a, b) => (a.get('sortOrder') || 0) - (b.get('sortOrder') || 0));
    return { items: latest.map(s => ({ code: s.get('code'), displayName: s.get('displayName'),
      description: s.get('description') || '', configVersion: s.get('version'),
      labels: s.get('labels') || {}, capabilities: s.get('capabilities') || [] })) };
  });

  C.register('plans-list', async request => {
    const p = C.exact(request.params || {}, ['segmentCode']);
    const query = C.q('Plan');
    query.equalTo('status', 'active');
    if (p.segmentCode) query.containedIn('segmentCodes', [C.requireText(p.segmentCode, 'segmentCode', 64)]);
    query.descending('version');
    query.limit(100);
    const plans = await C.all(query);
    const latest = [...new Map(plans.reverse().map(plan => [plan.get('code'), plan])).values()]
      .sort((a, b) => (a.get('amount') || 0) - (b.get('amount') || 0));
    return { items: latest.map(plan => ({ code: plan.get('code'), name: plan.get('name'),
      amount: plan.get('amount'), currency: plan.get('currency'),
      billingInterval: plan.get('billingInterval'), trialDays: plan.get('trialDays') || 0,
      limits: plan.get('limits') || {}, capabilities: plan.get('capabilities') || [],
      version: plan.get('version') })) };
  });

  C.register('workspaces-create', async (request, requestId) => {
    const user = C.requireUser(request);
    const p = C.exact(request.params, ['name', 'slug', 'segmentCode', 'timezone', 'city', 'state', 'idempotencyKey']);
    const name = C.requireText(p.name, 'name');
    const slug = C.requireText(p.slug, 'slug', 50).toLowerCase();
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) C.fail('VALIDATION_ERROR', 'Endereço público inválido.');
    const segment = await activeSegment(C.requireText(p.segmentCode, 'segmentCode', 64));
    const timezone = C.validZone(p.timezone);
    const city = C.requireText(p.city, 'city', 80);
    const state = C.requireText(p.state, 'state', 30);
    const key = C.requireText(p.idempotencyKey, 'idempotencyKey', 80);
    const hash = C.digest(JSON.stringify([name, slug, segment.get('code'), timezone, city, state]));
    const scope = 'workspace:' + user.id;
    return C.withLock(scope, async assertLock => {
      const ownQuery = C.q('Workspace');
      ownQuery.equalTo('onboardingKey', user.id + ':' + key);
      let workspace = await C.one(ownQuery);
      if (!workspace) {
        const sameSlug = C.q('Workspace');
        sameSlug.equalTo('slug', slug);
        if (await C.one(sameSlug)) C.fail('VALIDATION_ERROR', 'Endereço público já em uso.');
        workspace = C.hidden(new (C.cls('Workspace'))());
        workspace.set({ name, slug, segmentCode: segment.get('code'),
          segmentConfigVersion: segment.get('version'), owner: user,
          timezone, city, state, status: 'pending_setup', publicProfileEnabled: false,
          onboardingKey: user.id + ':' + key, onboardingRequestHash: hash });
        assertLock();
        await C.save(workspace);
      } else if (workspace.get('owner').id !== user.id ||
                 workspace.get('onboardingRequestHash') !== hash) {
        C.fail('IDEMPOTENCY_CONFLICT', 'Esta solicitação já foi utilizada.');
      }
      const memberQuery = C.q('Membership');
      memberQuery.equalTo('workspace', workspace);
      memberQuery.equalTo('user', user);
      let member = await C.one(memberQuery);
      if (!member) {
        member = C.hidden(new (C.cls('Membership'))());
        member.set({ workspace, user, role: 'owner', status: 'active', acceptedAt: new Date() });
        assertLock();
        await C.save(member);
        await C.audit({ workspace, user, action: 'workspace.created', object: workspace, requestId });
      }
      return { workspace: workspaceView(workspace), membership: membershipView(member) };
    });
  });

  C.register('workspaces-get', async request => {
    const p = C.exact(request.params, ['workspaceId']);
    const { workspace } = await C.membership(request, C.workspaceId(p));
    return workspaceView(workspace);
  });

  C.register('workspaces-update', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'name', 'description', 'publicProfileEnabled']);
    const { workspace, user } = await C.membership(request, C.workspaceId(p), 'workspace:write');
    if (p.name !== undefined) workspace.set('name', C.requireText(p.name, 'name'));
    if (p.description !== undefined) workspace.set('description', C.optionalText(p.description, 'description', 1000));
    if (p.publicProfileEnabled !== undefined) {
      if (typeof p.publicProfileEnabled !== 'boolean') C.fail('VALIDATION_ERROR', 'Visibilidade inválida.');
      workspace.set('publicProfileEnabled', p.publicProfileEnabled);
    }
    await C.save(workspace);
    await C.audit({ workspace, user, action: 'workspace.updated', object: workspace, requestId });
    return workspaceView(workspace);
  });

  C.register('subscription-select-trial', async (request, requestId) => {
    const p = C.exact(request.params, ['workspaceId', 'planCode', 'acceptedVersion']);
    const { workspace, user, member } = await C.membership(request, C.workspaceId(p), 'billing:write');
    if (member.get('role') !== 'owner') C.fail('FORBIDDEN', 'Acesso não autorizado.');
    const code = C.requireText(p.planCode, 'planCode', 64);
    const query = C.q('Plan');
    query.equalTo('code', code);
    query.equalTo('version', p.acceptedVersion);
    query.equalTo('status', 'active');
    const plan = await C.one(query);
    if (!plan || !(plan.get('segmentCodes') || []).includes(workspace.get('segmentCode')))
      C.fail('PLAN_REQUIRED', 'Plano indisponível para este segmento.');
    if (p.acceptedVersion !== plan.get('version')) C.fail('VALIDATION_ERROR', 'Confira os termos atuais do plano.');
    return C.withLock('subscription:' + workspace.id, async assertLock => {
      const existingQ = C.q('Subscription');
      existingQ.equalTo('workspace', workspace);
      if (await C.one(existingQ)) C.fail('FORBIDDEN', 'Plano já selecionado. Solicite alteração de assinatura.');
      const trialDays = plan.get('trialDays') || 0;
      // Cobrança sem provedor não pode ser ativada; trial é concedido somente se previsto no plano.
      if (trialDays <= 0) C.fail('PLAN_REQUIRED', 'A contratação deste plano ainda não está disponível.');
      const sub = C.hidden(new (C.cls('Subscription'))());
      sub.set({ workspace, plan, status: 'trial', provider: 'pending',
        trialStart: new Date(), trialEnd: new Date(Date.now() + trialDays * 86400000),
        acceptedVersion: p.acceptedVersion });
      assertLock();
      await C.save(sub);
      workspace.set('status', 'trial');
      await C.save(workspace);
      await C.audit({ workspace, user, action: 'subscription.trial_started', object: sub, requestId });
      return { status: 'trial', trialEnd: sub.get('trialEnd').toISOString(), planCode: code };
    });
  });

  C.register('subscription-status', async request => {
    const p = C.exact(request.params, ['workspaceId']);
    const { workspace } = await C.membership(request, C.workspaceId(p));
    const query = C.q('Subscription');
    query.equalTo('workspace', workspace);
    query.descending('createdAt');
    const sub = await C.one(query);
    if (!sub) return { status: 'plan_required' };
    const expired = sub.get('status') === 'trial' && sub.get('trialEnd') <= new Date();
    const plan = sub.get('plan') && await C.get('Plan', sub.get('plan').id);
    return { status: expired ? 'trial_expired' : sub.get('status'),
      trialEnd: sub.get('trialEnd')?.toISOString() || null, planCode: plan?.get('code') || null };
  });
}
module.exports = { mount, workspaceView };

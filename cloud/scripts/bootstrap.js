'use strict';
// Operator-run seed. Never put the master key in the repository or Flutter build.
const fs = require('node:fs');
const path = require('node:path');

const url = process.env.PARSE_SERVER_URL;
const appId = process.env.PARSE_APPLICATION_ID;
const master = process.env.PARSE_MASTER_KEY;
if (!url || !appId || !master || !url.startsWith('https://')) {
  console.error('Set PARSE_SERVER_URL, PARSE_APPLICATION_ID and PARSE_MASTER_KEY.');
  process.exit(1);
}
const segments = JSON.parse(fs.readFileSync(path.join(__dirname, '../config/segments.json'), 'utf8'));
const plansPath = process.env.PLANS_CONFIG_PATH;
const plans = plansPath ? JSON.parse(fs.readFileSync(plansPath, 'utf8')) : [];
if (!Array.isArray(plans)) throw new Error('PLANS_CONFIG_PATH must be a JSON array.');
const headers = { 'X-Parse-Application-Id': appId, 'X-Parse-Master-Key': master,
  'Content-Type': 'application/json' };

async function call(method, endpoint, body) {
  const response = await fetch(url.replace(/\/$/, '') + endpoint,
    { method, headers, body: body && JSON.stringify(body) });
  if (!response.ok) throw new Error('Parse request failed: ' + response.status);
  return response.json();
}

async function seed(className, items) {
  for (const item of items) {
    if (!/^[a-z][a-z0-9_]*$/.test(item.code) || !Number.isInteger(item.version) ||
        item.version < 1) throw new Error('Invalid code or version.');
    if (className === 'Plan' &&
        (!Number.isInteger(item.amount) || item.amount < 0 ||
         !Number.isInteger(item.trialDays) || item.trialDays < 0 ||
         !['BRL'].includes(item.currency) || !['monthly', 'yearly'].includes(item.billingInterval) ||
         !Array.isArray(item.segmentCodes) || !item.segmentCodes.length ||
         !item.limits || !Number.isInteger(item.limits.services) ||
         !Number.isInteger(item.limits.resources))) {
      throw new Error('Incomplete plan configuration.');
    }
    const where = encodeURIComponent(JSON.stringify({ code: item.code, version: item.version }));
    const result = await call('GET', '/classes/' + className + '?where=' + where + '&limit=1');
    if (result.results.length) {
      console.log(className + ' ' + item.code + ' v' + item.version + ': exists, skipped');
      continue;
    }
    await call('POST', '/classes/' + className, { ...item, status: 'active',
      ACL: {} });
    console.log(className + ' ' + item.code + ' v' + item.version + ': created');
  }
}
(async () => {
  await seed('SegmentDefinition', segments);
  if (plans.length) await seed('Plan', plans);
  else console.log('No plans supplied. Onboarding can create a workspace; trial requires a real plan.');
})().catch(error => { console.error(error.message); process.exitCode = 1; });

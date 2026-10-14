// Usage: DATABASE_URL=... node scripts/run.mjs migrate|test
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const cmd = process.argv[2];

if (!['migrate', 'test'].includes(cmd)) {
  console.error('usage: DATABASE_URL=... node scripts/run.mjs migrate|test');
  process.exit(2);
}
const url = process.env.DATABASE_URL;
if (!url) {
  console.error('DATABASE_URL is not set; refusing to run.');
  process.exit(2);
}

// Parse manually so sslmode params in the URL cannot override our ssl choice
// and so odd passwords do not break URL parsing.
function parseUrl(u) {
  const m = /^postgres(?:ql)?:\/\/([^:@\/]+)(?::(.*))?@([^@\/:]+)(?::(\d+))?\/([^?]+)/.exec(u);
  if (!m) return null;
  const dec = (s) => { try { return decodeURIComponent(s); } catch { return s; } };
  return {
    user: dec(m[1]),
    password: m[2] === undefined ? undefined : dec(m[2]),
    host: m[3],
    port: m[4] ? Number(m[4]) : 5432,
    database: dec(m[5]),
  };
}

const cfg = parseUrl(url);
if (!cfg) {
  console.error('DATABASE_URL is not a valid postgresql:// URL (value not shown).');
  process.exit(2);
}
const isLocal = ['localhost', '127.0.0.1', '::1'].includes(cfg.host);
const client = new pg.Client({
  ...cfg,
  ssl: isLocal ? false : { rejectUnauthorized: false },
});

async function migrate() {
  await client.query(`create table if not exists public.schema_migrations (
    name text primary key, applied_at timestamptz default now())`);
  const done = new Set(
    (await client.query('select name from public.schema_migrations')).rows.map((r) => r.name),
  );
  const dir = path.join(root, 'migrations');
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  for (const f of files) {
    if (done.has(f)) { console.log(`skip   ${f}`); continue; }
    const sql = fs.readFileSync(path.join(dir, f), 'utf8');
    await client.query('begin');
    try {
      await client.query(sql);
      await client.query('insert into public.schema_migrations(name) values ($1)', [f]);
      await client.query('commit');
      console.log(`apply  ${f}`);
    } catch (e) {
      await client.query('rollback').catch(() => {});
      console.error(`FAILED ${f}: ${e.message}`);
      return 1;
    }
  }
  return 0;
}

async function runTests() {
  const dir = path.join(root, 'tests');
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  let failed = 0;
  let passed = 0;
  for (const f of files) {
    console.log(`# ${f}`);
    const sql = fs.readFileSync(path.join(dir, f), 'utf8');
    try {
      const res = await client.query(sql);
      const results = Array.isArray(res) ? res : [res];
      for (const r of results) {
        for (const row of r.rows ?? []) {
          const v = Object.values(row)[0];
          if (typeof v !== 'string') continue;
          if (v.startsWith('not ok')) { failed++; console.log(v); }
          else if (v.startsWith('ok')) { passed++; console.log(v); }
        }
      }
    } catch (e) {
      failed++;
      console.log(`not ok - ${f} errored: ${e.message}`);
      await client.query('rollback').catch(() => {});
    }
  }
  console.log(`# passed ${passed}, failed ${failed}`);
  return failed > 0 || passed === 0 ? 1 : 0;
}

let code = 1;
try {
  await client.connect();
  code = cmd === 'migrate' ? await migrate() : await runTests();
} catch (e) {
  console.error(`error: ${e.message}`);
} finally {
  await client.end().catch(() => {});
}
process.exit(code);

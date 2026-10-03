import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import test from 'node:test';

const requireFromOpenClaw = createRequire('/Users/tarundevesetti/.npm-global/lib/node_modules/openclaw/package.json');
const { Client } = requireFromOpenClaw('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = requireFromOpenClaw('@modelcontextprotocol/sdk/client/stdio.js');

test('Calendar bridge exposes only safe writes and validates them without changing Calendar', async () => {
  const client = new Client({ name: 'jinx-calendar-test', version: '1.0.0' });
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve('Scripts/jinx-calendar-mcp.mjs')],
    env: { ...process.env, JINX_CALENDAR_DRY_RUN: '1' },
  });
  try {
    await client.connect(transport);
    const { tools } = await client.listTools();
    assert.deepEqual(tools.map(({ name }) => name).sort(), ['calendar_create', 'calendar_update']);
    const created = await client.callTool({
      name: 'calendar_create',
      arguments: {
        summary: 'Jinx diagnostic dry run',
        from: '2026-10-05T10:00:00-07:00',
        to: '2026-10-05T10:30:00-07:00',
      },
    });
    assert.equal(created.isError, undefined);
    const output = JSON.parse(created.content[0].text);
    assert.equal(output.dry_run, true);
    assert.equal(output.op, 'calendar.create');
    const invalid = await client.callTool({
      name: 'calendar_create',
      arguments: {
        summary: 'Invalid time order',
        from: '2026-10-05T11:00:00-07:00',
        to: '2026-10-05T10:30:00-07:00',
      },
    });
    assert.equal(invalid.isError, true);
  } finally {
    await client.close();
  }
});

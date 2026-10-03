#!/usr/bin/env node
// Narrow Calendar writer for Jinx. No Gmail commands or arbitrary shell input.
import { execFile } from 'node:child_process';
import { createRequire } from 'node:module';
import { promisify } from 'node:util';

// Reuse the MCP SDK shipped with the OpenClaw installation running this bridge.
const requireFromOpenClaw = createRequire('/Users/tarundevesetti/.npm-global/lib/node_modules/openclaw/package.json');
const { McpServer } = requireFromOpenClaw('@modelcontextprotocol/sdk/server/mcp.js');
const { StdioServerTransport } = requireFromOpenClaw('@modelcontextprotocol/sdk/server/stdio.js');
const z = requireFromOpenClaw('zod/v4');

const run = promisify(execFile);
const GOG = '/usr/local/bin/gog';
const ACCOUNT = 'tarundevmail@gmail.com';
const COMMON = [
  '--enable-commands-exact=calendar.create,calendar.update,calendar.event',
  '--gmail-no-send',
  `--account=${ACCOUNT}`,
  '--no-input',
  '--json',
];
const textField = (value, name, max = 500) => {
  if (typeof value !== 'string' || !value.trim() || value.length > max) {
    throw new Error(`${name} must be nonempty text of at most ${max} characters`);
  }
  return value.trim();
};
const timeField = (value, name) => {
  const text = textField(value, name, 40);
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:\d{2})$/.test(text) || Number.isNaN(Date.parse(text))) {
    throw new Error(`${name} must be RFC3339 with a UTC offset`);
  }
  return text;
};
const optionalText = (args, key, max) => {
  if (args[key] === undefined) return [];
  return [`--${key}=${textField(args[key], key, max)}`];
};
const callGog = async (args) => {
  const flags = process.env.JINX_CALENDAR_DRY_RUN === '1' ? ['--dry-run'] : [];
  const { stdout } = await run(GOG, [...COMMON, ...flags, 'calendar', ...args], {
    timeout: 30_000,
    maxBuffer: 100_000,
    shell: false,
  });
  return stdout.trim();
};
async function handleCall(name, args) {
  if (!args || typeof args !== 'object' || Array.isArray(args)) throw new Error('Invalid arguments');
  const allowed = new Set(name === 'calendar_create' ? ['summary', 'from', 'to', 'description', 'location'] : name === 'calendar_update' ? ['eventId', 'summary', 'from', 'to', 'description', 'location'] : []);
  if (!allowed.size || Object.keys(args).some((key) => !allowed.has(key))) throw new Error('Unknown tool or argument');
  if (name === 'calendar_create') {
    const summary = textField(args.summary, 'summary', 200);
    const from = timeField(args.from, 'from');
    const to = timeField(args.to, 'to');
    if (Date.parse(to) <= Date.parse(from)) throw new Error('to must be after from');
    return callGog(['create', 'primary', `--summary=${summary}`, `--from=${from}`, `--to=${to}`, ...optionalText(args, 'description', 5000), ...optionalText(args, 'location', 500), '--send-updates=none']);
  }
  const eventId = textField(args.eventId, 'eventId', 256);
  if (!/^[a-zA-Z0-9_-]+$/.test(eventId)) throw new Error('Invalid eventId');
  const changes = ['summary', 'from', 'to', 'description', 'location'].filter((key) => args[key] !== undefined);
  if (!changes.length) throw new Error('At least one change is required');
  if ((args.from === undefined) !== (args.to === undefined)) throw new Error('from and to must be changed together');
  const eventJson = await callGog(['event', 'primary', eventId]);
  const event = JSON.parse(eventJson).event;
  if (!event || typeof event !== 'object') throw new Error('Could not verify event attendees');
  if (Array.isArray(event.attendees) && event.attendees.length > 0) throw new Error('Events with attendees are not editable through this bridge');
  const flags = [
    ...optionalText(args, 'summary', 200),
    ...optionalText(args, 'description', 5000),
    ...optionalText(args, 'location', 500),
  ];
  if (args.from !== undefined) {
    const from = timeField(args.from, 'from');
    const to = timeField(args.to, 'to');
    if (Date.parse(to) <= Date.parse(from)) throw new Error('to must be after from');
    flags.push(`--from=${from}`, `--to=${to}`);
  }
  return callGog(['update', 'primary', eventId, ...flags, '--send-updates=none']);
}

const server = new McpServer({ name: 'jinx-calendar-writer', version: '1.0.0' });
const resultFor = async (name, args) => {
  try {
    return { content: [{ type: 'text', text: await handleCall(name, args) }] };
  } catch (error) {
    return { isError: true, content: [{ type: 'text', text: error.message }] };
  }
};
server.registerTool('calendar_create', {
  description: 'Create one event on the owner’s primary Google Calendar. No attendees or email invitations.',
  inputSchema: {
    summary: z.string(),
    from: z.string().describe('RFC3339 start time including offset'),
    to: z.string().describe('RFC3339 end time including offset'),
    description: z.string().optional(),
    location: z.string().optional(),
  },
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: true },
}, (args) => resultFor('calendar_create', args));
server.registerTool('calendar_update', {
  description: 'Update title, time, description, or location of an attendee-free event on the owner’s primary Google Calendar. Cannot delete or invite.',
  inputSchema: {
    eventId: z.string(),
    summary: z.string().optional(),
    from: z.string().optional(),
    to: z.string().optional(),
    description: z.string().optional(),
    location: z.string().optional(),
  },
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: true },
}, (args) => resultFor('calendar_update', args));

await server.connect(new StdioServerTransport());

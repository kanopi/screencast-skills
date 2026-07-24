// The Playwright "brain" for browser-action scenes. Launched by browser.sh.
//
// A single persistent Chromium is launched at a known screen position/size with
// remote debugging on a fixed port. Each subcommand connects over CDP, acts, and
// disconnects, so the window survives between browser.sh calls (open -> box ->
// wait -> ...). Playwright input is NOT used to click on camera — `box` returns
// the element's viewport-center coordinates, and hands.sh (cliclick) does the
// visible move + click. This mirrors the sibling skill's agent-browser/xdotool
// split, ported to the macOS host.

import { spawn } from 'node:child_process';
import { mkdirSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
// ESM import does not honor NODE_PATH; resolve the globally-installed playwright
// via require (which does). preflight installs it with npm i -g.
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const CDP_PORT = process.env.TUT_CDP_PORT || '9222';
const CDP_URL = `http://127.0.0.1:${CDP_PORT}`;
const WIN = {
  x: +(process.env.WIN_X || 0),
  y: +(process.env.WIN_Y || 0),
  w: +(process.env.WIN_W || 1920),
  h: +(process.env.WIN_H || 1080),
};
const HDIR = process.env.HDIR || '.tutorial-build/default';
const USER_DATA = `${HDIR}/chrome-profile`;

const [cmd, ...args] = process.argv.slice(2);

function fail(msg) {
  console.error(`error: ${msg}`);
  process.exit(1);
}

async function connect() {
  try {
    const browser = await chromium.connectOverCDP(CDP_URL);
    return browser;
  } catch {
    fail('no browser session (run: browser.sh start <url>)');
  }
}

async function firstPage(browser) {
  const ctx = browser.contexts()[0];
  if (!ctx) fail('no browser context');
  const pages = ctx.pages();
  return pages[0] || (await ctx.newPage());
}

switch (cmd) {
  case 'start': {
    const url = args[0] || 'about:blank';
    mkdirSync(USER_DATA, { recursive: true });
    const exe = chromium.executablePath();
    if (!existsSync(exe)) fail('chromium not installed (npx playwright install chromium)');
    // Launch the raw Chromium binary so it owns a real, visible window at a fixed
    // position/size. Playwright then attaches over CDP for the read-only work.
    const flags = [
      `--remote-debugging-port=${CDP_PORT}`,
      `--user-data-dir=${USER_DATA}`,
      `--window-position=${WIN.x},${WIN.y}`,
      `--window-size=${WIN.w},${WIN.h}`,
      '--force-device-scale-factor=1',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-infobars',
      '--disable-features=Translate',
      '--hide-crash-restore-bubble',
      url,
    ];
    const child = spawn(exe, flags, { detached: true, stdio: 'ignore' });
    child.unref();
    // Wait for CDP to answer.
    for (let i = 0; i < 30; i++) {
      try {
        const r = await fetch(`${CDP_URL}/json/version`);
        if (r.ok) { console.log('session up'); process.exit(0); }
      } catch { /* not up yet */ }
      await new Promise((r) => setTimeout(r, 500));
    }
    fail('Chromium CDP did not come up');
    break;
  }
  case 'open': {
    const browser = await connect();
    const page = await firstPage(browser);
    await page.goto(args[0], { waitUntil: 'load' });
    await browser.close();
    console.log(`opened ${args[0]}`);
    break;
  }
  case 'wait': {
    const browser = await connect();
    const page = await firstPage(browser);
    await page.locator(args[0]).first().waitFor({ state: 'visible', timeout: 30000 });
    await browser.close();
    console.log('visible');
    break;
  }
  case 'box': {
    const browser = await connect();
    const page = await firstPage(browser);
    const el = page.locator(args[0]).first();
    await el.waitFor({ state: 'visible', timeout: 30000 });
    const b = await el.boundingBox();
    await browser.close();
    if (!b) fail(`no bounding box for ${args[0]}`);
    // Viewport center. hands.sh adds the OFF_X/OFF_Y calibration to get screen px.
    console.log(`${Math.round(b.x + b.width / 2)} ${Math.round(b.y + b.height / 2)}`);
    break;
  }
  case 'fill': {
    const browser = await connect();
    const page = await firstPage(browser);
    await page.locator(args[0]).first().fill(args[1] ?? '');
    await browser.close();
    console.log('filled');
    break;
  }
  case 'snapshot': {
    const browser = await connect();
    const page = await firstPage(browser);
    const tree = await page.accessibility.snapshot();
    await browser.close();
    console.log(JSON.stringify(tree, null, 2));
    break;
  }
  case 'stop': {
    try {
      const browser = await chromium.connectOverCDP(CDP_URL);
      for (const ctx of browser.contexts()) await ctx.close();
      await browser.close();
    } catch { /* already down */ }
    console.log('session stopped');
    break;
  }
  default:
    fail(`unknown command: ${cmd} (start|open|wait|box|fill|snapshot|stop)`);
}

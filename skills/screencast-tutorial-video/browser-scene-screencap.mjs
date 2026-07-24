// Method B browser engine (automated): drive a headed, fullscreen Chromium with
// Playwright while ffmpeg avfoundation captures the real screen, then scale the
// capture to 1920x1080. Shows the real browser/OS; needs Screen Recording
// permission on the running process. Produces scenes/NN.mp4.
//
// Args: <NN> <url> [holdSeconds]
// Env:  HDIR, FFMPEG, TUT_AVF_SCREEN (display index), OUT (optional),
//       TUT_SCENE_SCROLL=1 to gentle-scroll during the hold.

import { mkdirSync, existsSync, readFileSync, openSync } from 'node:fs';
import { spawn, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const [nn, url, holdArg] = process.argv.slice(2);
const hold = Number(holdArg || 10);
const HDIR = process.env.HDIR || '.tutorial-build/default';
const FFMPEG = process.env.FFMPEG || 'ffmpeg';
const outDir = `${HDIR}/scenes`;
const out = process.env.OUT || `${outDir}/${nn}.mp4`;
const log = `${outDir}/${nn}.screencap.log`;
mkdirSync(outDir, { recursive: true });

// avfoundation device indices shift when cameras connect/disconnect (Continuity
// Camera), so detect the "Capture screen 0" index at runtime rather than trust a
// fixed number. TUT_AVF_SCREEN overrides only if it still points at a screen.
function detectScreenIndex(pref) {
  const r = spawnSync(FFMPEG, ['-hide_banner', '-f', 'avfoundation',
    '-list_devices', 'true', '-i', ''], { encoding: 'utf8' });
  const screens = [];
  let inVideo = false;
  for (const l of (r.stderr || '').split('\n')) {
    if (/video devices/i.test(l)) { inVideo = true; continue; }
    if (/audio devices/i.test(l)) { inVideo = false; continue; }
    if (!inVideo) continue;
    const m = l.match(/\[(\d+)\]\s+Capture screen (\d+)/i);
    if (m) screens.push({ index: +m[1], screen: +m[2] });
  }
  if (pref !== undefined && screens.some((s) => s.index === +pref)) return +pref;
  const zero = screens.find((s) => s.screen === 0);
  return zero ? zero.index : (screens[0] ? screens[0].index : +(pref ?? 0));
}
const AVF = String(detectScreenIndex(process.env.TUT_AVF_SCREEN));

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Headed, fullscreen, and with the "controlled by automated software" infobar
// suppressed so it does not show in the capture.
const browser = await chromium.launch({
  headless: false,
  ignoreDefaultArgs: ['--enable-automation'],
  args: ['--kiosk', '--start-fullscreen', '--disable-infobars',
    '--no-first-run', '--no-default-browser-check', '--disable-features=Translate'],
});
const context = await browser.newContext({ viewport: null });
const page = await context.newPage();
await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 }).catch(() => {});
await sleep(1800); // let the fullscreen transition + first paint settle

// Start the screen capture (self-stops after `hold` seconds). ffmpeg output goes
// to a log so failures are visible instead of a false success.
const logFd = openSync(log, 'w');
const ff = spawn(FFMPEG, [
  '-y', '-f', 'avfoundation', '-capture_cursor', '1', '-framerate', '25',
  '-t', String(hold), '-i', `${AVF}:`,
  '-vf', 'scale=1920:1080', '-c:v', 'libx264', '-preset', 'medium',
  '-pix_fmt', 'yuv420p', out,
], { stdio: ['ignore', logFd, logFd] });
const done = new Promise((res) => ff.on('close', res));

// Drive the visible motion during the capture window.
if (process.env.TUT_SCENE_SCROLL === '1') {
  const steps = Math.max(1, Math.floor(hold * 2));
  for (let i = 0; i < steps; i++) { await page.mouse.wheel(0, 260); await sleep(500); }
} else {
  await sleep(hold * 1000);
}

await done;         // wait for ffmpeg to finalize
await context.close();
await browser.close();

if (!existsSync(out)) {
  const tail = existsSync(log) ? readFileSync(log, 'utf8').split('\n').slice(-8).join('\n') : '(no log)';
  console.error(`error: capture produced no file (device index ${AVF}). ffmpeg log tail:\n${tail}`);
  process.exit(1);
}
console.log(`browser scene ${nn} (screencap, device ${AVF}) -> ${out}`);

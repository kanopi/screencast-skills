// Method A browser engine: Playwright records the page directly to video at a
// fixed 1920x1080 (headless, off-screen) — no OS screen capture, no Retina, no
// permissions, and it records ONLY the page (never the desktop). Produces
// scenes/NN.mp4. Launched by browser-scene.sh.
//
// Usage:
//   node browser-scene.mjs <NN> <spec.json>      # spec-driven (preferred)
//   node browser-scene.mjs <NN> <url> [seconds]  # simple: load, gentle scroll, hold
//
// Spec JSON: { "url": "...", "steps": [ <step>, ... ] }
//   step kinds: {"waitMs":N} | {"highlightText":"..."} | {"highlightSelector":"css"}
//     | {"clearHighlights":true} | {"scrollToText":"..."} | {"scrollTop":true}
//     | {"scrollBy":px,"overMs":N} | {"scrollThrough":true,"overMs":N}
//
// Env: HDIR, FFMPEG, OUT (optional).

import { mkdirSync, readdirSync, rmSync, existsSync, readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright'); // ESM import ignores NODE_PATH; require honors it

const [nn, specArg, holdArg] = process.argv.slice(2);
const HDIR = process.env.HDIR || '.tutorial-build/default';
const FFMPEG = process.env.FFMPEG || 'ffmpeg';
const size = { width: 1920, height: 1080 };
const outDir = `${HDIR}/scenes`;
const out = process.env.OUT || `${outDir}/${nn}.mp4`;
const tmpDir = `${HDIR}/pw-video-${nn}`;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Build the scene spec from a JSON file or the simple url+seconds form.
let spec;
if (specArg && specArg.endsWith('.json')) {
  spec = JSON.parse(readFileSync(specArg, 'utf8'));
} else {
  const s = Number(holdArg || 8);
  spec = { url: specArg, steps: [{ waitMs: 1200 }, { scrollThrough: true, overMs: s * 1000 }, { waitMs: 800 }] };
}

mkdirSync(outDir, { recursive: true });
rmSync(tmpDir, { recursive: true, force: true });
mkdirSync(tmpDir, { recursive: true });

const HL = '__tut_hl__';
async function highlight(page, locator) {
  const el = locator.first();
  if (!(await el.count())) return;
  await el.evaluate((node, cls) => {
    node.classList.add(cls);
    node.style.outline = '4px solid #f5c518';
    node.style.outlineOffset = '4px';
    node.style.borderRadius = '4px';
    node.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, HL).catch(() => {});
}
async function clearHighlights(page) {
  await page.evaluate((cls) => {
    document.querySelectorAll('.' + cls).forEach((n) => {
      n.style.outline = ''; n.style.outlineOffset = ''; n.classList.remove(cls);
    });
  }, HL).catch(() => {});
}
async function smoothScrollTo(page, targetY, overMs) {
  await page.evaluate(async ({ targetY, overMs }) => {
    const startY = window.scrollY;
    const dist = targetY - startY;
    const start = performance.now();
    await new Promise((resolve) => {
      function frame(now) {
        const t = Math.min(1, (now - start) / overMs);
        const ease = t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2; // easeInOutQuad
        window.scrollTo(0, startY + dist * ease);
        if (t < 1) requestAnimationFrame(frame); else resolve();
      }
      requestAnimationFrame(frame);
    });
  }, { targetY, overMs });
}

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: size, deviceScaleFactor: 2, recordVideo: { dir: tmpDir, size } });
const page = await context.newPage();
await page.goto(spec.url, { waitUntil: 'networkidle', timeout: 60000 }).catch(() => {});
// Wait for web fonts to finish loading so no flash of unstyled text (FOUT) is
// recorded. The assembly also trims the first ~1.5s of each clip as a backstop.
await page.evaluate(() => (document.fonts && document.fonts.ready) ? document.fonts.ready : Promise.resolve()).catch(() => {});
await page.waitForTimeout(700);

for (const step of spec.steps || []) {
  if (step.waitMs) await sleep(step.waitMs);
  else if (step.highlightText) await highlight(page, page.locator(`text=${step.highlightText}`));
  else if (step.highlightSelector) await highlight(page, page.locator(step.highlightSelector));
  else if (step.clearHighlights) await clearHighlights(page);
  else if (step.scrollTop) await smoothScrollTo(page, 0, step.overMs || 800);
  else if (step.scrollToText) {
    const el = page.locator(`text=${step.scrollToText}`).first();
    await el.evaluate((n) => n.scrollIntoView({ behavior: 'smooth', block: 'center' })).catch(() => {});
    await sleep(step.overMs || 1200);
  } else if (step.scrollBy) {
    const y = await page.evaluate(() => window.scrollY);
    await smoothScrollTo(page, y + step.scrollBy, step.overMs || 1500);
  } else if (step.scrollThrough) {
    const bottom = await page.evaluate(() => document.body.scrollHeight - window.innerHeight);
    await smoothScrollTo(page, Math.max(0, bottom), step.overMs || 8000);
  }
}

await context.close();
await browser.close();

const webm = readdirSync(tmpDir).find((f) => f.endsWith('.webm'));
if (!webm) { console.error('error: no video produced'); process.exit(1); }
execFileSync(FFMPEG, [
  '-y', '-i', `${tmpDir}/${webm}`,
  '-vf', 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=25',
  '-c:v', 'libx264', '-preset', 'medium', '-pix_fmt', 'yuv420p', out,
], { stdio: 'ignore' });
rmSync(tmpDir, { recursive: true, force: true });
if (!existsSync(out)) { console.error('error: ffmpeg produced no file'); process.exit(1); }
console.log(`browser scene ${nn} (playwright) -> ${out}`);

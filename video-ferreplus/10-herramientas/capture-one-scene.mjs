import { execFileSync } from 'node:child_process';
import { copyFileSync, mkdirSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import OBSWebSocket from 'obs-websocket-js';
import { chromium } from 'playwright-core';

const toolsDir = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(toolsDir, '..');
const chapterRoot = resolve(projectRoot, '01-capitulo-01');
const storyboard = JSON.parse(readFileSync(resolve(chapterRoot, '01-planificacion/storyboard.json'), 'utf8'));
const scene = storyboard.scenes[0];
const runId = Date.now();
const obsSceneName = `${scene.obsScene}-${runId}`;
const obsInputName = `FerrePlusPortal-${runId}`;
const browserExecutable = '/usr/bin/google-chrome';
const obsConfigPath = resolve(toolsDir, 'obs-runtime/config/obs-studio/plugin_config/obs-websocket/config.json');
const obsConfig = JSON.parse(readFileSync(obsConfigPath, 'utf8'));
const rawDir = resolve(chapterRoot, '04-grabaciones/bruto');
const captureDir = resolve(chapterRoot, '04-grabaciones/capturas');
mkdirSync(rawDir, { recursive: true });
mkdirSync(captureDir, { recursive: true });

const browser = await chromium.launch({ executablePath: browserExecutable, headless: true, args: ['--no-sandbox'] });
const page = await browser.newPage({ viewport: { width: scene.capture.browserWidth, height: scene.capture.browserHeight } });
await page.goto(scene.sourceUrl, { waitUntil: 'networkidle', timeout: 30000 });
await page.screenshot({ path: resolve(captureDir, 'portal-publico.png'), fullPage: false });
await page.waitForTimeout(scene.capture.waitAfterLoadMs);
await browser.close();

const obs = new OBSWebSocket();
await obs.connect('ws://127.0.0.1:4455', obsConfig.server_password);
await obs.call('SetVideoSettings', {
  baseWidth: scene.capture.browserWidth,
  baseHeight: scene.capture.browserHeight,
  outputWidth: scene.capture.browserWidth,
  outputHeight: scene.capture.browserHeight,
  fpsNumerator: 30,
  fpsDenominator: 1
});
const scenes = await obs.call('GetSceneList');
await obs.call('CreateScene', { sceneName: obsSceneName });
const inputs = await obs.call('GetInputList');
await obs.call('CreateInput', {
  sceneName: obsSceneName,
  inputName: obsInputName,
  inputKind: 'browser_source',
  inputSettings: {
    url: scene.sourceUrl,
    width: scene.capture.browserWidth,
    height: scene.capture.browserHeight,
    fps: 30,
    reroute_audio: true
  },
  sceneItemEnabled: true
});
await obs.call('SetCurrentProgramScene', { sceneName: obsSceneName });
const ambientInputs = new Set(['Desktop Audio', 'Mic/Aux']);
for (const { inputName } of inputs.inputs) {
  if (ambientInputs.has(inputName)) {
    await obs.call('SetInputMute', { inputName, inputMuted: true });
  }
}
await new Promise((resolve) => setTimeout(resolve, scene.capture.waitAfterLoadMs));
await obs.call('StartRecord');
await new Promise((resolve) => setTimeout(resolve, (scene.durationSeconds + 8) * 1000));
const stopped = await obs.call('StopRecord');
await obs.call('RemoveScene', { sceneName: obsSceneName });
await obs.disconnect();

const sourcePath = stopped.outputPath;
if (!sourcePath) throw new Error('OBS did not return an output path');
const rawPath = resolve(rawDir, 'portal-publico.mkv');
copyFileSync(sourcePath, rawPath);
console.log(JSON.stringify({ sourcePath, rawPath, screenshot: resolve(captureDir, 'portal-publico.png') }, null, 2));

import { copyFileSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import OBSWebSocket from 'obs-websocket-js';
import { chromium } from 'playwright-core';

const toolsDir = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(toolsDir, '..');
const chapterRoot = resolve(projectRoot, '01-capitulo-01');
const storyboard = JSON.parse(readFileSync(resolve(chapterRoot, '01-planificacion/storyboard-capitulo-01.json'), 'utf8'));
const narration = JSON.parse(readFileSync(resolve(chapterRoot, '02-guion/narraciones-escenas.json'), 'utf8'));
const obsConfig = JSON.parse(readFileSync(resolve(toolsDir, 'obs-runtime/config/obs-studio/plugin_config/obs-websocket/config.json'), 'utf8'));
const rawDir = resolve(chapterRoot, '04-grabaciones/bruto');
const captureDir = resolve(chapterRoot, '04-grabaciones/capturas');
const audioDir = resolve(chapterRoot, '05-audio/voz/escenas');
mkdirSync(rawDir, { recursive: true });
mkdirSync(captureDir, { recursive: true });

const pageMarkup = (body) => `<!doctype html><html><head><meta charset="utf-8"><style>
*{box-sizing:border-box}body{margin:0;width:1920px;height:1080px;overflow:hidden;background:#f5f7f4;color:#17252d;font-family:Arial, sans-serif}h1{font-size:78px;margin:0 0 28px;line-height:1.05}h2{font-size:42px;margin:0 0 18px;color:#078b86}p{font-size:32px;line-height:1.4;color:#4f6570}.page{padding:120px; height:100%}.pill{display:inline-block;padding:18px 30px;border-radius:40px;background:#e4a33a;color:#17252d;font-weight:700;font-size:26px}.cards{display:flex;gap:28px;margin-top:60px}.card{border:2px solid #cddbd8;border-radius:24px;padding:32px;width:32%;background:#fff}.row{display:flex;gap:34px;align-items:center;margin-top:54px}.node{padding:26px 38px;border-radius:20px;background:#17252d;color:#fff;font-size:30px;font-weight:700}.arrow{font-size:42px;color:#078b86}.terminal{background:#101a1e;color:#d9f3e9;padding:40px;border-radius:24px;font:26px/1.6 monospace;white-space:pre}.small{font-size:24px;color:#4f6570}.admin-shell{display:grid;grid-template-columns:270px 1fr;height:100%;background:#f4f7f8}.admin-side{background:#17252d;color:#fff;padding:42px 28px}.admin-side h2{color:#fff;font-size:30px;margin:0 0 52px}.admin-side div{padding:18px 16px;border-radius:12px;margin:8px 0;font-size:24px;color:#c7d6da}.admin-side .active{background:#078b86;color:#fff}.admin-main{padding:48px 58px}.admin-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:38px}.admin-top h1{font-size:48px;margin:0}.admin-user{font-size:22px;color:#4f6570}.admin-metrics{display:grid;grid-template-columns:repeat(4,1fr);gap:20px}.admin-metric{background:#fff;border-radius:18px;padding:26px;border:1px solid #d7e1e3}.admin-metric strong{display:block;font-size:38px;color:#17252d;margin-top:10px}.admin-metric span{color:#60747c;font-size:20px}.admin-panels{display:grid;grid-template-columns:1.5fr 1fr;gap:24px;margin-top:28px}.admin-panel{background:#fff;border:1px solid #d7e1e3;border-radius:18px;padding:28px}.admin-panel h3{font-size:26px;margin:0 0 24px;color:#17252d}.bars{height:190px;display:flex;align-items:end;gap:18px;border-bottom:1px solid #d7e1e3}.bar{width:42px;background:#078b86;border-radius:8px 8px 0 0}.activity{display:flex;justify-content:space-between;border-bottom:1px solid #edf1f2;padding:16px 0;font-size:20px;color:#4f6570}</style></head><body>${body}</body></html>`;

const sleep = (ms) => new Promise((resolveSleep) => setTimeout(resolveSleep, ms));
const waitForStableRecording = async (recordingPath) => {
  let previousSize = -1;
  for (let attempt = 1; attempt <= 30; attempt += 1) {
    const size = statSync(recordingPath).size;
    let duration = '';
    try {
      duration = execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', recordingPath], { encoding: 'utf8' }).trim();
    } catch {}
    if (size > 0 && size === previousSize && duration && duration !== 'N/A') return Number(duration);
    previousSize = size;
    await sleep(500);
  }
  throw new Error(`OBS recording did not stabilize: ${recordingPath}`);
};

const server = createServer((req, res) => {
  const path = new URL(req.url, 'http://127.0.0.1').pathname;
  if (path === '/admin-dashboard-real.png') {
    res.writeHead(200, { 'Content-Type': 'image/png', 'Cache-Control': 'no-store' });
    res.end(readFileSync(resolve(captureDir, 'admin-dashboard-real.png')));
    return;
  }
  let body;
  if (path === '/title') body = '<div class="page" style="background:linear-gradient(135deg,#17252d 0%,#203943 58%,#078b86 140%);color:#fff;position:relative;overflow:hidden"><div style="position:absolute;right:-100px;top:-160px;width:720px;height:720px;border:2px solid rgba(228,163,58,.35);border-radius:50%"></div><div style="position:absolute;right:140px;bottom:-280px;width:600px;height:600px;border:2px solid rgba(255,255,255,.12);border-radius:50%"></div><span class="pill">FERREPLUS · CAPÍTULO 1</span><div style="margin-top:115px;max-width:1250px"><h1 style="font-size:92px;color:#fff;letter-spacing:-2px">Qué es FerrePlus<br><span style="color:#e4a33a">y cómo se conectan sus partes</span></h1><p style="font-size:36px;color:#c7d6da;max-width:900px">Una lectura visual de interfaces, APIs, enrutamiento y datos.</p></div><div style="position:absolute;bottom:90px;left:120px;display:flex;gap:18px"><span style="padding:14px 20px;border:1px solid rgba(255,255,255,.3);border-radius:30px;color:#d9f3e9;font-size:22px">Arquitectura</span><span style="padding:14px 20px;border:1px solid rgba(255,255,255,.3);border-radius:30px;color:#d9f3e9;font-size:22px">Portal</span><span style="padding:14px 20px;border:1px solid rgba(255,255,255,.3);border-radius:30px;color:#d9f3e9;font-size:22px">APIs</span><span style="padding:14px 20px;border:1px solid rgba(255,255,255,.3);border-radius:30px;color:#d9f3e9;font-size:22px">Datos</span></div></div>';
  else if (path === '/admin-dashboard-capture') body = '<div style="width:1920px;height:1080px;background:#f5f7f4"><img src="/admin-dashboard-real.png" style="display:block;width:1920px;height:1080px;object-fit:contain"></div>';
  else if (path === '/diagram') body = '<div class="page"><h1>Arquitectura general</h1><p>FerrePlus separa interfaces, APIs, enrutamiento y datos.</p><div class="row"><div class="node">Navegador</div><div class="arrow">→</div><div class="node" style="background:#078b86">Traefik</div><div class="arrow">→</div><div class="node">Interfaces</div><div class="arrow">→</div><div class="node">APIs</div></div><div class="cards"><div class="card"><h2>Admin UI</h2><p>Operación interna y usuarios autenticados.</p></div><div class="card"><h2>Portal público</h2><p>Publicaciones, convocatorias y formularios.</p></div><div class="card"><h2>Servicios de datos</h2><p>PostgreSQL · MongoDB · Redis · MinIO</p></div></div></div>';
  else if (path === '/terminal') body = '<div class="page"><h1>Docker Compose y Traefik</h1><div class="terminal">$ docker compose ps\nNAME                    STATUS\nferreplus-traefik       running\nferreplus-admin-api     running\nferreplus-public-api    running\nferreplus-portal        running\nferreplus-admin          running</div><p class="small">Salida resumida del entorno local. No se muestran secretos.</p></div>';
  else if (path === '/hostnames') body = '<div class="page"><h1>Hostnames locales</h1><div class="cards"><div class="card"><h2>public.localhost</h2><p>Portal público</p></div><div class="card"><h2>admin.localhost</h2><p>Panel administrativo</p></div><div class="card"><h2>api.localhost</h2><p>API pública</p></div><div class="card"><h2>api-admin.localhost</h2><p>API administrativa</p></div></div></div>';
  else if (path === '/data') body = '<div class="page"><h1>Servicios de datos</h1><div class="cards"><div class="card"><h2>PostgreSQL</h2><p>Operación administrativa</p></div><div class="card"><h2>MongoDB</h2><p>Contenido público</p></div><div class="card"><h2>Redis</h2><p>Límites y estados auxiliares</p></div><div class="card"><h2>MinIO</h2><p>Medios y archivos</p></div></div></div>';
  else if (path === '/flow') body = '<div class="page"><h1>Recorrido de una petición pública</h1><div class="row"><div class="node">Navegador</div><div class="arrow">→</div><div class="node" style="background:#078b86">Traefik</div><div class="arrow">→</div><div class="node">Portal</div><div class="arrow">→</div><div class="node">public-api</div></div><p style="margin-top:90px">Validación → reglas de negocio → almacenamiento → respuesta al usuario</p></div>';
  else if (path === '/cloudflare') body = '<div class="page"><span class="pill">OPCIONAL</span><h1 style="margin-top:70px">Cloudflare Tunnel</h1><p>Acceso externo temporal y controlado mediante <b>cloudflared</b>.</p><div class="row"><div class="node">Internet</div><div class="arrow">→</div><div class="node" style="background:#e4a33a;color:#17252d">cloudflared</div><div class="arrow">→</div><div class="node" style="background:#078b86">Traefik</div></div><p class="small">Los tokens se mantienen como secretos locales y nunca se muestran.</p></div>';
  else if (path === '/closing') body = '<div class="page"><span class="pill">CAPÍTULO 1 · CIERRE</span><h1 style="margin-top:90px">Interfaces claras.<br>APIs con límites.<br>Datos por responsabilidad.</h1><p>Siguiente capítulo: levantar el entorno local y comprobar la salud de sus servicios.</p></div>';
  else { res.writeHead(404); res.end('Not found'); return; }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(pageMarkup(body));
});
await new Promise((resolveServer) => server.listen(8765, '127.0.0.1', resolveServer));

const urlById = {
  T1: 'http://127.0.0.1:8765/title', T2: 'http://public.localhost:8088', T3: 'http://127.0.0.1:8765/admin-dashboard-capture',
  T4: 'http://127.0.0.1:8765/diagram', T5: 'http://127.0.0.1:8765/terminal', T6: 'http://127.0.0.1:8765/hostnames',
  T7: 'http://127.0.0.1:8765/data', T8: 'http://127.0.0.1:8765/flow', T9: 'http://127.0.0.1:8765/cloudflare', T10: 'http://127.0.0.1:8765/closing'
};
const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
const durations = new Map();
for (const scene of narration.scenes) {
  const audioPath = resolve(audioDir, `${scene.id}.wav`);
  const duration = Number(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', audioPath], { encoding: 'utf8' }).trim());
  durations.set(scene.id, duration);
}
const obs = new OBSWebSocket();
await obs.connect('ws://127.0.0.1:4455', obsConfig.server_password);
await obs.call('SetVideoSettings', { baseWidth: 1920, baseHeight: 1080, outputWidth: 1920, outputHeight: 1080, fpsNumerator: 30, fpsDenominator: 1 });
const inputs = await obs.call('GetInputList');
for (const { inputName } of inputs.inputs) if (['Desktop Audio', 'Mic/Aux'].includes(inputName)) await obs.call('SetInputMute', { inputName, inputMuted: true });
const requestedScenes = process.env.CAPTURE_SCENES
  ? new Set(process.env.CAPTURE_SCENES.split(',').map(id => id.trim()).filter(Boolean))
  : null;
for (const scene of storyboard.scenes) {
  const id = scene.id;
  if (requestedScenes && !requestedScenes.has(id)) continue;
  const runId = `${Date.now()}-${id}`;
  const obsSceneName = `FerrePlus-${id}-${runId}`;
  const obsInputName = `Chapter-${id}-Browser-${runId}`;
  let sourceUrl = urlById[id];
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  if (id === 'T3') {
    const email = process.env.VIDEO_ADMIN_EMAIL;
    const password = process.env.VIDEO_ADMIN_PASSWORD;
    if (!email || !password) throw new Error('VIDEO_ADMIN_EMAIL and VIDEO_ADMIN_PASSWORD are required for real dashboard capture');
    await page.goto('http://admin.localhost:8088/auth', { waitUntil: 'networkidle', timeout: 30000 });
    await page.locator('input[formControlName="email"]').fill(email);
    await page.locator('input[formControlName="password"]').fill(password);
    await page.locator('button[type="submit"]').click();
    await page.waitForURL('**/dashboard', { timeout: 30000 });
    await page.waitForLoadState('networkidle');
    await sleep(2500);
    await page.screenshot({ path: resolve(captureDir, 'admin-dashboard-real.png'), fullPage: false });
  } else {
    await page.goto(sourceUrl, { waitUntil: 'networkidle', timeout: 30000 });
    await page.screenshot({ path: resolve(captureDir, `${id}.png`), fullPage: false });
  }
  await page.close();
  await obs.call('CreateScene', { sceneName: obsSceneName });
  await obs.call('CreateInput', { sceneName: obsSceneName, inputName: obsInputName, inputKind: 'browser_source', inputSettings: { url: sourceUrl, width: 1920, height: 1080, fps: 30, reroute_audio: false }, sceneItemEnabled: true });
  await obs.call('SetCurrentProgramScene', { sceneName: obsSceneName });
  await new Promise((resolveWait) => setTimeout(resolveWait, 1800));
  await obs.call('StartRecord');
  await new Promise((resolveWait) => setTimeout(resolveWait, Math.ceil((durations.get(id) + 1) * 1000)));
  const stopped = await obs.call('StopRecord');
  if (!stopped.outputPath) throw new Error(`OBS did not return output path for ${id}`);
  const stabilizedDuration = await waitForStableRecording(stopped.outputPath);
  const rawPath = resolve(rawDir, `${id}.mkv`);
  copyFileSync(stopped.outputPath, rawPath);
  const copiedDuration = await waitForStableRecording(rawPath);
  await obs.call('RemoveScene', { sceneName: obsSceneName });
  console.log(JSON.stringify({ id, sourcePath: stopped.outputPath, rawPath, expectedDurationSeconds: durations.get(id), stabilizedDuration, copiedDuration }));
}
await obs.disconnect();
await browser.close();
server.close();

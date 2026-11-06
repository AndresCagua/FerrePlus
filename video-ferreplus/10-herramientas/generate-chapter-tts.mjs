import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { join } from 'node:path';

const chapterRoot = new URL('../01-capitulo-01/', import.meta.url);
const inputPath = new URL('02-guion/narraciones-escenas.json', chapterRoot);
const outputDir = new URL('05-audio/voz/escenas/', chapterRoot);
const concatPath = new URL('05-audio/voz/escenas.txt', chapterRoot);
const finalPath = new URL('05-audio/voz/narracion-capitulo-01.wav', chapterRoot);
mkdirSync(outputDir, { recursive: true });
const { scenes } = JSON.parse(readFileSync(inputPath, 'utf8'));
const files = [];

for (const scene of scenes) {
  const outputPath = new URL(`${scene.id}.wav`, outputDir);
  const pcmPath = new URL(`${scene.id}.pcm`, outputDir);
  if (existsSync(outputPath)) {
    files.push(outputPath.pathname);
    console.log(`${scene.id}: already exists, reusing ${outputPath.pathname}`);
    continue;
  }
  const request = JSON.stringify({
    contents: [{ parts: [{ text: `Di exactamente este texto en español neutro internacional, sin voseo, jergas ni regionalismos, con voz clara y profesional: ${scene.text}` }] }],
    generationConfig: { responseModalities: ['AUDIO'], speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Kore' } } } }
  });
  let parsed;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    const response = execFileSync('docker', [
      'exec', '-i', 'ferreplus-admin-api', 'sh', '-c',
      'curl -sS -H "Content-Type: application/json" "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=$GEMINI_API_KEY" --data-binary @-'
    ], { input: request, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
    parsed = JSON.parse(response);
    if (!parsed?.error || parsed.error.code !== 429 || attempt === 3) break;
    const waitMs = 25000;
    console.log(`${scene.id}: Gemini quota response; waiting ${waitMs / 1000}s before retry ${attempt + 1}/3`);
    await new Promise((resolve) => setTimeout(resolve, waitMs));
  }
  const inline = parsed?.candidates?.[0]?.content?.parts?.[0]?.inlineData;
  if (!inline?.data) throw new Error(`Gemini TTS returned no audio for ${scene.id}: ${JSON.stringify(parsed).slice(0, 800)}`);
  writeFileSync(pcmPath, Buffer.from(inline.data, 'base64'));
  execFileSync('ffmpeg', ['-y', '-f', 's16le', '-ar', '24000', '-ac', '1', '-i', pcmPath.pathname, '-c:a', 'pcm_s16le', outputPath.pathname], { stdio: 'ignore' });
  unlinkSync(pcmPath);
  files.push(outputPath.pathname);
  console.log(`${scene.id}: ${outputPath.pathname}`);
  if (scene !== scenes.at(-1)) await new Promise((resolve) => setTimeout(resolve, 22000));
}

writeFileSync(concatPath, files.map((file) => `file '${file.replaceAll("'", "'\\''")}'`).join('\n') + '\n');
execFileSync('ffmpeg', ['-y', '-f', 'concat', '-safe', '0', '-i', concatPath.pathname, '-c:a', 'pcm_s16le', finalPath.pathname], { stdio: 'inherit' });
unlinkSync(concatPath);
console.log(finalPath.pathname);

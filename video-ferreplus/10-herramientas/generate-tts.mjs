import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { resolve } from 'node:path';
import { chapterArgument } from './video-args.mjs';

const { chapterRoot } = chapterArgument();
const inputPath = resolve(chapterRoot, '02-guion/narraciones-escenas.json');
const outputDir = resolve(chapterRoot, '05-audio/voz/escenas');
const concatPath = resolve(chapterRoot, '05-audio/voz/escenas.txt');
const finalPath = resolve(chapterRoot, '05-audio/voz/narracion.wav');
mkdirSync(outputDir, { recursive: true });
const { scenes } = JSON.parse(readFileSync(inputPath, 'utf8'));
const files = [];
const piperBin = process.env.PIPER_BIN ?? 'piper';
const piperModel = process.env.PIPER_MODEL;
const piperFallback = process.env.PIPER_FALLBACK !== 'false';
const edgeTtsBin = process.env.EDGE_TTS_BIN ?? 'edge-tts';
const edgeTtsVoice = process.env.EDGE_TTS_VOICE ?? 'es-MX-DaliaNeural';
const edgeTtsFallback = process.env.EDGE_TTS_FALLBACK === 'true';
let geminiUnavailable = false;
const generateWithPiper = (text, outputPath) => {
  if (!piperModel) throw new Error('PIPER_MODEL is required when Piper fallback is enabled');
  const piperPath = `${outputPath}.piper.wav`;
  execFileSync(piperBin, ['--model', piperModel, '--output_file', piperPath], { input: text, encoding: 'utf8', maxBuffer: 1024 * 1024 });
  execFileSync('ffmpeg', ['-y', '-i', piperPath, '-ar', '24000', '-ac', '1', '-c:a', 'pcm_s16le', outputPath], { stdio: 'ignore' });
  unlinkSync(piperPath);
};
const generateWithEdgeTts = (text, outputPath) => {
  const edgePath = `${outputPath}.edge.mp3`;
  execFileSync(edgeTtsBin, ['--voice', edgeTtsVoice, '--text', text, '--write-media', edgePath], { encoding: 'utf8', maxBuffer: 1024 * 1024 });
  execFileSync('ffmpeg', ['-y', '-i', edgePath, '-ar', '24000', '-ac', '1', '-c:a', 'pcm_s16le', outputPath], { stdio: 'ignore' });
  unlinkSync(edgePath);
};
const generateFallback = (text, outputPath) => {
  if (edgeTtsFallback) generateWithEdgeTts(text, outputPath);
  else generateWithPiper(text, outputPath);
};
const fallbackLabel = edgeTtsFallback ? 'Edge TTS' : 'Piper';

for (const scene of scenes) {
  const outputPath = resolve(outputDir, `${scene.id}.wav`);
  const pcmPath = resolve(outputDir, `${scene.id}.pcm`);
  if (existsSync(outputPath)) { files.push(outputPath); continue; }
  if (geminiUnavailable && (edgeTtsFallback || piperFallback)) {
    console.log(`${scene.id}: Gemini quota already exhausted; using ${fallbackLabel} fallback`);
    generateFallback(scene.text, outputPath);
    files.push(outputPath);
    continue;
  }
  const request = JSON.stringify({
    contents: [{ parts: [{ text: `Di exactamente este texto en español neutro internacional, sin voseo, jergas ni regionalismos, con voz clara y profesional: ${scene.text}` }] }],
    generationConfig: { responseModalities: ['AUDIO'], speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Kore' } } } }
  });
  let parsed;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    const response = execFileSync('docker', ['exec', '-i', 'ferreplus-admin-api', 'sh', '-c',
      'curl -sS -H "Content-Type: application/json" "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=$GEMINI_API_KEY" --data-binary @-'],
      { input: request, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
    parsed = JSON.parse(response);
    const status = Number(parsed?.error?.code ?? 0);
    if (!parsed?.error || status !== 429 || attempt === 3) break;
    if (edgeTtsFallback || piperFallback) {
      geminiUnavailable = true;
      break;
    }
    const waitMs = 25000;
    console.log(`${scene.id}: Gemini quota response; waiting ${waitMs / 1000}s before retry ${attempt + 1}/3`);
    await new Promise(resolveSleep => setTimeout(resolveSleep, waitMs));
  }
  const inline = parsed?.candidates?.[0]?.content?.parts?.[0]?.inlineData;
  if (!inline?.data) {
    const providerCode = parsed?.error?.code ?? 'unknown';
    const providerStatus = parsed?.error?.status ?? 'unknown';
    if (!edgeTtsFallback && !piperFallback) throw new Error(`Gemini TTS returned no audio for ${scene.id} (code=${providerCode}, status=${providerStatus})`);
    console.log(`${scene.id}: Gemini unavailable (code=${providerCode}, status=${providerStatus}); using ${fallbackLabel} fallback`);
    generateFallback(scene.text, outputPath);
    files.push(outputPath);
    continue;
  }
  writeFileSync(pcmPath, Buffer.from(inline.data, 'base64'));
  execFileSync('ffmpeg', ['-y', '-f', 's16le', '-ar', '24000', '-ac', '1', '-i', pcmPath, '-c:a', 'pcm_s16le', outputPath], { stdio: 'ignore' });
  unlinkSync(pcmPath);
  files.push(outputPath);
}
writeFileSync(concatPath, files.map(file => `file '${file.replaceAll("'", "'\\''")}'`).join('\n') + '\n');
execFileSync('ffmpeg', ['-y', '-f', 'concat', '-safe', '0', '-i', concatPath, '-c:a', 'pcm_s16le', finalPath], { stdio: 'inherit' });
unlinkSync(concatPath);
console.log(finalPath);

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

for (const scene of scenes) {
  const outputPath = resolve(outputDir, `${scene.id}.wav`);
  const pcmPath = resolve(outputDir, `${scene.id}.pcm`);
  if (existsSync(outputPath)) { files.push(outputPath); continue; }
  const request = JSON.stringify({
    contents: [{ parts: [{ text: `Di exactamente este texto en español neutro internacional, sin voseo, jergas ni regionalismos, con voz clara y profesional: ${scene.text}` }] }],
    generationConfig: { responseModalities: ['AUDIO'], speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Kore' } } } }
  });
  const response = execFileSync('docker', ['exec', '-i', 'ferreplus-admin-api', 'sh', '-c',
    'curl -sS -H "Content-Type: application/json" "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=$GEMINI_API_KEY" --data-binary @-'],
    { input: request, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  const inline = JSON.parse(response)?.candidates?.[0]?.content?.parts?.[0]?.inlineData;
  if (!inline?.data) throw new Error(`Gemini TTS returned no audio for ${scene.id}`);
  writeFileSync(pcmPath, Buffer.from(inline.data, 'base64'));
  execFileSync('ffmpeg', ['-y', '-f', 's16le', '-ar', '24000', '-ac', '1', '-i', pcmPath, '-c:a', 'pcm_s16le', outputPath], { stdio: 'ignore' });
  unlinkSync(pcmPath);
  files.push(outputPath);
}
writeFileSync(concatPath, files.map(file => `file '${file.replaceAll("'", "'\\''")}'`).join('\n') + '\n');
execFileSync('ffmpeg', ['-y', '-f', 'concat', '-safe', '0', '-i', concatPath, '-c:a', 'pcm_s16le', finalPath], { stdio: 'inherit' });
unlinkSync(concatPath);
console.log(finalPath);

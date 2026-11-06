import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { join } from 'node:path';

const root = new URL('../01-capitulo-01/', import.meta.url);
const narrationPath = new URL('02-guion/narracion-gemini.json', root);
const outputPath = new URL('05-audio/voz/narracion-gemini.wav', root);
const pcmPath = new URL('05-audio/voz/narracion-gemini.pcm', root);
const { narration } = JSON.parse(readFileSync(narrationPath, 'utf8'));
const request = JSON.stringify({
  contents: [{ parts: [{ text: `Di exactamente este texto en español neutro internacional, sin voseo, jergas ni regionalismos, con voz clara y profesional: ${narration}` }] }],
  generationConfig: {
    responseModalities: ['AUDIO'],
    speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Kore' } } }
  }
});
const response = execFileSync('docker', [
  'exec', '-i', 'ferreplus-admin-api', 'sh', '-c',
  'curl -sS -H "Content-Type: application/json" "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=$GEMINI_API_KEY" --data-binary @-'
], { input: request, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
const parsed = JSON.parse(response);
const inline = parsed?.candidates?.[0]?.content?.parts?.[0]?.inlineData;
if (!inline?.data) throw new Error(`Gemini TTS returned no audio: ${JSON.stringify(parsed).slice(0, 500)}`);
writeFileSync(pcmPath, Buffer.from(inline.data, 'base64'));
execFileSync('ffmpeg', ['-y', '-f', 's16le', '-ar', '24000', '-ac', '1', '-i', pcmPath.pathname, '-c:a', 'pcm_s16le', outputPath.pathname], { stdio: 'ignore' });
unlinkSync(pcmPath);
console.log(outputPath.pathname);

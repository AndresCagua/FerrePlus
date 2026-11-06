import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';

const storyboardPath = new URL('../01-capitulo-01/01-planificacion/storyboard.json', import.meta.url);
const outputPath = new URL('../01-capitulo-01/02-guion/narracion-gemini.json', import.meta.url);
const storyboard = JSON.parse(readFileSync(storyboardPath, 'utf8'));
const scene = storyboard.scenes[0];
const prompt = `Escribí una narración técnica breve en español neutro internacional, sin voseo, jergas ni regionalismos para una escena de 20 segundos sobre FerrePlus.\n\nContexto real:\n- La URL mostrada es ${scene.sourceUrl}.\n- FerrePlus tiene portal público, panel administrativo, APIs y servicios Docker.\n- No inventes funcionalidades que no estén en ese contexto.\n- Devolvé únicamente JSON válido con esta forma: {"narration":"..."}.\n- La narración debe durar aproximadamente 18 a 20 segundos al leerla en voz clara.`;
const request = JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] });
const response = execFileSync('docker', [
  'exec', '-i', 'ferreplus-admin-api', 'sh', '-c',
  'curl -sS -H "Content-Type: application/json" "https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_CHAT_MODEL:-gemini-3.6-flash}:generateContent?key=$GEMINI_API_KEY" --data-binary @-'
], { input: request, encoding: 'utf8' });
const parsed = JSON.parse(response);
const text = parsed?.candidates?.[0]?.content?.parts?.[0]?.text;
if (!text) throw new Error(`Gemini returned no text: ${JSON.stringify(parsed).slice(0, 1000)}`);
const clean = text.replace(/^```json\s*/i, '').replace(/\s*```$/i, '').trim();
const narration = JSON.parse(clean);
writeFileSync(outputPath, `${JSON.stringify({ provider: 'Google Gemini', model: process.env.GEMINI_CHAT_MODEL ?? 'gemini-3.6-flash', ...narration }, null, 2)}\n`);
console.log(outputPath.pathname);

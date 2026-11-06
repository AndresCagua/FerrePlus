import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { resolve } from 'node:path';
import { chapterArgument } from './video-args.mjs';

const { chapterRoot } = chapterArgument();
const rawDir = resolve(chapterRoot, '04-grabaciones/bruto');
const audioDir = resolve(chapterRoot, '05-audio/voz');
const editDir = resolve(chapterRoot, '07-edicion');
const normalizedDir = resolve(editDir, 'escenas-normalizadas');
const subtitleDir = resolve(chapterRoot, '06-subtitulos');
const exportDir = resolve(chapterRoot, '08-exportados');
mkdirSync(editDir, { recursive: true });
mkdirSync(normalizedDir, { recursive: true });
mkdirSync(subtitleDir, { recursive: true });
mkdirSync(exportDir, { recursive: true });

const scenes = JSON.parse(readFileSync(resolve(chapterRoot, '02-guion/narraciones-escenas.json'), 'utf8')).scenes;
const narrationPath = resolve(audioDir, 'narracion.wav');
const outputPath = resolve(exportDir, `${chapterRoot.split('/').pop()}.mp4`);
const concatPath = resolve(editDir, 'scenes.txt');
const joinedPath = resolve(editDir, 'scenes.mkv');
const subtitlePath = resolve(subtitleDir, 'narracion.srt');
const narrationDuration = Number(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', narrationPath], { encoding: 'utf8' }).trim());
const stamp = seconds => { const ms = Math.round(seconds * 1000); return `${String(Math.floor(ms / 3600000)).padStart(2, '0')}:${String(Math.floor(ms / 60000) % 60).padStart(2, '0')}:${String(Math.floor(ms / 1000) % 60).padStart(2, '0')},${String(ms % 1000).padStart(3, '0')}`; };
const chunks = text => text.match(/[^.!?]+[.!?]+|[^.!?]+$/g)?.flatMap(sentence => { const words = sentence.trim().split(/\s+/); const result = []; let current = ''; for (const word of words) { const candidate = current ? `${current} ${word}` : word; if (candidate.length > 56 && current) { result.push(current); current = word; } else current = candidate; } if (current) result.push(current); return result; }) ?? [text];

const concat = [];
const subtitles = [];
let offset = 0;
for (const scene of scenes) {
  const rawVideo = resolve(rawDir, `${scene.id}.mkv`);
  const audio = resolve(audioDir, 'escenas', `${scene.id}.wav`);
  const duration = Number(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', audio], { encoding: 'utf8' }).trim());
  const normalizedVideo = resolve(normalizedDir, `${scene.id}.mkv`);
  // OBS scenes are intentionally longer than their narration; normalize each one
  // before concatenation so visuals and speech change at the same timestamps.
  execFileSync('ffmpeg', ['-y', '-i', rawVideo, '-t', duration.toFixed(6), '-an', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '18', '-pix_fmt', 'yuv420p', normalizedVideo], { stdio: 'ignore' });
  concat.push(`file '${normalizedVideo.replaceAll("'", "'\\''")}'`);
  const parts = chunks(scene.text);
  const total = parts.reduce((sum, part) => sum + part.length, 0) || 1;
  let localOffset = 0;
  for (const part of parts) {
    const partDuration = duration * (part.length / total);
    subtitles.push(`${subtitles.length + 1}\n${stamp(offset + localOffset)} --> ${stamp(offset + localOffset + partDuration)}\n${part}\n`);
    localOffset += partDuration;
  }
  offset += duration;
}
writeFileSync(concatPath, `${concat.join('\n')}\n`);
writeFileSync(subtitlePath, subtitles.join('\n'));
execFileSync('ffmpeg', ['-y', '-f', 'concat', '-safe', '0', '-i', concatPath, '-c', 'copy', joinedPath], { stdio: 'inherit' });
execFileSync('ffmpeg', ['-y', '-i', joinedPath, '-i', narrationPath, '-i', subtitlePath, '-map', '0:v:0', '-map', '1:a:0', '-map', '2:0', '-c:v', 'copy', '-c:a', 'aac', '-ar', '24000', '-ac', '1', '-c:s', 'mov_text', '-metadata:s:s:0', 'language=spa', '-t', narrationDuration.toFixed(6), '-movflags', '+faststart', outputPath], { stdio: 'inherit' });
unlinkSync(concatPath);
unlinkSync(joinedPath);
console.log(outputPath);

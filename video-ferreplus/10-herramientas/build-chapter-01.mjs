import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { resolve } from 'node:path';

const toolsDir = resolve(new URL('.', import.meta.url).pathname);
const projectRoot = resolve(toolsDir, '..');
const chapterRoot = resolve(projectRoot, '01-capitulo-01');
const rawDir = resolve(chapterRoot, '04-grabaciones/bruto');
const audioDir = resolve(chapterRoot, '05-audio/voz');
const subtitleDir = resolve(chapterRoot, '06-subtitulos');
const editDir = resolve(chapterRoot, '07-edicion');
const exportDir = resolve(chapterRoot, '08-exportados');
mkdirSync(editDir, { recursive: true });
mkdirSync(exportDir, { recursive: true });
mkdirSync(subtitleDir, { recursive: true });
const scenes = JSON.parse(readFileSync(resolve(chapterRoot, '02-guion/narraciones-escenas.json'), 'utf8')).scenes;
const concatPath = resolve(editDir, 'chapter-scenes.txt');
const joinedPath = resolve(editDir, 'capitulo-01-escenas.mkv');
const subtitlePath = resolve(subtitleDir, 'narracion-capitulo-01.srt');
const outputPath = resolve(exportDir, 'capitulo-01-ferreplus.mp4');
const narrationPath = resolve(audioDir, 'narracion-capitulo-01.wav');
const narrationDuration = Number(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', narrationPath], { encoding: 'utf8' }).trim());

const concatLines = [];
const subtitleBlocks = [];
let offset = 0;
const toTimestamp = (seconds) => {
  const millis = Math.round(seconds * 1000);
  const h = Math.floor(millis / 3600000);
  const m = Math.floor((millis % 3600000) / 60000);
  const s = Math.floor((millis % 60000) / 1000);
  const ms = millis % 1000;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')},${String(ms).padStart(3, '0')}`;
};
const subtitleSegments = (text, duration) => {
  const sentences = text.match(/[^.!?]+[.!?]+|[^.!?]+$/g)?.map(segment => segment.trim()).filter(Boolean) ?? [text];
  const chunks = [];
  for (const sentence of sentences) {
    if (sentence.length <= 56) {
      chunks.push(sentence);
      continue;
    }
    const words = sentence.split(/\s+/);
    let current = '';
    for (const word of words) {
      const candidate = current ? `${current} ${word}` : word;
      if (candidate.length > 56 && current) {
        chunks.push(current);
        current = word;
      } else {
        current = candidate;
      }
    }
    if (current) chunks.push(current);
  }
  const totalCharacters = chunks.reduce((sum, chunk) => sum + chunk.length, 0) || 1;
  let segmentOffset = 0;
  return chunks.map((text) => {
    const segmentDuration = duration * (text.length / totalCharacters);
    const segment = { text, start: segmentOffset, end: segmentOffset + segmentDuration };
    segmentOffset += segmentDuration;
    return segment;
  });
};
for (const scene of scenes) {
  const scenePath = resolve(rawDir, `${scene.id}.mkv`);
  const audioPath = resolve(audioDir, 'escenas', `${scene.id}.wav`);
  concatLines.push(`file '${scenePath.replaceAll("'", "'\\''")}'`);
  const duration = Number(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', audioPath], { encoding: 'utf8' }).trim());
  for (const segment of subtitleSegments(scene.text, duration)) {
    subtitleBlocks.push(`${subtitleBlocks.length + 1}\n${toTimestamp(offset + segment.start)} --> ${toTimestamp(offset + segment.end)}\n${segment.text}\n`);
  }
  offset += duration;
}
writeFileSync(concatPath, concatLines.join('\n') + '\n');
writeFileSync(subtitlePath, subtitleBlocks.join('\n'));
execFileSync('ffmpeg', ['-y', '-f', 'concat', '-safe', '0', '-i', concatPath, '-c', 'copy', joinedPath], { stdio: 'inherit' });
execFileSync('ffmpeg', ['-y', '-i', joinedPath, '-i', narrationPath, '-i', subtitlePath, '-map', '0:v:0', '-map', '1:a:0', '-map', '2:0', '-c:v', 'copy', '-c:a', 'aac', '-ar', '24000', '-ac', '1', '-c:s', 'mov_text', '-metadata:s:s:0', 'language=spa', '-metadata:s:s:0', 'title=Español', '-t', narrationDuration.toFixed(6), '-movflags', '+faststart', outputPath], { stdio: 'inherit' });
unlinkSync(concatPath);
unlinkSync(joinedPath);
console.log(outputPath);

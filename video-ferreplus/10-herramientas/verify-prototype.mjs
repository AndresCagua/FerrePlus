import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolsDir = dirname(fileURLToPath(import.meta.url));
const chapterRoot = resolve(toolsDir, '../01-capitulo-01');
const output = resolve(chapterRoot, '08-exportados/capitulo-01-prototipo.mp4');
const screenshot = resolve(chapterRoot, '04-grabaciones/capturas/portal-publico.png');
const subtitles = resolve(chapterRoot, '06-subtitulos/narracion-gemini.srt');
for (const path of [output, screenshot, subtitles]) {
  if (!existsSync(path)) throw new Error(`Missing artifact: ${path}`);
}
const probe = execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration:stream=codec_type,codec_name,width,height,sample_rate,channels,duration:stream_tags=language', '-of', 'json', output], { encoding: 'utf8' });
const metadata = JSON.parse(probe);
const duration = Number(metadata.format?.duration ?? 0);
const streams = metadata.streams ?? [];
const types = new Set(streams.map((stream) => stream.codec_type));
const videoDuration = Number(streams.find((stream) => stream.codec_type === 'video')?.duration ?? 0);
const audioDuration = Number(streams.find((stream) => stream.codec_type === 'audio')?.duration ?? 0);
if (duration < 5) throw new Error(`Video is too short: ${duration}s`);
if (videoDuration < 18 || audioDuration < 18) throw new Error(`Audio/video streams are too short: video=${videoDuration}s audio=${audioDuration}s`);
if (Math.abs(videoDuration - audioDuration) > 1.5) throw new Error(`Audio/video drift is too large: video=${videoDuration}s audio=${audioDuration}s`);
if (!types.has('video') || !types.has('audio')) throw new Error('Final video must contain video and audio streams');
const subtitleText = readFileSync(subtitles, 'utf8');
if (!subtitleText.includes('FerrePlus')) throw new Error('Subtitles do not mention FerrePlus');
console.log(JSON.stringify({ output, durationSeconds: duration, videoDurationSeconds: videoDuration, audioDurationSeconds: audioDuration, streams: [...types], screenshot, subtitles }, null, 2));

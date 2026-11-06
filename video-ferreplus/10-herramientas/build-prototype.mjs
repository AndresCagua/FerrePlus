import { execFileSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const toolsDir = dirname(fileURLToPath(import.meta.url));
const chapterRoot = resolve(toolsDir, '../01-capitulo-01');
const raw = resolve(chapterRoot, '04-grabaciones/bruto/portal-publico.mkv');
const audio = resolve(chapterRoot, '05-audio/voz/narracion-gemini.wav');
const subtitles = resolve(chapterRoot, '06-subtitulos/narracion-gemini.srt');
const editDir = resolve(chapterRoot, '07-edicion');
const exportDir = resolve(chapterRoot, '08-exportados');
mkdirSync(editDir, { recursive: true });
mkdirSync(exportDir, { recursive: true });
const intermediate = resolve(editDir, 'capitulo-01-sin-subtitulos.mp4');
const output = resolve(exportDir, 'capitulo-01-prototipo.mp4');
execFileSync('ffmpeg', ['-y', '-fflags', '+genpts', '-err_detect', 'ignore_err', '-i', raw, '-i', audio, '-map', '0:v:0', '-map', '1:a:0', '-vf', 'scale=1920:1080', '-c:v', 'libx264', '-preset', 'veryfast', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '128k', '-shortest', '-movflags', '+faststart', intermediate], { stdio: 'inherit' });
execFileSync('ffmpeg', ['-y', '-i', intermediate, '-i', subtitles, '-map', '0:v:0', '-map', '0:a:0', '-map', '1:0', '-c:v', 'copy', '-c:a', 'copy', '-c:s', 'mov_text', '-metadata:s:s:0', 'language=spa', '-movflags', '+faststart', output], { stdio: 'inherit' });
console.log(output);

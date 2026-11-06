import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function chapterArgument(defaultChapter = process.env.VIDEO_CHAPTER) {
  const index = process.argv.indexOf('--chapter');
  const value = index >= 0 ? process.argv[index + 1] : defaultChapter;
  if (!value) throw new Error('Missing --chapter <directory>, e.g. 02-capitulo-03');
  const toolsDir = resolve(fileURLToPath(new URL('.', import.meta.url)));
  const projectRoot = resolve(toolsDir, '..');
  return { projectRoot, chapterRoot: resolve(projectRoot, value), chapterName: value };
}

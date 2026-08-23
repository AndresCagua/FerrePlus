import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(new URL('..', import.meta.url).pathname);
const css = await readFile(resolve(root, 'src/styles/global.css'), 'utf8');
const page = await readFile(resolve(root, 'src/pages/publicaciones/[slug].astro'), 'utf8');

const checks = [
  ['columna editorial aislada', /\.publication-article[^\{]*\{[^}]*max-width:720px/s],
  ['contenido editorial responsive', /\.publication-article[^\{]*\{[^}]*width:min\(calc\(100% - 2rem\),720px\)/s],
  ['imagenes sin overflow', /\.publication-article img[^\{]*\{[^}]*max-width:100%/s],
  ['YouTube 16:9', /\.publication-video[^\{]*\{[^}]*aspect-ratio:16 \/ 9/s],
  ['YouTube limitado al contenedor', /\.publication-video iframe[^\{]*\{[^}]*max-width:100%/s],
  ['X centrado', /\.x-preview[^\{]*\{[^}]*justify-content:center/s],
  ['URL de X sin overflow', /\.x-preview-url[^\{]*\{[^}]*overflow-wrap:anywhere/s],
  ['reduced motion', /prefers-reduced-motion:reduce/],
  ['borradores excluidos por listado publico', /publicApi\.publicaciones\(\)/],
  ['pagina editorial aislada', /publication-article/],
];

const failed = checks.flatMap(([name, pattern]) => {
  const valid = Array.isArray(pattern) ? pattern.every(candidate => candidate.test(css)) : pattern.test(name.includes('borradores') || name.includes('pagina') ? page : css);
  return valid ? [] : [name];
});

if (failed.length) {
  console.error(`Editorial checks failed: ${failed.join(', ')}`);
  process.exitCode = 1;
} else {
  console.log(`Editorial static checks passed (${checks.length})`);
}

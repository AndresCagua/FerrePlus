import { publicApi } from '../../lib/api-client/public-api';
import type { Convocatoria, Publicacion } from '../../lib/api-client/types';
import { createXIcon, enhanceXEmbeds, parseXLink, parseYouTubeLink } from '../link-previews';

const date = (value?: string, prefix = '') => value ? `${prefix}${new Date(value).toLocaleDateString('es-CO')}` : '';

function element<T extends HTMLElement>(selector: string): T | null {
  return document.querySelector<T>(selector);
}

function setState(container: HTMLElement, message: string, className: string): void {
  container.replaceChildren();
  const state = document.createElement('div');
  state.className = className;
  state.dataset.contentState = className === 'notice' ? 'error' : className;
  state.dataset.stateOrigin = 'runtime';
  state.setAttribute('role', className === 'notice' ? 'alert' : 'status');
  state.setAttribute('aria-live', className === 'notice' ? 'assertive' : 'polite');
  state.textContent = message;
  container.append(state);
}

function card(href: string, title: string, summary: string | undefined, eyebrow: string, publishedDate: string): HTMLElement {
  const article = document.createElement('article');
  article.className = 'card';
  article.innerHTML = `<div class="tag"></div><h2><a></a></h2><p></p><div class="date"></div><p><a class="button secondary" data-more></a></p>`;
  const titleLink = article.querySelector('h2 a') as HTMLAnchorElement;
  titleLink.href = href;
  titleLink.textContent = title;
  (article.querySelector('.tag') as HTMLElement).textContent = eyebrow;
  (article.querySelector('p') as HTMLElement).textContent = summary ?? '';
  (article.querySelector('.date') as HTMLElement).textContent = publishedDate;
  const more = article.querySelector('[data-more]') as HTMLAnchorElement;
  more.href = href;
  more.textContent = 'Conocer mas';
  return article;
}

export async function setupPublicacionesList(): Promise<void> {
  const container = element<HTMLElement>('[data-publicaciones-list]');
  if (!container) return;
  try {
    const items = await publicApi.publicaciones();
    container.replaceChildren(...items.map((item) => card(`/publicaciones/detail/?slug=${encodeURIComponent(item.slug)}`, item.titulo, item.resumen ?? item.descripcion, item.categoria ?? 'Publicacion', date(item.fechaPublicacion))));
    if (!items.length) setState(container, 'Todavia no hay publicaciones disponibles.', 'empty');
  } catch {
    setState(container, 'No podemos consultar las publicaciones ahora. Vuelve a intentarlo pronto.', 'notice');
  }
}

function updateMeta(title: string, description: string): void {
  document.title = title;
  const meta = document.querySelector<HTMLMetaElement>('meta[name="description"]');
  if (meta) meta.content = description;
}

function renderPublication(item: Publicacion): void {
  const title = item.metadataSEO?.title ?? item.titulo;
  const description = item.metadataSEO?.description ?? item.resumen ?? 'Publicacion de Ferreplus.';
  updateMeta(title, description);
  const content = element<HTMLElement>('[data-publicacion-detail]');
  if (!content) return;
  content.replaceChildren();
  const eyebrow = document.createElement('div'); eyebrow.className = 'eyebrow'; content.append(eyebrow);
  const heading = document.createElement('h1'); content.append(heading);
  const published = document.createElement('div'); published.className = 'date'; content.append(published);
  const lede = document.createElement('p'); lede.className = 'lede'; content.append(lede);
  const article = document.createElement('div'); article.className = 'article-content'; content.append(article);
  eyebrow.textContent = item.categoria ?? 'Publicacion'; heading.textContent = item.titulo;
  published.textContent = date(item.fechaPublicacion); lede.textContent = item.resumen ?? ''; article.textContent = item.descripcion ?? '';
  if (item.portada?.url) { const image = document.createElement('img'); image.src = item.portada.url; image.alt = item.portada.alt ?? item.titulo; image.loading = 'lazy'; content.append(image); }
  if (item.galeria?.length) { const gallery = document.createElement('div'); gallery.className = 'gallery'; item.galeria.forEach(media => { if (!media.url) return; const image = document.createElement('img'); image.src = media.url; image.alt = media.alt ?? item.titulo; image.loading = 'lazy'; gallery.append(image); }); content.append(gallery); }
  const video = parseYouTubeLink(item.videoUrl);
  if (video) {
    const preview = document.createElement('article'); preview.className = 'link-preview youtube-preview';
    const image = document.createElement('img'); image.src = video.thumbnail; image.alt = `Vista previa del video: ${item.titulo}`; image.loading = 'lazy'; preview.append(image);
    const body = document.createElement('div'); body.className = 'link-preview-body';
    const label = document.createElement('span'); label.className = 'tag'; label.textContent = 'YouTube'; body.append(label);
    const link = document.createElement('a'); link.href = video.href; link.rel = 'noopener noreferrer'; link.target = '_blank'; link.textContent = 'Ver video relacionado'; body.append(link);
    preview.append(body); content.append(preview);
  }
  const social = document.createElement('div'); social.className = 'social-previews';
  for (const value of item.enlacesX ?? []) {
    const x = parseXLink(value); if (!x) continue;
    const preview = document.createElement('article'); preview.className = 'link-preview x-preview'; preview.dataset.xPreview = 'true';
    if (x.statusId) {
      const embed = document.createElement('blockquote'); embed.className = 'twitter-tweet x-embed'; embed.dataset.xEmbed = x.statusId; embed.dataset.dnt = 'true';
      const embedText = document.createElement('p'); embedText.lang = 'es'; embedText.dir = 'ltr'; embedText.textContent = 'Ver esta publicacion en X.'; embed.append(embedText);
      const embedLink = document.createElement('a'); embedLink.href = x.href; embedLink.textContent = x.displayUrl; embedLink.rel = 'noopener noreferrer'; embedLink.target = '_blank'; embed.append(embedLink);
      preview.append(embed);
    }
    const fallback = document.createElement('div'); fallback.className = 'x-preview-fallback';
    const icon = document.createElement('span'); icon.className = 'x-preview-icon'; icon.append(createXIcon()); fallback.append(icon);
    const body = document.createElement('div'); body.className = 'x-preview-body';
    const label = document.createElement('span'); label.className = 'x-preview-network'; label.textContent = 'X'; body.append(label);
    const source = document.createElement('span'); source.className = 'x-preview-source'; source.textContent = x.statusId ? 'Publicacion de X' : 'Enlace de X'; body.append(source);
    const link = document.createElement('a');
    link.className = 'x-preview-link'; link.href = x.href; link.rel = 'noopener noreferrer'; link.target = '_blank';
    link.ariaLabel = `Abrir enlace de X en una pestana nueva: ${x.displayUrl}`;
    const url = document.createElement('span'); url.className = 'x-preview-url'; url.textContent = x.displayUrl; url.title = x.href; link.append(url);
    const external = document.createElement('span'); external.className = 'x-preview-external'; external.setAttribute('aria-hidden', 'true'); external.textContent = '->'; link.append(external);
    body.append(link);
    if (x.statusId) { const note = document.createElement('span'); note.className = 'x-preview-note'; note.textContent = 'Si X no permite la vista previa, abre la publicacion original.'; body.append(note); }
    fallback.append(body); preview.append(fallback);
    social.append(preview);
  }
  if (social.childElementCount) { content.append(social); enhanceXEmbeds(content); }
}

export async function setupPublicacionDetail(): Promise<void> {
  const slug = new URLSearchParams(location.search).get('slug') ?? decodeURIComponent(location.pathname.split('/').filter(Boolean).pop() ?? '');
  const content = element<HTMLElement>('[data-publicacion-detail]');
  if (!content || !slug || slug === 'detail') return;
  try { renderPublication(await publicApi.publicacion(slug)); }
  catch { setState(content, 'La publicacion no esta disponible.', 'empty'); }
}

function renderConvocatoria(item: Convocatoria): void {
  updateMeta(item.titulo, item.descripcion);
  const content = element<HTMLElement>('[data-convocatoria-detail]');
  if (!content) return;
  content.innerHTML = `<div class="eyebrow"></div><h1></h1><p class="lede"></p><p><strong>Ubicacion:</strong> <span data-location></span></p><h2>Requisitos</h2><ul data-requirements></ul>`;
  (content.querySelector('.eyebrow') as HTMLElement).textContent = item.modalidad ?? 'Convocatoria abierta';
  (content.querySelector('h1') as HTMLElement).textContent = item.titulo;
  (content.querySelector('.lede') as HTMLElement).textContent = item.descripcion;
  (content.querySelector('[data-location]') as HTMLElement).textContent = item.ubicacion ?? 'Por definir';
  const requirements = content.querySelector('[data-requirements]') as HTMLUListElement;
  for (const requirement of item.requisitos ?? []) {
    const li = document.createElement('li'); li.textContent = requirement; requirements.append(li);
  }
  const form = element<HTMLFormElement>('form[data-convocatoria-id]');
  if (form) form.dataset.convocatoriaId = item.id;
}

export async function setupConvocatoriasList(): Promise<void> {
  const container = element<HTMLElement>('[data-convocatorias-list]');
  if (!container) return;
  try {
    const items = await publicApi.convocatorias();
    container.replaceChildren(...items.map((item) => card(`/convocatorias/${item.id}/`, item.titulo, item.descripcion, item.modalidad ?? 'Oportunidad', date(item.fechaCierre, 'Cierra '))));
    if (!items.length) setState(container, 'No hay convocatorias abiertas en este momento.', 'empty');
  } catch {
    setState(container, 'No podemos consultar las oportunidades ahora. Vuelve a intentarlo pronto.', 'notice');
  }
}

export async function setupConvocatoriaDetail(): Promise<void> {
  const id = decodeURIComponent(location.pathname.split('/').filter(Boolean).pop() ?? '');
  const content = element<HTMLElement>('[data-convocatoria-detail]');
  if (!content || !id || id === 'detail') return;
  try { renderConvocatoria(await publicApi.convocatoria(id)); }
  catch { setState(content, 'La convocatoria no esta disponible o ya fue cerrada.', 'empty'); }
}

import { publicApi } from '../../lib/api-client/public-api';
import type { Convocatoria, Publicacion } from '../../lib/api-client/types';

const date = (value?: string, prefix = '') => value ? `${prefix}${new Date(value).toLocaleDateString('es-CO')}` : '';

function element<T extends HTMLElement>(selector: string): T | null {
  return document.querySelector<T>(selector);
}

function setState(container: HTMLElement, message: string, className: string): void {
  container.replaceChildren();
  const state = document.createElement('div');
  state.className = className;
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
    container.replaceChildren(...items.map((item) => card(`/publicaciones/${item.slug}/`, item.titulo, item.resumen ?? item.descripcion, item.categoria ?? 'Publicacion', date(item.fechaPublicacion))));
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
  content.innerHTML = `<div class="eyebrow"></div><h1></h1><div class="date"></div><p class="lede"></p><div class="article-content"></div>`;
  (content.querySelector('.eyebrow') as HTMLElement).textContent = item.categoria ?? 'Publicacion';
  (content.querySelector('h1') as HTMLElement).textContent = item.titulo;
  (content.querySelector('.date') as HTMLElement).textContent = date(item.fechaPublicacion);
  (content.querySelector('.lede') as HTMLElement).textContent = item.resumen ?? '';
  (content.querySelector('.article-content') as HTMLElement).textContent = item.descripcion ?? '';
  if (item.videoUrl) {
    const link = document.createElement('p');
    link.innerHTML = '<a rel="noreferrer">Ver video relacionado →</a>';
    (link.firstElementChild as HTMLAnchorElement).href = item.videoUrl;
    content.append(link);
  }
}

export async function setupPublicacionDetail(): Promise<void> {
  const slug = decodeURIComponent(location.pathname.split('/').filter(Boolean).pop() ?? '');
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

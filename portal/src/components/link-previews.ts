const youtubeHosts = new Set(['youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be']);
const xHosts = new Set(['x.com', 'www.x.com', 'twitter.com', 'www.twitter.com']);

export interface YouTubeLink {
  href: string;
  id: string;
  thumbnail: string;
  embed: string;
}

export interface XLink {
  href: string;
  statusId?: string;
  displayUrl: string;
}

function parseHttpsUrl(value: string | undefined, hosts: Set<string>): URL | null {
  try {
    const url = new URL(value ?? '');
    const hostname = url.hostname.toLowerCase();
    const allowed = [...hosts].some((host) => hostname === host || hostname.endsWith(`.${host}`));
    return url.protocol === 'https:' && allowed ? url : null;
  } catch {
    return null;
  }
}

export function parseYouTubeLink(value: string | undefined): YouTubeLink | null {
  const url = parseHttpsUrl(value, youtubeHosts);
  if (!url) return null;

  let id = '';
  if (url.hostname === 'youtu.be') {
    id = url.pathname.slice(1).split('/')[0];
  } else if (url.pathname === '/watch') {
    id = url.searchParams.get('v') ?? '';
  } else if (/^\/(shorts|embed)\//.test(url.pathname)) {
    id = url.pathname.split('/')[2] ?? '';
  }

  if (!/^[A-Za-z0-9_-]{11}$/.test(id)) return null;
  return {
    href: url.href,
    id,
    thumbnail: `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
    embed: `https://www.youtube-nocookie.com/embed/${id}`,
  };
}

export function parseXLink(value: string | undefined): XLink | null {
  const url = parseHttpsUrl(value, xHosts);
  if (!url) return null;
  const status = url.pathname.match(/^\/[^/]+\/status\/([0-9]+)\/?$/i);
  const path = `${url.pathname.replace(/\/$/, '')}${url.search}`;
  const displayUrl = `${url.hostname.replace(/^www\./, '')}${path}`;
  return {
    href: url.href,
    statusId: status?.[1],
    displayUrl: displayUrl.length > 72 ? `${displayUrl.slice(0, 69)}...` : displayUrl,
  };
}

export function createXIcon(): SVGElement {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('aria-hidden', 'true');
  svg.setAttribute('focusable', 'false');
  const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  path.setAttribute('d', 'M18.9 2H22l-6.77 7.74L23.2 22h-6.28l-4.92-6.43L6.38 22H3.27l7.24-8.28L2.8 2h6.44l4.45 5.88L18.9 2Zm-1.1 17.86h1.74L8.29 4.03H6.42L17.8 19.86Z');
  svg.append(path);
  return svg;
}

let widgetsPromise: Promise<void> | undefined;

function loadXWidgets(): Promise<void> {
  if (widgetsPromise) return widgetsPromise;
  widgetsPromise = new Promise((resolve) => {
    if ((window as Window & { twttr?: unknown }).twttr) { resolve(); return; }
    const existing = document.querySelector<HTMLScriptElement>('script[data-x-widgets]');
    if (existing) {
      existing.addEventListener('load', () => resolve(), { once: true });
      existing.addEventListener('error', () => resolve(), { once: true });
      return;
    }
    const script = document.createElement('script');
    script.src = 'https://platform.twitter.com/widgets.js';
    script.async = true;
    script.dataset.xWidgets = 'true';
    script.onload = () => resolve();
    script.onerror = () => resolve();
    document.head.append(script);
  });
  return widgetsPromise;
}

export function enhanceXEmbeds(container: HTMLElement): void {
  const embeds = container.querySelectorAll<HTMLElement>('[data-x-embed]');
  if (!embeds.length) return;
  const observers = [...embeds].map((embed) => {
    const wrapper = embed.closest<HTMLElement>('[data-x-preview]');
    if (!wrapper) return null;
    const revealEmbed = () => {
      if (wrapper.querySelector('iframe')) {
        wrapper.classList.add('is-embedded');
        return true;
      }
      return false;
    };
    if (revealEmbed()) return null;
    const observer = new MutationObserver(() => {
      if (revealEmbed()) observer.disconnect();
    });
    observer.observe(wrapper, { childList: true, subtree: true });
    window.setTimeout(() => observer.disconnect(), 10000);
    return observer;
  });
  void loadXWidgets().then(() => {
    const widgets = (window as Window & { twttr?: { widgets?: { load: (element?: HTMLElement) => void } } }).twttr;
    widgets?.widgets?.load(container);
    if (!widgets?.widgets?.load) observers.forEach((observer) => observer?.disconnect());
  });
}

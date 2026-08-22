/// <reference types="astro/client" />

interface ImportMetaEnv {
  readonly PUBLIC_API_URL?: string;
  readonly PUBLIC_SITE_URL?: string;
  readonly PUBLIC_TURNSTILE_SITE_KEY?: string;
  readonly PUBLIC_CAPTCHA_ENABLED?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
interface Window {
  turnstile?: { render: (element: Element, options: Record<string, unknown>) => string | number; reset: (widgetId?: string | number) => void };
}

import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

const site = process.env.PUBLIC_SITE_URL ?? 'http://public.localhost';

export default defineConfig({
  output: 'static',
  site,
  integrations: [sitemap()],
  prefetch: true,
  build: { format: 'directory' },
});

FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ARG PUBLIC_SITE_URL=http://public.localhost
ARG PUBLIC_API_URL=
ARG PUBLIC_TURNSTILE_SITE_KEY=
ARG PUBLIC_CAPTCHA_ENABLED=false
ENV PUBLIC_SITE_URL=$PUBLIC_SITE_URL PUBLIC_API_URL=$PUBLIC_API_URL PUBLIC_TURNSTILE_SITE_KEY=$PUBLIC_TURNSTILE_SITE_KEY PUBLIC_CAPTCHA_ENABLED=$PUBLIC_CAPTCHA_ENABLED
RUN npm run build

FROM nginx:1.27-alpine
RUN addgroup -S app && adduser -S -G app -u 10001 app \
    && mkdir -p /var/cache/nginx /tmp/nginx \
    && chown -R app:app /var/cache/nginx /tmp/nginx /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html
RUN printf 'ok\n' > /usr/share/nginx/html/health && chown -R app:app /usr/share/nginx/html
USER app
HEALTHCHECK --interval=15s --timeout=3s --retries=5 CMD wget --spider -q http://localhost:8080/health || exit 1
EXPOSE 8080

FROM node:22-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration production

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app/dist/ferreplus-frontend/browser /usr/share/nginx/html
RUN addgroup -S app && adduser -S -G app -u 10001 app \
    && mkdir -p /var/cache/nginx /tmp/nginx \
    && printf 'ok\n' > /usr/share/nginx/html/health \
    && chown -R app:app /var/cache/nginx /tmp/nginx /usr/share/nginx/html
USER app
EXPOSE 8080

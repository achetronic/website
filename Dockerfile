# syntax=docker/dockerfile:1.7

# ---- build stage -------------------------------------------------------------
ARG HUGO_VERSION=0.155.3

FROM --platform=$BUILDPLATFORM alpine:3.20 AS build

ARG HUGO_VERSION
ARG TARGETARCH

RUN apk add --no-cache curl ca-certificates git \
    && case "${TARGETARCH}" in \
         "amd64") HUGO_ARCH="64bit" ;; \
         "arm64") HUGO_ARCH="ARM64" ;; \
         *) echo "unsupported arch ${TARGETARCH}" && exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${HUGO_ARCH}.tar.gz" \
       | tar -xz -C /usr/local/bin hugo \
    && hugo version

WORKDIR /src
COPY . .

ENV HUGO_ENVIRONMENT=production \
    TZ=Europe/Madrid

RUN hugo --gc --minify

# ---- runtime stage -----------------------------------------------------------
FROM nginx:1.27-alpine AS runtime

COPY --from=build /src/public /usr/share/nginx/html

# minimal nginx config: long cache for fingerprinted assets,
# no-cache for HTML, gzip, basic security headers.
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
    listen       8080;
    listen  [::]:8080;
    server_name  _;

    root   /usr/share/nginx/html;
    index  index.html;

    # gzip everything reasonable
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_min_length 1024;
    gzip_types
        text/plain text/css text/xml text/javascript
        application/javascript application/json application/xml
        application/rss+xml application/atom+xml
        image/svg+xml font/woff2;

    # fingerprinted assets (.<hash>.css/js/woff2): long cache, immutable
    location ~* \.(?:css|js)$ {
        try_files $uri =404;
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    location ~* \.(?:woff2?|ttf|otf|eot)$ {
        try_files $uri =404;
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header Access-Control-Allow-Origin "*";
    }

    location ~* \.(?:png|jpe?g|gif|webp|avif|ico|svg)$ {
        try_files $uri =404;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }

    # HTML always fresh (it's static but the content changes)
    location / {
        try_files $uri $uri/ $uri/index.html =404;
        add_header Cache-Control "public, max-age=0, must-revalidate";

        # basic security headers
        add_header X-Content-Type-Options "nosniff";
        add_header X-Frame-Options "DENY";
        add_header Referrer-Policy "strict-origin-when-cross-origin";
        add_header Permissions-Policy "interest-cohort=()";
    }

    # Hugo 404
    error_page 404 /404.html;

    # Don't serve sensitive dotfiles if any sneak into the repo.
    location ~ /\.(?!well-known).* { deny all; }
}
EOF

# the official nginx runs as root + master + workers; we run alpine as non-root.
# NOTE: the official nginx:alpine image already ships the nginx user (uid 101).
# We adjust the paths it needs to write to.
RUN chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx /usr/share/nginx/html \
    && touch /var/run/nginx.pid \
    && chown nginx:nginx /var/run/nginx.pid \
    && sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf 2>/dev/null || true

USER nginx
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ > /dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]

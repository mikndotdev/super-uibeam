FROM oven/bun:1 AS builder
WORKDIR /app

COPY package.json bun.lock ./

COPY apps/frontend ./apps/frontend

RUN bun install --frozen-lockfile

WORKDIR /app/apps/frontend
RUN bun run build

FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

RUN cat <<'EOF' > /etc/nginx/conf.d/default.conf
server {
    listen 80;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    error_page 404 /404.html;
    location = /404.html {
        root /usr/share/nginx/html;
        internal;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
        internal;
    }
}
EOF

COPY --from=builder /app/apps/frontend/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

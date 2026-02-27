FROM oven/bun:1 AS base
WORKDIR /app

COPY . .

RUN bun i
RUN bun run build

FROM nginx:alpine
WORKDIR /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf

RUN printf 'server {\n    listen 80;\n\n    location / {\n        root /usr/share/nginx/html;\n        index index.html;\n        try_files $uri $uri/ /index.html;\n    }\n\n    error_page 404 /404.html;\n    location = /404.html {\n        root /usr/share/nginx/html;\n        internal;\n    }\n\n    error_page 500 502 503 504 /50x.html;\n    location = /50x.html {\n        root /usr/share/nginx/html;\n        internal;\n    }\n}\n' > /etc/nginx/conf.d/default.conf

COPY --from=base /app/apps/frontend/dist .

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

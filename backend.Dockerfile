FROM oven/bun:1 AS base
WORKDIR /app

COPY . .

RUN bun i
RUN bun run build

FROM debian:bookworm-slim
WORKDIR /app

COPY --from=base /app/apps/backend/bin ./

CMD ["./bin"]
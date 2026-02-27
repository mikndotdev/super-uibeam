import { RedisClient } from "bun";
import type { ServerWebSocket } from "bun";

const redis = new RedisClient(process.env.REDIS_URL!);

const connections = new Set<ServerWebSocket>();

async function getCount(): Promise<number> {
  const count = await redis.get("count");
  return count ? parseInt(count, 10) : 0;
}

async function incrementCount(): Promise<number> {
  const newCount = await redis.incr("count");
  return newCount;
}

function broadcast(data: string): void {
  for (const ws of connections) {
    ws.send(data);
  }
}

Bun.serve({
  fetch(req, server) {
    if (server.upgrade(req)) {
      return;
    }
    return new Response("Upgrade failed", { status: 500 });
  },
  websocket: {
    async open(ws: ServerWebSocket) {
      connections.add(ws);
      const count = await getCount();
      ws.send(JSON.stringify({ counter: count, users: connections.size }));
      broadcast(JSON.stringify({ users: connections.size }));
    },
    async message(ws: ServerWebSocket, message: string | Buffer) {
      if (message === "uibeam") {
        const newCount = await incrementCount();
        broadcast(JSON.stringify({ counter: newCount }));
      }
    },
    close(ws: ServerWebSocket) {
      connections.delete(ws);
      broadcast(JSON.stringify({ users: connections.size }));
    },
  },
});

FROM oven/bun:1.3 AS builder

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .
RUN bun --bun run build

FROM oven/bun:1.3

WORKDIR /app

COPY --from=builder /app/build build/
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules node_modules/

EXPOSE 3000

ENV NODE_ENV=production

CMD ["bun", "run", "build/index.js"]

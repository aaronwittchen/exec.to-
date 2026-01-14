FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

# Build the application
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bun run build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Copy built output and package files
COPY --from=builder /app/.output ./.output
COPY --from=builder /app/package.json ./

# Install production deps in server directory
WORKDIR /app/.output/server
RUN bun install --production --no-save 2>/dev/null || true

WORKDIR /app

RUN groupadd --system --gid 1001 nuxt && \
    useradd --system --uid 1001 --gid nuxt nuxt && \
    chown -R nuxt:nuxt /app

USER nuxt

EXPOSE 3000

CMD ["bun", "run", ".output/server/index.mjs"]

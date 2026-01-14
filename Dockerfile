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

RUN groupadd --system --gid 1001 nuxt && \
    useradd --system --uid 1001 --gid nuxt nuxt

# Copy built output and node_modules for external dependencies
COPY --from=builder --chown=nuxt:nuxt /app/.output ./.output
COPY --from=deps --chown=nuxt:nuxt /app/node_modules ./node_modules

USER nuxt

EXPOSE 3000

CMD ["bun", "run", ".output/server/index.mjs"]

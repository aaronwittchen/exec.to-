FROM oven/bun:1 AS base
WORKDIR /app

# -------------------
# Dependencies stage
# -------------------
FROM base AS deps
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

# -------------------
# Build stage
# -------------------
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bun run build

# -------------------
# Production runner
# -------------------
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Copy Nitro output
COPY --from=builder /app/.output ./.output

# Remove symlinked node_modules (Kaniko can't COPY over symlinks), then copy real deps
RUN rm -rf ./.output/server/node_modules
COPY --from=deps /app/node_modules ./.output/server/node_modules

# Create non-root user
RUN groupadd --system --gid 1001 nuxt && \
    useradd --system --uid 1001 --gid nuxt nuxt && \
    chown -R nuxt:nuxt /app

USER nuxt

EXPOSE 3000

CMD ["bun", ".output/server/index.mjs"]

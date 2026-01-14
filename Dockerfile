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

# Copy ONLY the Nitro output
COPY --from=builder /app/.output ./.output

# Optional: package.json (not required unless you rely on it at runtime)
# COPY --from=builder /app/package.json ./

# Create non-root user
RUN groupadd --system --gid 1001 nuxt && \
    useradd --system --uid 1001 --gid nuxt nuxt && \
    chown -R nuxt:nuxt /app
# Copy built output
COPY --from=builder --chown=nuxt:nuxt /app/.output ./.output

# Copy node_modules to both root and server directory for external deps
COPY --from=deps --chown=nuxt:nuxt /app/node_modules ./node_modules
COPY --from=deps --chown=nuxt:nuxt /app/node_modules ./.output/server/node_modules

USER nuxt

EXPOSE 3000

CMD ["bun", ".output/server/index.mjs"]

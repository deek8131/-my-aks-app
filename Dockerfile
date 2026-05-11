# ─────────────────────────────────────────────
# Stage 1: Builder
# Build dependencies & compile (if TypeScript etc)
# ─────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first (layer cache optimization)
COPY package*.json ./

# Install ALL dependencies (including dev)
RUN npm ci --only=production

# Copy source code
COPY src/ ./src/

# ─────────────────────────────────────────────
# Stage 2: Runtime (final lightweight image)
# Only production artifacts, no dev tools
# ─────────────────────────────────────────────
FROM node:20-alpine AS runtime

# Security: non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only what we need from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY package.json ./

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "src/index.js"]
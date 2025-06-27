# syntax=docker/dockerfile:1

ARG NODE_VERSION=22.13.1
FROM node:${NODE_VERSION}-slim AS base

# Set working directory
WORKDIR /app

# Install dependencies in a separate layer for better caching
# Only copy package.json and package-lock.json for dependency install
COPY --link package.json ./
# If you have a lock file, copy it as well (but do NOT copy .env or secrets)
COPY --link package-lock.json ./

# Install production dependencies with cache
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

# Copy application source code (excluding files in .dockerignore)
COPY --link . .

# Create uploads directories and set permissions
RUN mkdir -p public/uploads/gallery public/uploads/thumbnails \
    && chmod -R 755 public/uploads

# Create a non-root user and switch to it
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Set environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Expose the application port
EXPOSE 3001

# Healthcheck for container orchestration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["npm", "start"]

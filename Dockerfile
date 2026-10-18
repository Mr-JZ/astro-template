# syntax=docker/dockerfile:1

FROM oven/bun:1.3.14 AS build
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
COPY . .
# Keeps Astro's optimized-image cache between builds, so unchanged images are not re-encoded.
RUN --mount=type=cache,target=/app/node_modules/.astro bun run build

FROM nginxinc/nginx-unprivileged:1.30.6-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080

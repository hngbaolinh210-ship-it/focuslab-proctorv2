FROM node:24.14.1-bookworm-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ["*.zip", "/tmp/focuslab-archives/"]

# Accept the original ZIP name, including a browser's " (1)" suffix.
# The source archive contains a single focuslab-proctor-server directory.
RUN set -eu; \
    set -- /tmp/focuslab-archives/*.zip; \
    if [ "$#" -ne 1 ]; then echo "Keep exactly one FocusLab source ZIP in the repository root."; exit 1; fi; \
    unzip -q "$1" -d /tmp/focuslab-source; \
    test -f /tmp/focuslab-source/focuslab-proctor-server/package-lock.json; \
    cp -a /tmp/focuslab-source/focuslab-proctor-server/. /app/; \
    rm -rf /tmp/focuslab-archives /tmp/focuslab-source

RUN npm ci && npm run build && npm prune --omit=dev

FROM node:24.14.1-bookworm-slim
WORKDIR /app
COPY --from=build /app /app

ENV NODE_ENV=production \
    DATA_DIR=/data \
    PORT=5173 \
    COOKIE_SECURE=true \
    TRUST_PROXY=true

EXPOSE 5173
CMD ["node", "server/index.mjs"]

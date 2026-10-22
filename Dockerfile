FROM python:3.12-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ["*.zip", "/tmp/focuslab-archives/"]

# Repo chi duoc giu dung MOT ZIP nguon o thu muc goc. ZIP chua thu muc focuslab-fastapi/.
RUN set -eu; \
    set -- /tmp/focuslab-archives/*.zip; \
    if [ "$#" -ne 1 ]; then echo "Keep exactly one FocusLab source ZIP in the repository root."; exit 1; fi; \
    unzip -q "$1" -d /tmp/focuslab-source; \
    test -f /tmp/focuslab-source/focuslab-fastapi/requirements.txt; \
    test -f /tmp/focuslab-source/focuslab-fastapi/static/app.css; \
    cp -a /tmp/focuslab-source/focuslab-fastapi/. /app/; \
    rm -rf /tmp/focuslab-archives /tmp/focuslab-source

RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim

WORKDIR /app
COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /app /app

# FOCUSLAB_BACKUP_URL (duong ket noi PostgreSQL mien phi) dat trong Environment cua
# Render, KHONG ghi vao file nay: no chua mat khau CSDL.
ENV PYTHONUNBUFFERED=1 \
    FOCUSLAB_DB=/data/focuslab-thi.db \
    FOCUSLAB_COOKIE_SECURE=1

EXPOSE 8000
CMD uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}" --proxy-headers

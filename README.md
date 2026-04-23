# media-server

## Description

Wrapper for MediaMTX that reformats the logs

## Build

```bash
INSTALL_ROOT=/opt/project-system ./scripts/build.sh cross
```

## Run

```bash
./media-server.sh ./mediamtx mediamtx.yml
```

## Check Path Status

```bash
./test.sh
./test.sh camera2
API_BASE_URL=http://127.0.0.1:9997 ./test.sh camera2
```

This helper queries `GET /v3/paths/get/{name}` and prints whether a path is `online`, `available`, `offline`, or `missing`.

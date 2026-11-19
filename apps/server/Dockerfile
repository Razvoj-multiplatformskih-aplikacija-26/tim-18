# Kontekst gradnje je koren repozitorijuma (docker-compose.yml).
FROM dart:stable AS build
WORKDIR /app
COPY docker/server-workspace.yaml pubspec.yaml
COPY packages/domain packages/domain
COPY apps/server apps/server
RUN dart pub get
RUN dart compile exe apps/server/bin/server.dart -o /app/server

FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/server /app/server
EXPOSE 8080
CMD ["/app/server"]

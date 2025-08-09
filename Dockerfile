FROM rust AS base
WORKDIR /app

FROM base AS build
COPY src src
COPY Cargo.toml .
RUN cargo build --release

FROM debian:stable-slim AS prod
COPY --from=build /app/target/release/api /usr/bin/api
COPY --from=build /app/target/release/worker /usr/bin/worker
EXPOSE 3000
CMD ["api"]
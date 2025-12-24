# --- Build Stage ---
FROM elixir:1.19-alpine AS runtime_base

# Install build dependencies
RUN apk add --no-cache build-base git sqlite-dev openssl

WORKDIR /app

# Install hex/rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application files
COPY config config
COPY lib lib
COPY priv priv
COPY assets assets

# Compile and Release
RUN mix compile
RUN mix assets.deploy
RUN mix release

# --- Runtime Stage ---
FROM runtime_base

# Install runtime dependencies
RUN apk add --no-cache sqlite

# Create app user
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

WORKDIR /app

# Copy ONLY the release from the build stage
COPY --from=runtime_base --chown=app:app /app/_build/prod/rel/domaindive ./

# Create DB folder
RUN mkdir -p /app/db && chown app:app /app/db

USER app

EXPOSE 4000

CMD ["bin/domaindive", "start"]

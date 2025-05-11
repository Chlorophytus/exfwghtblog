ARG VERSION_ELIXIR=1.18.3
ARG VERSION_ERLANG=27.3.4
ARG VERSION_OS=3.21.3
ARG IMAGE_BUILDER="hexpm/elixir:${VERSION_ELIXIR}-erlang-${VERSION_ERLANG}-alpine-${VERSION_OS}"
ARG IMAGE_RUNNER="alpine:${VERSION_OS}"
# loosely based off https://blog.logrocket.com/run-phoenix-application-docker/
# =============================================================================
# Build the Alpine-based image
# =============================================================================
FROM ${IMAGE_BUILDER} as builder
# Install NodeJS 18, and NPM
RUN apk -U upgrade && \
    apk add alpine-sdk argon2-dev nodejs npm
WORKDIR /app
# Install Hex and Rebar3
RUN mix local.hex --force && \
    mix local.rebar --force
# Start building the prod environment
ENV MIX_ENV="prod"
# Packages and lockfile
COPY mix.exs mix.lock ./
# Only get production dependencies
RUN mix deps.get --only $MIX_ENV

# Copy over config
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
# Compile dependencies
RUN mix deps.compile
# Copy priv/, lib/, and assets/
COPY priv priv
COPY lib lib
COPY assets assets

# NPM/ESBuild are strange and don't want to download dependencies
RUN npm install --prefix assets

# Deploy assets, compile main codebase
RUN mix assets.deploy
RUN mix compile

# Release prepare and build
COPY config/runtime.exs config/
COPY rel rel
RUN mix release
# =============================================================================
# Runnner image
# =============================================================================
FROM ${IMAGE_RUNNER}
RUN apk -U upgrade && \
    apk add libstdc++ ncurses openssl
WORKDIR /app
RUN chown nobody /app
# Set to prod again
ENV MIX_ENV="prod"
# Copy /app as nobody
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/exfwghtblog ./
USER nobody
# Run
CMD ["/app/bin/exfwghtblog"]

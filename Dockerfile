ARG VER_ELIXIR
ARG VER_ERLANG
FROM hexpm/elixir:${VER_ELIXIR}-erlang-${VER_ERLANG}-alpine-3.14.2

RUN apk upgrade && \
		mkdir /opt/application

COPY . /opt/application
WORKDIR /opt/application

RUN mix local.hex --force && \
		mix local.rebar --force && \
		mix deps.get

RUN MIX_ENV=prod mix release

CMD ["_build/prod/rel/exfwghtblog/bin/exfwghtblog"]

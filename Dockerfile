FROM "hexpm/elixir:1.12.3-erlang-23.3-debian-bullseye-20210902-slim"

ENV MIX_ENV=prod
RUN apt-get update -y && apt-get install -y build-essential git protobuf-compiler libstdc++6 openssl \
  libncurses5 locales inotify-tools \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

COPY assets /app/assets
COPY config /app/config
COPY lib /app/lib
COPY priv /app/priv
COPY test /app/test
COPY mix.exs /app/mix.exs
COPY mix.lock /app/mix.lock
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force && mix do deps.get, deps.compile --only prod
RUN mix assets.deploy
RUN mix escript.install hex protobuf --force
RUN mix release

ENV PHX_SERVER=true
ENV SECRET_KEY_BASE=
ENV PHX_HOST=localhost
ENV PORT=4000
EXPOSE 4000

WORKDIR /app/_build/prod/rel/grpc_mock
RUN mkdir -p ./tmp
ENV PATH="/root/.mix/escripts:${PATH}"
CMD ["./bin/grpc_mock", "start"]

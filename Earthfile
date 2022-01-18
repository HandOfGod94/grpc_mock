FROM hexpm/elixir:1.12.3-erlang-23.3-debian-bullseye-20210902-slim

compile:
  ENV MIX_ENV=dev
  COPY . ./app
  WORKDIR /app
  RUN mix local.hex --force && mix local.rebar --force && mix do deps.get, deps.compile
  RUN mkdir -p ./tmp
  RUN mix assets.deploy
  SAVE ARTIFACT /app /app

build:
  COPY +compile/app ./app
  RUN apt-get update -y && apt-get install -y build-essential git protobuf-compiler libstdc++6 openssl \
    libncurses5 locales inotify-tools \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*
  RUN mix local.hex --force && mix local.rebar --force
  RUN mix escript.install hex protobuf --force
  ENV PATH="/root/.mix/escripts:${PATH}"
  WORKDIR /app
  CMD ["mix", "phx.server"]
  SAVE IMAGE grpc_mock_dev:latest
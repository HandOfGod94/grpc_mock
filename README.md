# GrpcMock

|:warning::construction:|Caution|:construction::warning:|
|---|---|---|
|:warning::construction:|Work In Progress|:construction::warning:|

---

[![build](https://github.com/HandOfGod94/grpc_mock/actions/workflows/build.yml/badge.svg)](https://github.com/HandOfGod94/grpc_mock/actions/workflows/build.yml)
[![coverage](https://coveralls.io/repos/github/HandOfGod94/grpc_mock/badge.svg?branch=main)](https://coveralls.io/github/HandOfGod94/grpc_mock?branch=main)

## Features
- Dynamic Proto Compilation. Directly compile it via UI.
- Generate mock server dynamically and access it via dynamically binded ports
- Supports partial mocking (only want to mock one or 2 methods out of protobuf contract not an issue, do it rightaway)

## Run using docker
```
# ensure to use correct `pwd`
# expose as many ports as you want. Each port can be binded to different mock service.
docker run -it --rm -p 4000-4010:4000-4010 -e SECRET_KEY_BASE=<64-bytes-random> -v $(pwd):/app/protos ghcr.io/handofgod94/grpc_mock:latest
```

The web UI will be available at [`localhost:4000`](http://localhost:4000)

## Elixir Setup

* Elixir version: 1.12+
* Erlang/OTP Version: 23+

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

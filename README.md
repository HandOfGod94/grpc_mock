# GrpcMock

:warning::construction: POC  :construction::warning:  
:warning::construction: Work In Progress  :construction::warning:

## Features
- Dynamic Proto Compilation. No need to add dependencies on config file, directly compile it via UI
- Generate mock server dynamically and access it via dynamically binded ports
- partial mocking (only want to mock one or 2 methods out of protobuf contract not an issue, do it rightaway)

## Docker commands
```sh
# build
docker build -t grpc_mock:latest .

# ensure to use correct `pwd`
docker run -it --rm -p 4000-4010:4000-4010 -e SECRET_KEY_BASE=<64-bytes-random> -v $(pwd):/app/protos grpc_mock:latest
```

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

## Build via docker/Earthfile
* [Earthly](https://earthly.dev/)
* Docker

```sh
# install earthly
make setup

# build/compile
make compile

# builds docker image
make build

# run
make run
```

## TODO
**core**
- [x] generate elixir proto files programmatically
- [x] load generated modules in the code
- [x] spin up grpc server with mock implmentation using `DynamicSupervisor`
  - [ ] allocate ports dynamically based on the service chosen
- [x] read stub response from user `json`

**UI**
- [x] get import_path from user
- [x] get protofiles from user
- [ ] allow user to select service which needs to be stubbed
- [ ] accept stub response from user
- [x] show grpc server info (current active stub, ports, state) on UI

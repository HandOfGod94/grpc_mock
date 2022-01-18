# GrpcMock

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

## TODO
**core**
- [ ] generate elixir proto files programmatically
- [ ] load generated modules in the code
- [ ] spin up grpc server with mock implmentation using `DynamicSupervisor`
  - [ ] allocate ports dynamically based on the service chosen
- [ ] read stub response from user `json`

**UI**
- [ ] get import_path from user
- [ ] get protofiles from user
- [ ] allow user to select service which needs to be stubbed
- [ ] accept stub response from user
- [ ] show grpc server info (current active stub, ports, state) on UI
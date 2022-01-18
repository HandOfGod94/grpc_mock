compile:
	earthly +compile

build:
	earthly +build

run:
	$(info Please manually run this command)
	$(info ensure you mount correct protos dir in palce of `$$(pwd)`)
	$(info docker run -it -v $$(pwd):/app/protos -p 4000-4030:4000-4030 --rm grpc_mock_dev:latest)

setup:
	brew install earthly/earthly/earthly && earthly bootstra
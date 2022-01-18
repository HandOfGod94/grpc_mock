compile: setup
	earthly +compile

build: setup
	earthly +build

run:
	echo "ensure you mount correct protos"
	echo "run docker run -it -v $(pwd):/app/protos -p 4000:4000 --rm grpc_mock_dev:latest"

setup:
	brew install earthly/earthly/earthly && earthly bootstra
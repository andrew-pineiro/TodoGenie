BUILD_DIR=build
SRC_DIR=src
OS ?= linux

.PHONY: build deploy

build:
	@echo "++ Building TodoGenie..."
	dotnet publish $(SRC_DIR)/TodoGenie/TodoGenie.csproj --self-contained /p:PublishSingleFile=true -o $(BUILD_DIR)/$(OS) --os $(OS) -c Release
	@rm $(BUILD_DIR)/$(OS)/*.pdb -f
	@echo "++ Successfully built TodoGenie"

test:
	@echo "++ Running TodoGenie Tests..."
	dotnet test
	@echo "++ TodoGenie Tests Completed"

deploy: build
	@echo "++ Deploying TodoGenie..."
	@sudo cp $(BUILD_DIR)/$(OS)/TodoGenie /usr/local/bin/todogenie
	@echo "++ Sucessfully deployed. Type \`todogenie\` to start"


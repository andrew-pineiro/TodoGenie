BUILD_DIR=build
SRC_DIR=src
OS ?= linux

.PHONY: build dir_setup

build: dir_setup
	@echo "++ Building TodoGenie..."
	dotnet publish $(SRC_DIR)/TodoGenieLib/TodoGenieLib.csproj -o $(BUILD_DIR)/lib --os $(OS)
	dotnet publish $(SRC_DIR)/TodoGenie/TodoGenie.csproj --self-contained /p:PublishSingleFile=true -o $(BUILD_DIR) --os $(OS)
	@echo "++ Successfully built TodoGenie"

dir_setup:
	@mkdir -p $(BUILD_DIR)/lib
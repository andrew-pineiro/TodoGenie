BUILD_DIR=build
SRC_DIR=src

#TODO: get this working
#OS ?= $(dotnet --info | grep  -e \'OS Platform: \(\W*\)\' | grep -e \': \w*\' --only-matching | grep -e \'\w*\' --only-matching)
OS=linux

.PHONY: build

build: 
	@echo "Building TodoGenie..."
	dotnet publish $(SRC_DIR)/TodoGenieLib/TodoGenieLib.csproj -o $(BUILD_DIR) --os $(OS)
	dotnet publish $(SRC_DIR)/TodoGenie/TodoGenie.csproj --self-contained /p:PublishSingleFile=true -o $(BUILD_DIR) --os $(OS)
	@echo "Successfully built TodoGenie"
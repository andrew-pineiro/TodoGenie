BUILD_DIR=build
SRC_DIR=src
OS ?= linux

.PHONY: build deploy test

clean:
ifeq ($(OS), win)
	@del $(BUILD_DIR)\$(OS)\TodoGenie.pdb /f
else
	@rm $(BUILD_DIR)/$(OS)/TodoGenie.pdb -f
endif

build:
	@echo "++ Building TodoGenie..."
	dotnet publish $(SRC_DIR)/TodoGenie/TodoGenie.csproj --self-contained /p:PublishSingleFile=true -o $(BUILD_DIR)/$(OS) --os $(OS) -c Release
	@echo "++ Successfully built TodoGenie"

test:
	@echo "++ Running TodoGenie Tests..."
	dotnet test
	@echo "++ TodoGenie Tests Completed"

deploy: build clean
	@echo "++ Deploying TodoGenie..."
ifeq ($(OS), win)
	@xcopy $(BUILD_DIR)\$(OS)\TodoGenie.exe 'C:\users\Chill\Applications\' /D /Y
else
	@sudo cp $(BUILD_DIR)/$(OS)/TodoGenie /usr/local/bin/todogenie
endif
	@echo "++ Sucessfully deployed. Type \`todogenie\` to start"


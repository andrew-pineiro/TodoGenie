BUILD_DIR=build
SRC_DIR=src
OS ?= linux
APP=TodoGenie
.PHONY: build deploy test

clean:
ifeq ($(OS), win)
	@del $(BUILD_DIR)\$(OS)\$(APP).pdb /f
else
	@rm $(BUILD_DIR)/$(OS)/$(APP).pdb -f
endif

build:
	@echo "++ Building $(APP)..."
	dotnet publish $(SRC_DIR)/$(APP)/$(APP).csproj --self-contained /p:PublishSingleFile=true -o $(BUILD_DIR)/$(OS) --os $(OS) -c Release
	@echo "++ Successfully built $(APP)"

test:
	@echo "++ Running $(APP) Tests..."
	dotnet test
	@echo "++ $(APP) Tests Completed"

deploy: build clean
	@echo "++ Deploying $(APP)..."
ifeq ($(OS), win)
	@xcopy $(BUILD_DIR)\$(OS)\$(APP).exe 'C:\users\Chill\Applications\' /D /Y
else
	@sudo cp $(BUILD_DIR)/$(OS)/$(APP) /usr/local/bin/$(APP)
endif
	@echo "++ Sucessfully deployed. Type \`$(APP)\` to start"


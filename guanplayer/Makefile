FLEX_SDK ?= /opt/flex
MXMLC ?= $(FLEX_SDK)/bin/mxmlc
COMPC ?= $(FLEX_SDK)/bin/compc
BUILD_DIR ?= build
BUILD_PLAYER=$(BUILD_DIR)/player.swf

DEBUG ?= false
LOGGING ?= false

TARGET_PLAYER ?= 19.0

SRC = src/TanPlayer.as

all: clean build


clean:
	rm -rf build

build:
	$(MXMLC) $(SRC) \
	-l "$(FLEX_SDK)/frameworks/libs" \
	-l "./lib" \
	-o $(BUILD_PLAYER) \

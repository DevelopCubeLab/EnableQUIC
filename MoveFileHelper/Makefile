TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = MoveFileHelper

$(TOOL_NAME)_FILES = main.m
$(TOOL_NAME)_CFLAGS = -fobjc-arc
$(TOOL_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
$(TOOL_NAME)_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

after-stage::
	@echo "Copying file to parent directory..."
	cp $(THEOS_STAGING_DIR)/usr/local/bin/$(TOOL_NAME) ../$(TOOL_NAME)/
	@echo "Copy completed."


TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = AdvancedHelper

AdvancedHelper_FILES = main.m
AdvancedHelper_CFLAGS = -fobjc-arc
AdvancedHelper_CODESIGN_FLAGS = -Sentitlements.plist
AdvancedHelper_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

after-stage::
	@echo "Copying file to parent directory..."
	cp $(THEOS_STAGING_DIR)/usr/local/bin/$(TOOL_NAME) ../$(TOOL_NAME)/
	@echo "Copy completed."

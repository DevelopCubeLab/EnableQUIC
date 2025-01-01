TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = FileAttributesHelper

FileAttributesHelper_FILES = main.m
FileAttributesHelper_CFLAGS = -fobjc-arc
FileAttributesHelper_CODESIGN_FLAGS = -Sentitlements.plist
FileAttributesHelper_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk

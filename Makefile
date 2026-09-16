TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GPSMasterPatch

GPSMasterPatch_FILES = Tweak.x
GPSMasterPatch_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
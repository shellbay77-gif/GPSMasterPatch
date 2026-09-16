TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GPSMasterPatch

GPSMasterPatch_FILES = Tweak.x URLPatch.x
GPSMasterPatch_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

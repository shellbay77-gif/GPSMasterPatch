THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GPSMasterPatch

GPSMasterPatch_FILES = Tweak.x
GPSMasterPatch_CFLAGS = -fobjc-arc
GPSMasterPatch_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
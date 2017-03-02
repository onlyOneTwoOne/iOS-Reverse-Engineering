THEOS_DEVICE_IP = 10.1.20.160
ARCHS = armv7 armv7s
TARGET = iphone:latest:8.0

include /opt/theos/makefiles/common.mk

TWEAK_NAME = jrq
jrq_FILES = Tweak.xm
jrq_FRAMEWORKS = UIKit

_THEOS_TARGET_LDFLAGS += -current_version 1.0
_THEOS_TARGET_LDFLAGS += -compatibility_version 1.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 com.fromax.jrq"

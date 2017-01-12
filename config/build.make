BUILD ?= release
BUILD_DIR := $(BUILD_DIR)_$(BUILD)

cxxflags_release :=
cxxflags_release += -O2
cxxflags_release += -DNDEBUG

cxxflags_debug :=

ifeq ($(origin cxxflags_$(BUILD)),undefined)
  $(error cxxflags_$(BUILD): undefined)
endif

CXXFLAGS += $(cxxflags_$(BUILD))

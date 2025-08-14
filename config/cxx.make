CXXSTD ?= -std=c++20

CXXFLAGS += $(CXXSTD)
CXXFLAGS += -g

cxxflags_clang++ :=
cxxflags_clang++ += -Weverything
cxxflags_clang++ += -Wno-c++98-compat
cxxflags_clang++ += -Wno-c++98-compat-pedantic
cxxflags_clang++ += -Wno-poison-system-directories
cxxflags_clang++ += -Wno-pre-c++20-compat-pedantic
cxxflags_clang++ += -Wno-shadow-field-in-constructor
cxxflags_clang++ += -Wno-unused-private-field
cxxflags_clang++ += -Wno-switch-default

cxxflags_g++ :=
cxxflags_g++ += -Wall
cxxflags_g++ += -Wextra
cxxflags_g++ += -Wpedantic

CXXFLAGS += -Werror
CXXFLAGS += -Wno-padded
CXXFLAGS += -Wno-packed

CXX := $(if $(filter c++,$(CXX)),clang++,$(CXX))

ifeq ($(origin cxxflags_$(CXX)),undefined)
  $(error cxxflags_$(CXX): undefined)
endif

CXXFLAGS += $(cxxflags_$(CXX))

ldflags_clang++ :=
ldflags_g++ :=

ifeq ($(origin ldflags_$(CXX)),undefined)
  $(error ldflags_$(CXX): undefined)
endif

LDFLAGS := $(ldflags_$(CXX))

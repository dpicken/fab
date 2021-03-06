CXXSTD ?= -std=c++17

CXXFLAGS += $(CXXSTD)
CXXFLAGS += -g

cxxflags_clang++ :=
cxxflags_clang++ += -Weverything
cxxflags_clang++ += -Wno-c++98-compat

cxxflags_g++ :=
cxxflags_g++ += -Wall
cxxflags_g++ += -Wextra
cxxflags_g++ += -Wpedantic

CXXFLAGS += -Werror
CXXFLAGS += -Wno-error=padded

CXX := $(if $(filter c++,$(CXX)),$(shell readlink `type -p c++`),$(CXX))

ifeq ($(origin cxxflags_$(CXX)),undefined)
  $(error cxxflags_$(CXX): undefined)
endif

CXXFLAGS += $(cxxflags_$(CXX))

ldflags_clang++ :=
ldflags_clang++ += -lpthread

ldflags_g++ :=
ldflags_g++ += -pthread

ifeq ($(origin ldflags_$(CXX)),undefined)
  $(error ldflags_$(CXX): undefined)
endif

LDFLAGS := $(ldflags_$(CXX))

CXX := $(if $(filter c++,$(CXX)),$(shell readlink `type -p c++`),$(CXX))

CXXFLAGS += -std=c++14
CXXFLAGS += -g
CXXFLAGS += -Werror

cxxflags_g++ :=
cxxflags_g++ += -Wall
cxxflags_g++ += -Wextra
cxxflags_g++ += -Wpedantic

cxxflags_clang++ :=
cxxflags_clang++ += -Weverything
cxxflags_clang++ += -Wno-c++98-compat

ifeq ($(origin cxxflags_$(CXX)),undefined)
  $(error cxxflags_$(CXX): undefined)
endif

CXXFLAGS += $(cxxflags_$(CXX))

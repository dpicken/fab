# Fab - A "build system" for C++ projects.
# Copyright (c) 2017 Daniel Picken
# See https://github.com/dpicken/fab

# Make configuration.
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

# Default project configuration that SHOULD only be overriden in config*.make files (see below).
SRC_DIR ?= src
SRC_EXT_CXX ?= cc
SRC_EXT_AS ?= s
SRC_EXT_PLD ?= pld
BUILD_DIR ?= build
CXX ?= g++
CXXFLAGS ?=
CXX.MKDEPS ?= $(CXX) -MM -MP -MT
CXX.MKDEPS.CXXFLAGS ?= $(CXXFLAGS)
AS ?= as
ASFLAGS ?=
AR ?= ar
AR.MKLIB ?= $(AR) qcs
LDFLAGS ?=
PLD ?= galette
PLDFLAGS ?= --nochip --nofuse --nopin

# Default project configuration that MAY be overriden by the environment (or config*.make files).
ECHO_BUILD_MESSAGES ?= x
ECHO_RECIPES ?=

makefile := $(lastword $(MAKEFILE_LIST))
config_makefiles := $(wildcard config/*.make)
include $(config_makefiles)

# Separate source files and build artifacts:
#   - Easier to exclude build artifacts from revision control.
#   - Simpler/safer "make clean".
ifeq ($(SRC_DIR),$(BUILD_DIR))
  $(error SRC_DIR and BUILD_DIR should not be the same location)
endif

# Final expansion of configuration.
src_dir := $(SRC_DIR)
src_ext_cxx := $(SRC_EXT_CXX)
src_ext_as := $(SRC_EXT_AS)
src_ext_pld := $(SRC_EXT_PLD)
build_dir := $(BUILD_DIR)
cxx := $(CXX)
cxxflags := $(strip -I$(src_dir) $(CXXFLAGS))
cxx.mkdeps := $(CXX.MKDEPS)
cxx.mkdeps.cxxflags := $(strip -I$(src_dir) $(CXX.MKDEPS.CXXFLAGS))
as := $(AS)
asflags := $(ASFLAGS)
ar := $(AR)
ar.mklib := $(AR.MKLIB)
ldflags := $(LDFLAGS)
pld := $(PLD)
pldflags := $(PLDFLAGS)
echo_build_messages := $(ECHO_BUILD_MESSAGES)
echo_recipes := $(ECHO_RECIPES)

# Host information
host_os := $(shell uname -s | tr "[:upper:]" "[:lower:]")
host_machine_type := $(shell uname -m | tr "[:upper:]" "[:lower:]")

# Source files MUST be placed in directories beneath $(src_dir).
cmd_find_src_stem := find $(src_dir) -mindepth 1

srcs_cxx :=
srcs_as :=
objs_cxx :=
objs_as :=
libs :=

# A static library is built for each directory that contains source files.
# The library is named after its directory, e.g. the source tree...
#
#   $(src_dir)/example/foo.cc
#   $(src_dir)/example/bar.cc
#   $(src_dir)/example/subexample/qux.cc
#
# ...will produce:
#
#   $(build_dir)/example/example.a (containing the object files built from foo.cc and bar.cc).
#   $(build_dir)/example/subexample/subexample.a (containing the object file built from qux.cc).
#
# Any source files within a "platform/" directory are filtered; only those with a ".$(host_os)-$(host_machine_type)" suffix
# prior to the file name's (final) extension are included...
#
#   $(src_dir)/example/platform/foo.darwin-x86_64.cc
#   $(src_dir)/example/platform/foo.linux-x86_64.cc
#
# will produce the following on a x64_64 macOS host...
#
#   $(build_dir)/example/platform/platform.a (containing the object file built from foo.darwin-x86_64.cc).
#
# ...and the following on a x86_64 Linux host:
#
#   $(build_dir)/example/platform/platform.a (containing the object file built from foo.linux-x86_64.cc).
src_sub_dirs := $(shell $(cmd_find_src_stem) -type d)

define eval_lib
  src_sub_dir := $1

  src_file_stem_pattern := $$(if $$(patsubst platform,,$$(notdir $$(src_sub_dir))),*,*.$(host_os)-$(host_machine_type))
  lib_srcs_cxx := $$(wildcard $$(src_sub_dir)/$$(src_file_stem_pattern).$(src_ext_cxx))
  lib_srcs_as := $$(wildcard $$(src_sub_dir)/$$(src_file_stem_pattern).$(src_ext_as))
  lib_srcs_pld := $$(wildcard $$(src_sub_dir)/$$(src_file_stem_pattern).$(src_ext_pld))

  lib_objs_cxx := $$(patsubst $(src_dir)%,$(build_dir)%.o,$$(lib_srcs_cxx))
  lib_objs_as := $$(patsubst $(src_dir)%,$(build_dir)%.o,$$(lib_srcs_as))
  lib_objs_pld := $$(patsubst $(src_dir)%,$(build_dir)%.o,$$(lib_srcs_pld))
  lib_objs := $$(strip $$(lib_objs_cxx) $$(lib_objs_as) $$(lib_objs_pld))

  ifneq ($$(lib_objs),)
    lib := $$(patsubst $(src_dir)%,$(build_dir)%,$$(src_sub_dir)/$$(notdir $$(src_sub_dir).a))
    $$(lib).src_dir := $$(src_sub_dir)
    $$(lib).objs := $$(lib_objs)

    srcs_cxx += $$(lib_srcs_cxx)
    srcs_as += $$(lib_srcs_as)
    srcs_pld += $$(lib_srcs_pld)
    objs_cxx += $$(lib_objs_cxx)
    objs_as += $$(lib_objs_as)
    objs_pld += $$(lib_objs_pld)
    libs += $$(lib)
  endif
endef
$(foreach src_sub_dir,$(src_sub_dirs),$(eval $(call eval_lib,$(src_sub_dir))))
lib_build_dirs := $(foreach lib,$(libs),$(patsubst %/,%,$(dir $(lib))))

deps := $(patsubst %.o,%.d,$(strip $(objs_cxx) $(objs_as) $(objs_pld)))

# An executable binary is built for each directory that contains a "main.cc" and/or a "bin.make" file.
# The binary is named after the directory, e.g. the source tree...
#
#   $(src_dir)/hello_world/main.cc
#
# ...will produce:
#
#   - $(build_dir)/hello_world/hello_world.a (containing the object file built from main.cc)
#   - $(build_dir)/hello_world/hello_world (implicitly linked with hello_world.a)
#
# Any additional libraries a binary depends on MUST be explicitly specified in $(src_dir)/hello_world/bin.make (see below).
bin_main_dirs := $(patsubst %/main.$(src_ext_cxx),%,$(filter %/main.$(src_ext_cxx),$(srcs_cxx)))
bin_makefiles=$(shell $(cmd_find_src_stem) -name bin.make)
bin_makefile_dirs := $(patsubst %/,%,$(dir $(bin_makefiles)))
bin_build_dirs := $(patsubst $(src_dir)%,$(build_dir)%,$(sort $(bin_main_dirs) $(bin_makefile_dirs)))
bins := $(foreach bin_dir,$(bin_build_dirs),$(patsubst $(src_dir)%,$(build_dir)%,$(bin_dir))/$(notdir $(bin_dir)))

define eval_bin
  bin := $1

  $$(bin).ldflags :=
  $$(bin).libs := $$(filter $$(bin).a,$$(libs))
  $$(bin).system_libs :=
  $$(bin).bin_makefile :=
endef
$(foreach bin,$(bins),$(eval $(call eval_bin,$(bin))))

# A "bin.make" file specifies any additional libraries that a binary depends on via two lists:
#
#   LIB_DIRS - list of directories within $(src_dir).
#   SYSTEM_LIBS - list of system libraries.
#
# e.g. if $(src_dir)/hello_world/bin.make contained...
#
#   LIB_DIRS += example
#   LIB_DIRS += example/subexample
#   SYSTEM_LIBS += rt
#
# ...then $(build_dir)/hello_world/hello_world would be additionally linked with:
#
#   $(build_dir)/example/example.a
#   $(build_dir)/example/subexample/subexample.a
#   librt
#
# Alternatively and/or additionally, specific link flags needed to build the binary can be specified via:
#
#   LDFLAGS - list of link flags
define eval_bin_makefile
  bin_makefile := $1

  bin_build_dir := $(patsubst $(src_dir)%/,$(build_dir)%,$(dir $(bin_makefile)))
  bin := $$(bin_build_dir)/$$(notdir $$(bin_build_dir))

  LDFLAGS :=
  LIB_DIRS :=
  SYSTEM_LIBS :=
  include $(bin_makefile)

  $$(bin).ldflags := $$(strip $$(LDFLAGS))
  $$(bin).libs := $$(strip $$($$(bin).libs) $$(foreach lib_dir,$$(LIB_DIRS),$(build_dir)/$$(lib_dir)/$$(notdir $$(lib_dir).a)))
  $$(bin).system_libs := $$(strip $$(SYSTEM_LIBS))
  $$(bin).bin_makefile := $(bin_makefile)
endef
$(foreach bin_makefile,$(bin_makefiles),$(eval $(call eval_bin_makefile,$(bin_makefile))))

# Any binaries beneath "test" directories are executed by the build process.
# A test MUST return zero on success / non-zero on failure.
# A test failure is treated as a build failure.
# The standard out/error streams of a test binary are redirected to a log file named after the binary, e.g. the binary produced from...
#
#   $(src_dir)/example/test/main.cc
#
# ...would be...
#
#   $(build_dir)/example/test/test
#
# ...and its log file would be:
#
#   $(build_dir)/example/test/test.log
tests := $(shell echo $(bins) | awk -v RS=" " '/\/test\//')
test_passes := $(patsubst %,%.pass,$(tests))

build_dir_tree := $(sort $(foreach path,$(sort $(lib_build_dirs) $(bin_build_dirs)),$(eval branches :=)$(patsubst %/,%,$(strip $(foreach dir,$(subst /, ,$(path)),$(eval branches := $(branches)$(dir)/) $(branches))))))

echo_build_message = $(if $(echo_build_messages),$(info Building $@$(if $?, on $(if $(filter-out $?,$^),$?,$^))))
echo_recipe := $(if $(echo_recipes),,@)

init:

.PHONY: test
test : $(test_passes)

.PHONY: all
all: $(libs) $(bins) $(test_passes)

.PHONY: clean
clean:
	$(echo_recipe)[ ! -d $(build_dir) ] || find $(build_dir) -type f \( -name '*.o' -o -name '*.d' -o -name '*.a' -o -name '*.tmp' -o $(if $(findstring linux,$(host_os)),-executable,-perm +u=x,g=x,o=x) -o -name '*.log' -o -name '*.pass' \) -delete
	$(echo_recipe)[ ! -d $(build_dir) ] || find $(build_dir) -type d -delete

.PHONY: inspect
inspect:
	$(echo_recipe)true $(foreach i,$(sort $(.VARIABLES)),$(if $(filter-out automatic default environment,$(origin $i)),$(info $i=$(value $i))))

-include $(deps)

.SECONDEXPANSION:

target_prereq_parent_dir := $$(patsubst %/,%,$$(dir $$@))

$(build_dir_tree): | init $(target_prereq_parent_dir)
	$(echo_build_message)
	$(echo_recipe)mkdir $(if $(findstring B,$(MAKEFLAGS)),-p )$@

dep_ext_tmp = tmp.d
obj_prereq_src_file := $$(patsubst $(build_dir)%.o,$(src_dir)%, $$@)
obj_makefiles = $(strip $(config_makefiles) $(makefile))
obj_recipe_src_file = $<
obj_recipe_dep_file = $(patsubst %.o,%.d,$@)
obj_recipe_makefile_deps = $(echo_recipe)echo "$@ $(obj_makefiles)" | awk '{ for(i = 2; i <= NF; i++) deps = deps " " $$i; print "\n" $$1 ":" deps; for(i = 2; i <= NF; i++) print "\n" $$i ":"}'

$(objs_cxx): $(obj_prereq_src_file) $(obj_makefiles) | $(target_prereq_parent_dir)
	$(echo_build_message)
	$(echo_recipe)$(cxx.mkdeps) $@ $(cxx.mkdeps.cxxflags) $(obj_recipe_src_file) > $(obj_recipe_dep_file).$(dep_ext_tmp)
	$(echo_recipe)$(obj_recipe_makefile_deps) >>$(obj_recipe_dep_file).$(dep_ext_tmp)
	$(echo_recipe)mv $(obj_recipe_dep_file).$(dep_ext_tmp) $(obj_recipe_dep_file)
	$(echo_recipe)$(cxx) -o $@ -c $(cxxflags) $(obj_recipe_src_file)

$(objs_as): $(obj_prereq_src_file) $(obj_makefiles) | $(target_prereq_parent_dir)
	$(echo_build_message)
	$(echo_recipe)echo "$@: $(obj_recipe_src_file)" >$(obj_recipe_dep_file).$(dep_ext_tmp)
	$(echo_recipe)$(obj_recipe_makefile_deps) >>$(obj_recipe_dep_file).$(dep_ext_tmp)
	$(echo_recipe)mv $(obj_recipe_dep_file).$(dep_ext_tmp) $(obj_recipe_dep_file)
	$(echo_recipe)$(as) -o $@ $(asflags) $(obj_recipe_src_file)

$(objs_pld): $(obj_prereq_src_file) $(obj_makefiles) | $(target_prereq_parent_dir)
	$(echo_build_message)
	$(echo_recipe)echo "$@: $(obj_recipe_src_file)" >$(obj_recipe_dep_file).$(dep_ext_tmp)
	$(echo_recipe)$(obj_recipe_makefile_deps) >>$(obj_recipe_dep_file).$(dep_ext_tmp)
	$(echo_recipe)mv $(obj_recipe_dep_file).$(dep_ext_tmp) $(obj_recipe_dep_file)
	$(echo_recipe)cp $< $(basename $@).tmp
	$(echo_recipe)$(pld) $(pldflags) $(basename $@).tmp && mv $(basename $@).jed $@

$(libs): $$($$@.objs) $$($$@.src_dir)
	$(echo_build_message)
	$(echo_recipe)rm -f $@ && $(ar.mklib) $@ $(filter %.o,$^)

bin_recipe_lib_flags_pre_g++ := -Wl,--whole-archive
bin_recipe_lib_flags_post_g++ := -Wl,--no-whole-archive
bin_recipe_lib_flags_pre_clang++ := -Wl,-force_load
bin_recipe_lib_flags_post_clang++ :=
bin_recipe_lib_flags_pre_c++ := $(bin_recipe_lib_flags_pre_clang++)
bin_recipe_lib_flags_post_c++ := $(bin_recipe_lib_flags_post_clang++)
ifeq ($(origin bin_recipe_lib_flags_post_$(cxx)),undefined)
  $(error bin_recipe_lib_flags_post_$(cxx): undefined)
endif
bin_recipe_lib_flags = $(patsubst %,$(bin_recipe_lib_flags_pre_$(cxx)) % $(bin_recipe_lib_flags_post_$(cxx)),$(filter %.a,$^))
bin_recipe_system_lib_flags = $(patsubst %,-l%,$($@.system_libs))

$(bins): $$($$@.libs) $$($$@.bin_makefile) | $(target_prereq_parent_dir)
	$(echo_build_message)
	$(echo_recipe)$(cxx) -o $@ $(cxxflags) $(ldflags) $($@.ldflags) $(bin_recipe_lib_flags) $(bin_recipe_system_lib_flags)

test_pass_prereq_test_bin := $$(patsubst %.pass,%,$$@)
test_pass_recipe_log_file = $(patsubst %.pass,%.log,$@)
test_pass_recipe_bin = $<
test_pass_recipe_src_dir = $(patsubst $(build_dir)%/,$(src_dir)%,$(dir $@))

$(test_passes): $(test_pass_prereq_test_bin)
	$(echo_build_message)
	$(echo_recipe)$(test_pass_recipe_bin) >$(test_pass_recipe_log_file) 2>&1 || (echo Test failed: $(test_pass_recipe_src_dir) - dumping $(test_pass_recipe_log_file) && cat $(test_pass_recipe_log_file) && false)
	$(echo_recipe)touch $@

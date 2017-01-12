# Fab

A build system for C++ projects.  Make based, non-recursive and incremental.

## Features

- Robust incremental builds.  Rebuilds exactly what needs to be rebuilt, no more and no less.
- Build artifacts (object files, libraries, binaries, etc) are placed in a build tree outside the source tree.
- Support for executing unit tests as part of the build process.  A test failure is treated as a build failure.
- Zero Make boilerplate required to build a project.
- Tested with GNU Make, g++ and clang++ on Linux and macOS.

## Getting Started

Clone Fab, it may be placed inside or outside your project, e.g.

    FAB=~/fab
    git clone https://github.com/dpicken/fab $FAB
    cd my-project
    ln -s $FAB/Makefile .; # Use Fab's Makefile.
    ln -s $FAB/config .; # Use Fab's example configuration (optional, see below).
    make

Fab looks for source code within sub-directories of `my-project/src` and places all build artifacts in `my-project/build`.
These locations are configurable (see below).

N.B. Fab's example configuration supports release and debug builds.
A release build places its (optimized) artifacts in `my-project/build_release`.
A debug build places its artifacts in `my-project/build_debug`.

## Libraries

A static library is built for each directory that contains files with a `.cc` extension.
The extension is configurable (see below).

A library is named after its corresponding source path, e.g.

    src/example/foo.cc
    src/example/bar.cc
    src/example/subexample/qux.cc

...will yield:

    build/example/example.a (containing the object files built from src/example/foo.cc and src/example/bar.cc).
    build/example/subexample/subexample.a (containing the object file built from src/example/subexample/qux.cc).

## Binaries

An executable binary is built for each source directory that contains a `main.cc` and/or a `bin.make` file.

A binary is named after its corresponding source path, e.g.

    src/hello_world/main.cc

...will yield:

    build/hello_world/hello_world.a (containing the object file built from src/hello_world/main.cc).
    build/hello_world/hello_world (binary, implicitly linked with build/hello_world/hello_world.a).

Any additional libraries a binary depends on must be explicitly specified in its `bin.make` file.

### bin.make files

A `bin.make` file specifies a binary's additional dependencies via two lists:

- `LIB_DIRS` - list of paths within `my-project/src`.
- `SYSTEM_LIBS` - list of system libraries.

e.g. if `src/hello_world/bin.make` contained:

    LIB_DIRS += example
    LIB_DIRS += example/subexample
    SYSTEM_LIBS += rt

...then `build/hello_world/hello_world` would additionally be linked with the project libraries built from:

- `src/example`
- `src/example/subexample`

And the system library:

- `librt`

## Tests

Any binaries beneath a directory named "test" are executed by the build process.

The standard out/error streams of a test binary are redirected to a log file named after the binary.

A test is expected to return zero on success and non-zero on failure.

A test failure is treated as a build failure (its log file will be printed to standard out).

e.g. the binary produced from:

    src/example/test/main.cc

...would be:

    build/example/test/test

...and its log file would be:

    build/example/test/test.log

## Build targets

Fab provides the following standard targets:

- `all` - builds everything (that needs to be rebuilt) and runs all tests (that need to be re-run).  This is the default target.
- `clean` - removes all build artifacts.

## Configuration

The following Make variables may be overriden via `my-project/config/*.make` files:

- `SRC_DIR` - the name of the directory that contains the project's source code.  The default is `src`.
- `SRC_EXT` - the file name extension used by the project's C++ files.  The default is `cc`.
- `BUILD_DIR` - the directory into which build artifacts are placed.  The default is `build`.
- `CXX` - the compiler.  The default is `g++`.
- `CXXFLAGS` - flags passed to the compiler.  The default flags are `""`.
- `AR` - the archive tool used to create static libraries from objects files.  The default is `ar`.

The following Make variables have no effect on the build artifacts and may be overriden via `my-project/config/*.make` files or via the environment:

- `ECHO_BUILD_MESSAGES` - whether to print out-of-date targets (build artifacts) and their prerequisites that have changed.  The default is `x` (yes).
- `ECHO_RECIPES` - whether to print build recipes.  The default is `""` (no).

## Example configuration and project

Fab includes an example configuration, with the following features:

- Release and debug builds:
  - A release build is built by default (or explicitly with `BUILD=release make`), its artifacts are placed in `build_release`.
  - A debug build is built with `BUILD=debug make`, its artifacts are placed in `build_debug`.
- Compiles using the C++14 standard.
- Almost all warnings enabled.
- Warnings treated as errors.

Fab also includes an example project containing:

- the traditional "hello world" program
- a multilingual "hello world" program, supporting libraries and a test.

## License

Fab is available under the MIT license.  See the LICENSE file for details.

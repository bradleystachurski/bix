# This justfile is designed for use inside a Bitcoin Core source checkout via `nix develop`.

# List available recipes
default:
    @just --justfile {{justfile()}} --list

# Standard build
build:
    cmake -B build && cmake --build build -j$(nproc)
    ln -sf build/compile_commands.json compile_commands.json
    ln -sfn build .active-build

# Dev mode build
build-dev:
    cmake --preset dev-mode && cmake --build build_dev_mode -j$(nproc)
    ln -sf build_dev_mode/compile_commands.json compile_commands.json
    ln -sfn build_dev_mode .active-build

# Debug build
build-debug:
    cmake -B build_debug -DCMAKE_BUILD_TYPE=Debug && cmake --build build_debug -j$(nproc)
    ln -sf build_debug/compile_commands.json compile_commands.json
    ln -sfn build_debug .active-build

# Fuzzer build
build-fuzz:
    cmake --preset libfuzzer && cmake --build build_fuzz -j$(nproc)
    ln -sf build_fuzz/compile_commands.json compile_commands.json
    ln -sfn build_fuzz .active-build

# Rebuild active build without reconfiguring
rebuild:
    cmake --build .active-build -j$(nproc)

# Run unit tests
test-unit:
    ctest --test-dir .active-build -j$(nproc) --output-on-failure

# Run functional tests
test-functional:
    .active-build/test/functional/test_runner.py -j$(nproc)

# Run a single functional test
test-one TEST:
    .active-build/test/functional/test_runner.py {{TEST}}

# Run all tests (unit + functional)
test-all:
    just --justfile {{justfile()}} test-unit
    just --justfile {{justfile()}} test-functional

# Run benchmarks
bench:
    .active-build/bin/bench_bitcoin

# Run linters
lint:
    test/lint/all-lint.py

# Format only changed lines (Bitcoin Core convention)
format:
    git diff -U0 HEAD | python3 contrib/devtools/clang-format-diff.py -p1 -i

# Run fuzzer on a target
fuzz TARGET:
    FUZZ={{TARGET}} build_fuzz/bin/fuzz

# Show ccache statistics
ccache-stats:
    ccache -s

# Clean all build directories
clean:
    rm -rf build build_debug build_dev_mode build_fuzz compile_commands.json .active-build

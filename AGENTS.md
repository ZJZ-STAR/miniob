# Repository Guidelines

## Project Structure & Module Organization
MiniOB’s C++ sources live in `src/`, with `src/observer` hosting the database server entrypoint, SQL pipeline, and storage adapters. Shared utilities sit in `src/common`, client tooling in `src/obclient`, and experimental storage work in `src/oblsm`. GoogleTest suites are kept in `unittest/`; mirror the module layout when adding coverage. SQL regression material lives under `test/` (`test/case` for baseline SQL, `test/integration_test` for the Python harness, `test/sysbench` for load tests). Generated builds stay in `build_debug` or `build_release`, while external dependencies are vendored in `deps/3rd`. Architecture notes, assignments, and ops guides are collected in `docs/`.

## Build, Test, and Development Commands
Run `./build.sh init` once per machine to fetch and install libevent, googletest, benchmark, jsoncpp, and replxx into `deps/3rd/usr/local`. For day-to-day work use `./build.sh debug --make -j8`, which configures CMake into `build_debug` and compiles binaries to `build_debug/bin`. Swap `debug` with `release` for optimized output. Start the server via `build_debug/bin/observer -f etc/observer.ini` and inspect logs in `observer.log.*`. Execute unit tests with `cd build_debug && ctest --output-on-failure`. End-to-end SQL checks use the Python harness: `python3 test/integration_test/libminiob_test.py -c test/integration_test/conf.ini --repo . --no-cleanup --no-compile --player local`, assuming a fresh debug build.

## Coding Style & Naming Conventions
Formatting follows `.clang-format` (LLVM-derived, 2-space indent, 120-column limit, include order preserved, pointer stars on the right). Classes and structs use `CamelCase`; helper functions typically follow lower snake case—align with the surrounding file. Prefer explicit headers, avoid unused includes, and never mix tabs with spaces. Run `clang-format -i` on touched files and keep changes scoped to your patch.

## Testing Guidelines
Add or update GoogleTest cases alongside production code; name tests `<Module>_<Behavior>` so ctest filters work. After compiling, run `ctest` or `ctest -R Observer` for focused suites. Integration SQLs belong in `test/integration_test/test_cases`; update `case_name_mapper.py` if you introduce new categories. Large `sysbench` benchmarks live in `test/sysbench`; coordinate with reviewers before committing long-running scenarios. Document manual SQL scripts (e.g. `simple_drop_test.sql`) when sharing reproduction steps.

## Commit & Pull Request Guidelines
Commits should be focused, with imperative subjects (`fix(build): support GCC 14`, `Update rules for single table views`). Reference GitHub issues via `(#123)` when applicable and note validation steps in the body. Pull requests should summarise scope, highlight risk areas, attach logs or screenshots for user-visible changes, and confirm local test results. Request reviewers who own the affected module and wait for CI to pass before merging.

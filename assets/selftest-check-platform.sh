#!/usr/bin/env sh
# Self-test for check-platform.sh. Mirrors selftest-check-platform.ps1.
# Run: sh selftest-check-platform.sh [path/to/check-platform.sh]
set -u

CHECKER=${1:-$(dirname "$0")/check-platform.sh}
failures=0
tmpdirs=""

new_fixture() {
    FIXTURE=$(mktemp -d) || exit 2
    tmpdirs="$tmpdirs $FIXTURE"
}

set_file() {
    mkdir -p "$(dirname "$1")" || exit 2
    printf '%s\n' "$2" > "$1"
}

run_case() {
    name=$1; root=$2; expected=$3; shift 3
    if env "$@" sh "$CHECKER" "$root" >/dev/null 2>&1; then
        code=0
    else
        code=$?
    fi
    if [ "$code" -eq "$expected" ]; then
        echo "ok: $name"
    else
        echo "FAIL selftest: $name (expected $expected, got $code)"
        failures=$((failures + 1))
    fi
}

trap 'for d in $tmpdirs; do rm -rf "$d"; done' EXIT

sentinel_win='#ifndef _WIN32
#  error wrong platform
#endif'
sentinel_posix='#ifdef _WIN32
#  error wrong platform
#endif'

new_fixture; a=$FIXTURE
set_file "$a/include/api.h" '#pragma once
struct Api {};'
set_file "$a/include/api/platform/handle.h" '#pragma once
#ifdef _WIN32
using SocketHandle = unsigned long long;
#else
using SocketHandle = int;
#endif'
set_file "$a/src/core/impl.cpp" 'int add(int a, int b) { return a + b; }'
set_file "$a/src/adapters/vendor/lib.cpp" '#ifdef _MSC_VER
int v() { return 1; }
#endif'
set_file "$a/src/platform/win32/net.cpp" "$sentinel_win
void netInit() {}"
set_file "$a/src/platform/posix/net.cpp" "$sentinel_posix
void netInit() {}"
run_case 'clean tree passes' "$a" 0

new_fixture; b=$FIXTURE
set_file "$b/include/bad.h" '#pragma once
#include <windows.h>
#ifdef _WIN32
#endif'
run_case 'OS header and platform macro rejected' "$b" 1

new_fixture; e=$FIXTURE
set_file "$e/include/api/platform/handle.h" '#pragma once
#include <windows.h>'
run_case 'OS header in platform header rejected' "$e" 1

new_fixture; f=$FIXTURE
set_file "$f/src/core/impl.cpp" '#ifdef _MSC_VER
int f() { return 1; }
#endif'
run_case 'MSVC macro in core rejected' "$f" 1

new_fixture; g=$FIXTURE
set_file "$g/include/api/platform/extra.h" '#ifdef _WIN32
#endif'
run_case 'only handle.h is platform-aware' "$g" 1

new_fixture; c=$FIXTURE
set_file "$c/src/platform/win32/a.cpp" "$sentinel_win
void a() {}"
set_file "$c/src/platform/win32/b.cpp" "$sentinel_win
void b() {}"
set_file "$c/src/platform/posix/a.cpp" "$sentinel_posix
void a() {}"
run_case 'unpaired platform source rejected' "$c" 1
run_case 'pairing can be skipped' "$c" 0 SKIP_PAIRING=1

new_fixture; d=$FIXTURE
set_file "$d/src/platform/win32/x.cpp" 'void x() {}'
set_file "$d/src/platform/posix/x.cpp" 'void x() {}'
run_case 'missing sentinel rejected' "$d" 1 REQUIRE_SENTINEL=1

if [ "$failures" -gt 0 ]; then
    echo "selftest: $failures failure(s)"
    exit 1
fi
echo 'selftest: OK'
exit 0

#!/usr/bin/env sh
# cpp-enterprise platform rules check (POSIX).
# Synced from the cpp-enterprise skill. Update the skill first, then re-copy.
#
# Env overrides:
#   PLATFORM_DIR, CORE_DIR, INCLUDE_DIR, ADAPTER_DIR, MACRO_EXEMPT,
#   REQUIRE_SENTINEL=1, SKIP_PAIRING=1, REPORT_ONLY=1
set -u

ROOT=$(CDPATH= cd -- "${1:-.}" && pwd) || exit 2
PLATFORM_DIR=${PLATFORM_DIR:-src/platform}
CORE_DIR=${CORE_DIR:-src}
INCLUDE_DIR=${INCLUDE_DIR:-include}
ADAPTER_DIR=${ADAPTER_DIR:-src/adapters}
MACRO_EXEMPT=${MACRO_EXEMPT:-tests}
REQUIRE_SENTINEL=${REQUIRE_SENTINEL:-0}
SKIP_PAIRING=${SKIP_PAIRING:-0}
REPORT_ONLY=${REPORT_ONLY:-0}

findings=$(mktemp) || exit 2
trap 'rm -f "$findings"' EXIT

under() {
    case "$1" in
        "$2"|"$2"/*) return 0 ;;
        *) return 1 ;;
    esac
}

# win32/ and posix/ must expose the same .cpp set; darwin/ may override a subset.
check_pairing() {
    w="$ROOT/$PLATFORM_DIR/win32"; p="$ROOT/$PLATFORM_DIR/posix"; d="$ROOT/$PLATFORM_DIR/darwin"
    if [ -d "$w" ] && [ -d "$p" ]; then
        for f in "$w"/*.cpp; do
            [ -e "$f" ] || continue
            n=${f##*/}
            [ -e "$p/$n" ] || echo "$PLATFORM_DIR/win32/$n: missing pair in posix/" >> "$findings"
        done
        for f in "$p"/*.cpp; do
            [ -e "$f" ] || continue
            n=${f##*/}
            [ -e "$w/$n" ] || echo "$PLATFORM_DIR/posix/$n: missing pair in win32/" >> "$findings"
        done
    fi
    if [ -d "$d" ]; then
        for f in "$d"/*.cpp; do
            [ -e "$f" ] || continue
            n=${f##*/}
            [ -e "$p/$n" ] || echo "$PLATFORM_DIR/darwin/$n: no matching posix source" >> "$findings"
        done
    fi
}

if [ "$SKIP_PAIRING" -ne 1 ]; then
    check_pairing
fi

find "$ROOT" -type f \( \
        -name '*.h' -o -name '*.hpp' -o -name '*.hh' -o -name '*.hxx' -o \
        -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cxx' -o \
        -name '*.inl' -o -name '*.ipp' \) \
    -not -path '*/.git/*' -not -path '*/build/*' -not -path '*/bin/*' \
    -not -path '*/obj/*' -not -path '*/out/*' -not -path '*/node_modules/*' \
    -not -path '*/third_party/*' -not -path '*/vendor/*' -not -path '*/external/*' \
    -not -path '*/_deps/*' |
while IFS= read -r f; do
    rel=${f#"$ROOT"/}

    is_platform=0; under "$rel" "$PLATFORM_DIR" && is_platform=1
    is_adapter=0;  under "$rel" "$ADAPTER_DIR"  && is_adapter=1
    is_platform_header=0
    case "$rel" in
        include/*/platform/handle.h|include/platform/handle.h) is_platform_header=1 ;;
    esac
    is_exempt=0
    for d in $MACRO_EXEMPT; do under "$rel" "$d" && is_exempt=1; done

    if [ "$is_platform" -eq 0 ] && [ "$is_adapter" -eq 0 ] && [ "$is_exempt" -eq 0 ]; then
        grep -nEi '#[[:space:]]*include[[:space:]]*[<"](windows\.h|winsock2\.h|ws2tcpip\.h|unistd\.h|pthread\.h|dlfcn\.h|io\.h|direct\.h|process\.h|tchar\.h|netdb\.h|poll\.h|syslog\.h|termios\.h|sys/|netinet/|arpa/|mach/|linux/|android/)' "$f" \
            | sed "s|^\([0-9][0-9]*\):|$rel:\1: OS header in portable code: |" >> "$findings" || true
    fi

    if [ "$is_platform" -eq 0 ] && [ "$is_adapter" -eq 0 ] && [ "$is_platform_header" -eq 0 ] && [ "$is_exempt" -eq 0 ]; then
        grep -nE '(_WIN32|_WIN64|_MSC_VER|__linux__|__linux|__unix__|__unix|__APPLE__|__MACH__|__FreeBSD__|__CYGWIN__|__ANDROID__|_POSIX_VERSION)' "$f" \
            | sed "s|^\([0-9][0-9]*\):|$rel:\1: platform macro outside platform layer: |" >> "$findings" || true
    fi

    in_public=0; under "$rel" "$INCLUDE_DIR" && in_public=1
    in_core=0;   under "$rel" "$CORE_DIR" && [ "$is_adapter" -eq 0 ] && in_core=1
    if [ "$is_platform" -eq 0 ] && { [ "$in_public" -eq 1 ] || [ "$in_core" -eq 1 ]; }; then
        grep -nE 'platform/(win32|posix|darwin)/' "$f" \
            | sed "s|^\([0-9][0-9]*\):|$rel:\1: dependency on a concrete platform backend: |" >> "$findings" || true
    fi

    if [ "$REQUIRE_SENTINEL" -eq 1 ] && [ "$is_platform" -eq 1 ] && ! under "$rel" "$PLATFORM_DIR/common"; then
        grep -qE '#[[:space:]]*error' "$f" || echo "$rel: missing sentinel #error" >> "$findings"
    fi
done

count=$(wc -l < "$findings" | tr -d ' ')
if [ "$count" -eq 0 ]; then
    echo "platform checks: OK"
    exit 0
fi

sed 's/^/FAIL /' "$findings"
echo "platform checks: $count finding(s)"
if [ "$REPORT_ONLY" -eq 1 ]; then
    echo "report-only mode: exit 0"
    exit 0
fi
exit 1

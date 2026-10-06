#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "SunOS" ]]; then
  cat <<EOF
Usage: ./refresh-illumos-sysroot.sh

Must be run on an illumos machine. OmniOS LTS is recommended.
EOF
  exit 1
fi

SYSROOT="./illumos-x86_64"
GCC_LIB_DIR=$(dirname "$(readlink -f /usr/lib/amd64/libgcc_s.so.1)")

echo "Sysroot: $SYSROOT"

rm -rf "${SYSROOT:?}"
mkdir -p "$SYSROOT"

gtar -C / -cf - \
    usr/include \
    lib/amd64 \
    usr/lib/amd64 \
    "${GCC_LIB_DIR#/}" \
  | gtar -xf - -C "$SYSROOT"

# Clang also needs GCC's startup objects, which live outside the system library
# directories. Copy them into its sysroot search path so a host GCC installation
# is not required when cross-compiling.
for name in crtbegin.o crtend.o crtbeginS.o crtendS.o; do
  object=$("${GCC:-gcc}" -m64 -print-file-name="$name")
  if [[ ! -f "$object" ]]; then
    echo "Cannot find GCC startup object: $name" >&2
    exit 1
  fi
  cp "$object" "$SYSROOT/usr/lib/amd64/$name"
done

echo "Sysroot refresh complete: $SYSROOT"

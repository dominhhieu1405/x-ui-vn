#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${ROOT_DIR}/dist"
TMP_DIR="${ROOT_DIR}/.build-release"
APP_NAME="x-ui"

ARCHES=("$@")
if [ ${#ARCHES[@]} -eq 0 ]; then
  ARCHES=(amd64 arm64)
fi

required_files=(
  "main.go"
  "x-ui.sh"
  "x-ui.service"
  "config/name"
  "config/version"
  "bin/geoip.dat"
  "bin/geosite.dat"
)

for f in "${required_files[@]}"; do
  if [ ! -f "${ROOT_DIR}/${f}" ]; then
    echo "Missing required file: ${f}" >&2
    exit 1
  fi
done

mkdir -p "${OUT_DIR}"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

copy_runtime_files() {
  local dst="$1"
  mkdir -p "${dst}/bin"

  cp -r "${ROOT_DIR}/config" "${dst}/"
  cp -r "${ROOT_DIR}/web" "${dst}/"
  cp "${ROOT_DIR}/x-ui.sh" "${dst}/"
  cp "${ROOT_DIR}/x-ui.service" "${dst}/"
  cp "${ROOT_DIR}/LICENSE" "${dst}/"
  cp "${ROOT_DIR}/README.md" "${dst}/"
  cp "${ROOT_DIR}/bin/geoip.dat" "${dst}/bin/"
  cp "${ROOT_DIR}/bin/geosite.dat" "${dst}/bin/"
}

for arch in "${ARCHES[@]}"; do
  if [ ! -f "${ROOT_DIR}/bin/xray-linux-${arch}" ]; then
    echo "Missing xray binary for architecture: ${arch} (expected bin/xray-linux-${arch})" >&2
    exit 1
  fi

  pkg_root="${TMP_DIR}/${APP_NAME}-${arch}/${APP_NAME}"
  mkdir -p "${pkg_root}"
  copy_runtime_files "${pkg_root}"

  echo "Building ${APP_NAME} for linux/${arch}..."
  CGO_ENABLED=0 GOOS=linux GOARCH="${arch}" \
    go build -trimpath -ldflags='-s -w' -o "${pkg_root}/${APP_NAME}" "${ROOT_DIR}"

  cp "${ROOT_DIR}/bin/xray-linux-${arch}" "${pkg_root}/bin/"
  chmod +x "${pkg_root}/${APP_NAME}" "${pkg_root}/x-ui.sh" "${pkg_root}/bin/xray-linux-${arch}"

  tarball="${OUT_DIR}/${APP_NAME}-linux-${arch}.tar.gz"
  tar -C "${TMP_DIR}/${APP_NAME}-${arch}" -czf "${tarball}" "${APP_NAME}"
  echo "Created: ${tarball}"
done

echo "Done. Output directory: ${OUT_DIR}"

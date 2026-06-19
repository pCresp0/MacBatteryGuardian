#!/usr/bin/env bash
# build-dmg.sh
# Compila MacBatteryGuardian en Release y genera un .dmg listo para distribuir.
#
# Uso:
#   ./scripts/build-dmg.sh
#   SIGN_IDENTITY="Developer ID Application: Tu Nombre (TEAMID)" ./scripts/build-dmg.sh
#   NOTARIZE=1 APPLE_ID=... APP_PASSWORD=... TEAM_ID=... ./scripts/build-dmg.sh
#
# Requisitos: Xcode 16+, xcodegen (brew install xcodegen)

set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="MacBatteryGuardian"
CONFIGURATION="${CONFIGURATION:-Release}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
STAGING_DIR="$DIST_DIR/dmg-staging"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"

cd "$ROOT_DIR"

echo "▸ Generando proyecto Xcode…"
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
else
  echo "⚠ xcodegen no encontrado; usando MacBatteryGuardian.xcodeproj existente"
fi

echo "▸ Compilando $SCHEME ($CONFIGURATION)…"
xcodebuild \
  -project MacBatteryGuardian.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_STYLE=Automatic \
  build

APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/MacBatteryGuardian.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ No se encontró $APP_PATH"
  exit 1
fi

VERSION="$(
  /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
    "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "1.0.0"
)"
BUILD="$(
  /usr/libexec/PlistBuddy -c "Print CFBundleVersion" \
    "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "1"
)"
DMG_NAME="MacBatteryGuardian-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

extract_sign_identity() {
  local pattern="$1"
  local line
  line="$(security find-identity -v -p codesigning 2>/dev/null | grep "$pattern" | head -1 || true)"
  if [[ -n "$line" ]]; then
    awk -F'"' '{print $2}' <<< "$line"
  fi
}

# Firma (opcional pero recomendada)
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(extract_sign_identity 'Developer ID Application')"
fi
if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(extract_sign_identity 'Apple Development')"
fi

WORK_APP="$STAGING_DIR/MacBatteryGuardian.app"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$WORK_APP"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "▸ Firmando con: $SIGN_IDENTITY"
  codesign --force --deep --sign "$SIGN_IDENTITY" --options runtime "$WORK_APP"
  codesign --verify --deep --strict "$WORK_APP"
else
  echo "⚠ Sin certificado de firma; el .dmg funcionará solo en tu Mac con advertencias de Gatekeeper"
fi

ln -sf /Applications "$STAGING_DIR/Applications"

echo "▸ Creando DMG…"
mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "MacBatteryGuardian" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH" 2>/dev/null || true
fi

# Notarización opcional (Developer ID + contraseña de app específica)
if [[ "${NOTARIZE:-0}" == "1" ]]; then
  : "${APPLE_ID:?Falta APPLE_ID}"
  : "${APP_PASSWORD:?Falta APP_PASSWORD (app-specific password)}"
  : "${TEAM_ID:?Falta TEAM_ID}"

  echo "▸ Enviando a notarización…"
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APP_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

  echo "▸ Grapando ticket de notarización…"
  xcrun stapler staple "$DMG_PATH"
fi

rm -rf "$STAGING_DIR"

echo ""
echo "✓ Listo: $DMG_PATH"
echo "  Versión: $VERSION ($BUILD)"
if [[ -z "${SIGN_IDENTITY:-}" ]]; then
  echo ""
  echo "  Para distribución pública necesitas:"
  echo "  1. Certificado 'Developer ID Application' en developer.apple.com"
  echo "  2. SIGN_IDENTITY=\"Developer ID Application: …\" ./scripts/build-dmg.sh"
  echo "  3. NOTARIZE=1 APPLE_ID=… APP_PASSWORD=… TEAM_ID=… ./scripts/build-dmg.sh"
elif [[ "${NOTARIZE:-0}" != "1" ]]; then
  echo ""
  echo "  Siguiente paso recomendado: notarizar el DMG para que macOS no lo bloquee."
  echo "  NOTARIZE=1 APPLE_ID=… APP_PASSWORD=… TEAM_ID=7699A9R89R ./scripts/build-dmg.sh"
fi

#!/usr/bin/env bash
# X-Seti - Jun 2026 - Global Player - Version updater
# Usage: ./set_version.sh 3.3.1

set -euo pipefail

NEW_VER="${1:-}"
if [ -z "$NEW_VER" ]; then
    echo "Usage: $0 <version>  e.g. $0 3.3.1"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Setting Global Player version to $NEW_VER ..."

# install.sh - header comment and APP_VER variable
sed -i "s/^# X-Seti - GlobalPlayer [0-9.]*/# X-Seti - GlobalPlayer ${NEW_VER}/" "$SCRIPT_DIR/install.sh"
sed -i "s/^APP_VER=.*/APP_VER=\"${NEW_VER}\"/" "$SCRIPT_DIR/install.sh"

# uninstall.sh
sed -i "s/Global Player v[0-9.]*/Global Player v${NEW_VER}/g" "$SCRIPT_DIR/uninstall.sh"

# support/install_fixed.sh
sed -i "s/GlobalPlayer [0-9.]*/GlobalPlayer ${NEW_VER}/" "$SCRIPT_DIR/support/install_fixed.sh"
sed -i "s/Global Player v[0-9.]*/Global Player v${NEW_VER}/g" "$SCRIPT_DIR/support/install_fixed.sh"

# metadata files
sed -i "s/X-KDE-PluginInfo-Version=.*/X-KDE-PluginInfo-Version=${NEW_VER}/" "$SCRIPT_DIR/org.mooheda.globalplayer/v5/metadata.desktop"
sed -i "s/X-KDE-PluginInfo-Version=.*/X-KDE-PluginInfo-Version=${NEW_VER}/" "$SCRIPT_DIR/org.mooheda.globalplayer/v6/metadata.desktop"
sed -i "s/\"Version\": \"[0-9.]*\"/\"Version\": \"${NEW_VER}\"/" "$SCRIPT_DIR/org.mooheda.globalplayer/v6/metadata.json"

# QML - App_Vers property
sed -i "s/readonly property string App_Vers: \"[0-9.]*\"/readonly property string App_Vers: \"${NEW_VER}\"/" "$SCRIPT_DIR/plasma6_4_main.qml"

echo "Done. Files updated:"
grep -rn "3\.\|APP_VER\|App_Vers\|PluginInfo-Version" "$SCRIPT_DIR" \
    --include="*.sh" --include="*.qml" --include="*.json" --include="*.desktop" \
    | grep -E "(APP_VER=|App_Vers:|PluginInfo-Version=|${NEW_VER})" \
    | grep -v ".git"

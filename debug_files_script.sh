#!/usr/bin/env bash
# Debug script to find all QML files

echo "=== Global Player File Debug ==="
echo "Current directory: $(pwd)"
echo

echo "=== Looking for main.qml files ==="
find . -name "main*.qml" -type f | while read file; do
    echo "Found: $file"
    echo "  Size: $(wc -l < "$file") lines"
    echo "  Contains PlasmaExtras: $(grep -c "PlasmaExtras" "$file" 2>/dev/null || echo "0")"
    echo "  First import line: $(head -10 "$file" | grep "import" | head -1)"
    echo
done

echo "=== Directory structure ==="
tree -a org.mooheda.globalplayer/ 2>/dev/null || find org.mooheda.globalplayer/ -type f

echo

echo "=== Check installed widget ==="
INSTALLED_PATH="$HOME/.local/share/plasma/plasmoids/org.mooheda.globalplayer/contents/ui/main.qml"
if [ -f "$INSTALLED_PATH" ]; then
    echo "Installed file exists: $INSTALLED_PATH"
    echo "  Size: $(wc -l < "$INSTALLED_PATH") lines"
    echo "  Contains PlasmaExtras: $(grep -c "PlasmaExtras" "$INSTALLED_PATH" 2>/dev/null || echo "0")"
    echo "  First 10 lines:"
    head -10 "$INSTALLED_PATH"
else
    echo "No installed widget found at: $INSTALLED_PATH"
fi
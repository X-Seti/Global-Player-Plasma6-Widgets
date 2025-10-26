#!/bin/bash
# Patch script to fix plasma6_4_main.qml to use Python D-Bus instead of qdbus

TARGET_FILE="$1"

if [ -z "$TARGET_FILE" ]; then
    echo "Usage: $0 <path-to-plasma6_4_main.qml>"
    echo ""
    echo "Examples:"
    echo "  $0 ./plasma6_4_main.qml"
    echo "  $0 ~/.local/share/plasma/plasmoids/org.mooheda.globalplayer/contents/ui/main.qml"
    exit 1
fi

if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: File not found: $TARGET_FILE"
    exit 1
fi

echo "Backing up $TARGET_FILE to ${TARGET_FILE}.backup"
cp "$TARGET_FILE" "${TARGET_FILE}.backup"

echo "Patching qdbusCall function to use Python D-Bus..."

# Create the new function
cat > /tmp/new_qdbusCall.txt << 'EOF'
    function qdbusCall(method, args) {
        // Use Python D-Bus instead of qdbus command (works on all systems)
        var pythonCmd = "/usr/bin/python3 -c \""
        pythonCmd += "import dbus, json, sys; "
        pythonCmd += "bus = dbus.SessionBus(); "
        pythonCmd += "obj = bus.get_object('org.mooheda.gpd', '/org/mooheda/gpd'); "
        pythonCmd += "iface = dbus.Interface(obj, 'org.mooheda.gpd1'); "
        
        if (args && args.length > 0) {
            // Method with arguments
            var escapedArgs = []
            for (var i = 0; i < args.length; ++i) {
                var a = ("" + args[i]).replace(/'/g, "\\\\'")
                escapedArgs.push("'" + a + "'")
            }
            pythonCmd += "result = iface." + method + "(" + escapedArgs.join(", ") + "); "
        } else {
            // Method without arguments
            pythonCmd += "result = iface." + method + "(); "
        }
        
        pythonCmd += "print(str(result))"
        pythonCmd += "\""
        
        console.log("D-Bus call (Python):", method, args || "")
        execDS.connectSource(pythonCmd)
    }
EOF

# Use awk to replace the function
awk '
/^[[:space:]]*function qdbusCall\(method, args\) \{/ {
    in_function = 1
    # Print the new function
    while ((getline line < "/tmp/new_qdbusCall.txt") > 0) {
        print line
    }
    close("/tmp/new_qdbusCall.txt")
    next
}
in_function == 1 && /^[[:space:]]*\}[[:space:]]*$/ {
    in_function = 0
    next
}
in_function == 0 {
    print
}
' "$TARGET_FILE" > "${TARGET_FILE}.patched"

# Replace original with patched
mv "${TARGET_FILE}.patched" "$TARGET_FILE"

# Clean up
rm -f /tmp/new_qdbusCall.txt

echo "✅ Patching complete!"
echo ""
echo "Backup saved to: ${TARGET_FILE}.backup"
echo "Patched file: $TARGET_FILE"
echo ""
echo "Next steps:"
echo "  1. Copy to Plasma: cp $TARGET_FILE ~/.local/share/plasma/plasmoids/org.mooheda.globalplayer/contents/ui/main.qml"
echo "  2. Restart Plasma: kquitapp6 plasmashell && kstart plasmashell"
echo "  3. Add widget to panel"

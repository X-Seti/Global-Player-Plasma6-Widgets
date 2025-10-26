#!/bin/bash
# qdbus wrapper for systems without qdbus (like Orange Pi)
# Usage: qdbus-wrapper.sh org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Method [args...]

SERVICE="$1"
PATH="$2"
METHOD="$3"
shift 3
ARGS=("$@")

# Try native qdbus first
if command -v qdbus >/dev/null 2>&1; then
    qdbus "$SERVICE" "$PATH" "$METHOD" "${ARGS[@]}"
    exit $?
fi

# Try qdbus6
if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 "$SERVICE" "$PATH" "$METHOD" "${ARGS[@]}"
    exit $?
fi

# Fallback to Python D-Bus
python3 << PYEOF
import dbus
import sys
import json

try:
    bus = dbus.SessionBus()
    obj = bus.get_object('${SERVICE}', '${PATH}')
    
    # Extract interface and method name
    interface = '${METHOD}'.rsplit('.', 1)[0]
    method = '${METHOD}'.rsplit('.', 1)[1]
    
    iface = dbus.Interface(obj, interface)
    method_func = getattr(iface, method)
    
    # Call with args if provided
    args = []
$(for arg in "${ARGS[@]}"; do
    echo "    args.append('$arg')"
done)
    
    if args:
        result = method_func(*args)
    else:
        result = method_func()
    
    # Handle different return types
    if isinstance(result, (dbus.String, str)):
        print(str(result))
    elif isinstance(result, (list, tuple)):
        print(json.dumps([str(x) for x in result]))
    elif isinstance(result, dict):
        print(json.dumps({str(k): str(v) for k, v in result.items()}))
    else:
        print(str(result))
    
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

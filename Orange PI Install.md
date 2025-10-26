# Orange Pi / ARM Systems Without qdbus - Installation Guide

## Problem

On some ARM systems like Orange Pi, the `qdbus` command is not available or doesn't work properly. The Global Player widget uses `qdbus` to communicate with the daemon via D-Bus.

## Solution

Install the `qdbus-wrapper.sh` helper script that uses Python D-Bus as a fallback.

## Installation Steps

### 1. Install the wrapper script

```bash
# Copy the wrapper to your home directory
cp qdbus-wrapper.sh ~/qdbus-wrapper.sh
chmod +x ~/qdbus-wrapper.sh
```

### 2. Create a qdbus symlink

```bash
# Create a local bin directory if it doesn't exist
mkdir -p ~/.local/bin

# Create symlink named 'qdbus' pointing to our wrapper
ln -sf ~/qdbus-wrapper.sh ~/.local/bin/qdbus

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
fi
```

### 3. Verify it works

```bash
# Test the wrapper
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations
```

You should see the list of 25 UK stations as a JSON array.

### 4. Restart Plasma

```bash
kquitapp6 plasmashell && kstart plasmashell
```

### 5. Add the widget

1. Right-click panel → Add Widgets
2. Search "Global Player"
3. Add to panel

The widget should now connect and show all stations!

## How It Works

The wrapper script:
1. First tries to use native `qdbus` if available
2. Falls back to `qdbus6` if available  
3. Finally uses Python D-Bus as last resort

This makes the widget work on:
- ✅ Regular x86/x64 systems with qdbus
- ✅ ARM systems without qdbus (Orange Pi, Raspberry Pi, etc.)
- ✅ Any system with Python and python3-dbus installed

## Troubleshooting

### Wrapper not being called

Check PATH:
```bash
echo $PATH
which qdbus
```

Should show: `/home/x2/.local/bin/qdbus`

### Still getting qdbus errors

Make sure the symlink is correct:
```bash
ls -la ~/.local/bin/qdbus
# Should show: qdbus -> /home/x2/qdbus-wrapper.sh
```

### Python D-Bus errors

Ensure python3-dbus is installed:
```bash
python3 -c "import dbus; print('OK')"
```

If that fails:
```bash
sudo apt install python3-dbus python3-gi  # Debian/Ubuntu
sudo pacman -S python-dbus python-gobject  # Arch
```

## Testing the Wrapper Manually

```bash
# Get stations
~/qdbus-wrapper.sh org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations

# Get state  
~/qdbus-wrapper.sh org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetState

# Play a station
~/qdbus-wrapper.sh org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Play "Classic FM"
```

All commands should work and return proper JSON responses.

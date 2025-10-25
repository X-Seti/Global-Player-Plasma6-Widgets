#!/usr/bin/env bash
# Quick Fix Script for Global Player Plasma 6.4
# Applies all fixes automatically

set -euo pipefail

echo "🔧 Global Player Plasma 6.4 Quick Fix"
echo "====================================="
echo ""

# Check if we're in the right directory
if [ ! -f "install.sh" ] || [ ! -d "globalplayer-daemon" ]; then
    echo "❌ Error: Please run this script from the Global Player directory"
    echo "   (The directory containing install.sh and globalplayer-daemon/)"
    exit 1
fi

echo "[1/5] Backing up current files..."
if [ -f "install.sh" ]; then
    cp install.sh install.sh.backup
    echo "    ✓ Backed up install.sh"
fi

if [ -f "plasma6_main_qml" ]; then
    cp plasma6_main_qml plasma6_main_qml.backup
    echo "    ✓ Backed up plasma6_main_qml"
fi

echo ""
echo "[2/5] Downloading fixed files..."

# In a real scenario, you'd download from GitHub or have the files
# For now, we'll check if the fixed files are present
if [ ! -f "/home/claude/install_fixed.sh" ]; then
    echo "❌ Error: Fixed files not found"
    echo "   Please ensure install_fixed.sh, plasma6_4_main.qml, and diagnose.sh are available"
    exit 1
fi

echo ""
echo "[3/5] Applying fixes..."

# Copy fixed install script
cp /home/claude/install_fixed.sh ./install.sh
chmod +x install.sh
echo "    ✓ Updated install.sh with Plasma 6.4 detection"

# Copy fixed QML
cp /home/claude/plasma6_4_main.qml ./plasma6_main_qml
echo "    ✓ Updated QML with connection retry logic"

# Copy diagnostic script
cp /home/claude/diagnose.sh ./diagnose.sh
chmod +x diagnose.sh
echo "    ✓ Added diagnostic script"

echo ""
echo "[4/5] Stopping existing services..."
systemctl --user stop gpd.service 2>/dev/null || true
echo "    ✓ Stopped daemon service"

echo ""
echo "[5/5] Running installation..."
echo ""

# Run the fixed installer
./install.sh

echo ""
echo "✅ Quick fix complete!"
echo ""
echo "📊 Running diagnostics..."
echo ""

# Wait for services to start
sleep 3

# Run diagnostic
./diagnose.sh

echo ""
echo "💡 Next Steps:"
echo "   1. Check diagnostic output above for any remaining issues"
echo "   2. Add the widget: Right-click panel → Add Widgets → 'Global Player'"
echo "   3. If issues persist, check: journalctl --user -u gpd.service -f"
echo ""
echo "   Original files backed up with .backup extension"

#!/bin/bash

echo "=== Chrome Desktop Integration Verification ==="
echo ""

# Check if optimized launcher exists
if [ -f "/home/sri/chromium-optimized" ]; then
    echo "✅ Optimized Chromium launcher found: /home/sri/chromium-optimized"
    if [ -x "/home/sri/chromium-optimized" ]; then
        echo "✅ Launcher is executable"
    else
        echo "❌ Launcher is not executable"
        chmod +x /home/sri/chromium-optimized
        echo "✅ Fixed: Made launcher executable"
    fi
else
    echo "❌ Optimized launcher not found"
    echo "   Run: ./chrome_optimize.sh to create it"
fi

echo ""

# Check desktop file
if [ -f "/home/sri/.local/share/applications/chromium.desktop" ]; then
    echo "✅ Custom desktop file found"
    
    # Check if it points to our optimized launcher
    if grep -q "/home/sri/chromium-optimized" ~/.local/share/applications/chromium.desktop; then
        echo "✅ Desktop file points to optimized launcher"
    else
        echo "❌ Desktop file doesn't point to optimized launcher"
    fi
    
    # Show the exec line
    echo "   Exec line: $(grep '^Exec=' ~/.local/share/applications/chromium.desktop)"
else
    echo "❌ Custom desktop file not found"
fi

echo ""

# Check default application
DEFAULT_BROWSER=$(xdg-settings get default-web-browser 2>/dev/null || echo "Not set")
echo "🌐 Default web browser: $DEFAULT_BROWSER"

echo ""
echo "📋 Quick Actions:"
echo "• Test optimized launcher: ./chromium-optimized"
echo "• Set as default browser: xdg-settings set default-web-browser chromium.desktop"
echo "• Monitor memory usage: ./chrome_monitor.sh"
echo "• View desktop file: cat ~/.local/share/applications/chromium.desktop"

echo ""
echo "🎯 Next Steps:"
echo "1. Close any running Chromium instances"
echo "2. Launch Chromium from Applications menu → Internet → Chromium Web Browser (Optimized)"
echo "3. Verify it's using optimized settings with chrome://version"
echo "4. Monitor performance with './chrome_monitor.sh'"
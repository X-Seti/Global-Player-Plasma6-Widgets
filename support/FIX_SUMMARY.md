# Global Player - Change Log - X-Seti

---

## Jun 13 2026 - v3.3.0 - Plasma 6.6 Session

### Files changed
- plasma6_4_main.qml
- plasma6_6_main.qml (new - copy of 6.4, dev sandbox)
- install.sh (added option 5 for Plasma 6.6)
- reload.sh (new - fast dev deploy script, requires explicit 64|66 arg)
- set_version.sh (new - updates version in all files at once)
- README.md
- support/FIX_SUMMARY.md

### Fixes - plasma6_4_main.qml
Song list was offset right: nested ListView inside outer ListView removed, collapsed to single ListView.
Play without Refresh failing: playCurrent() now auto-calls refreshStations() if model empty, defers play via Qt.callLater.
Qt.callLater misuse: onExpandedChanged used Qt.callLater(fn, 500) - delay arg not supported in QML. Replaced with expandTimer (300ms).
White box over song list: song history Rectangle color was PlasmaCore.Theme.backgroundColor + opacity 0.8. Changed to transparent.
Artwork box invisible: complementaryBackgroundColor blended into theme. Changed to backgroundColor with highlightColor border.
Artwork box collapsing: RowLayout had no Layout.preferredHeight. Added preferredHeight and minimumHeight. Removed conflicting bare width/height vs Layout.* properties.
ComboBox breaking layout: textRole: "name" on plain string array caused ComboBox to render blank and collapse ColumnLayout. Removed textRole.
VU meter invisible: height set as bare property ignored by ColumnLayout. Added Layout.preferredHeight and Layout.minimumHeight.
fullRepresentation no real size: Layout.preferredWidth/Height ignored on desktop widget (no parent layout). Added bare width/height.
Unicode symbols: replaced all unicode transport/status symbols with Kirigami.Icon system icons.
Version label added: "Global Player v3.3" shown right-aligned in Recently Played header.

### TODO
- Artwork not showing in panel popup (artworkPath not returned by daemon in most cases)
- VU meter visibility still unconfirmed on all setups
- Artwork left panel still not visible in some Plasma configurations
- mediaMode not implemented (stub only)
- Favorite button not wired to any backend
- SetPlayDelay not implemented in daemon
- Song history station column alignment

---

## Oct 2025 - v3.2.3 - Plasma 6.4 Session

### Fixes
Plasma version detection failing: install.sh checked kquitapp5 before kquitapp6. Rewritten with multi-method detection using plasmashell --version first.
D-Bus connection silent failure: no feedback when daemon not running. Added 10-attempt startup timer, error banner, Retry button.
Station list not loading: stations loaded but not displayed. Fixed onNewData source name matching and JSON parse error handling.
QML imports: updated to current Plasma 6 standards.

### Files added
- diagnose.sh
- support/install_fixed.sh
- support/quick_fix.sh
- support/PLASMA_6.4.md

---

## Aug 2025 - v3.2.0 - Initial Plasma 6 port

Original plasma5_main_qml ported to Plasma 6. Basic D-Bus integration via Plasma5Support.DataSource. Regional station presets (UK, USA, Canada, Germany, Spain, Italy).

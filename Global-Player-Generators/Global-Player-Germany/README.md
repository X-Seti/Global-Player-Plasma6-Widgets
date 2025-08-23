# 🇩🇪 Global Player Deutschland - Plasma 6 Widget

Ein KDE Plasma 6 Widget für deutsche Radiosender mit Album-Artwork und Benachrichtigungen.

## 📻 Deutsche Radiosender

### Öffentlich-Rechtliche
- **1LIVE** - WDR Jugendwelle
- **WDR 2** - Rheinland Regionalprogramm
- **Bayern 3** - Bayerischer Rundfunk Pop/Rock
- **SWR3** - Südwestrundfunk Pop
- **NDR 2** - Norddeutscher Rundfunk
- **HR3** - Hessischer Rundfunk
- **MDR Jump** - Mitteldeutscher Rundfunk Jugendwelle
- **Radio Fritz** - rbb Jugendwelle Berlin/Brandenburg

### Öffentliche Information
- **Deutschlandfunk** - Nachrichten und Information
- **Deutschlandfunk Nova** - Junges Informationsprogramm

### Private Sender
- **Antenne Bayern** - Bayern privat
- **Radio Hamburg** - Hamburg regional
- **89.0 RTL** - Hit-Radio
- **Energy Berlin** - Dance und Charts
- **BigFM** - Hit-Radio bundesweit

### Spezial-Sender
- **Klassik Radio** - Klassische Musik
- **Radio Bob** - Rock und Metal
- **Rock Antenne** - Rock-Musik

## ✨ Features
- 🎨 **Album-Artwork** im Panel-Icon und Benachrichtigungen
- 🔔 **Desktop-Benachrichtigungen** bei Song-Wechsel
- 🇩🇪 **Deutsche Lokalisierung** mit deutscher Flagge und Gold-Akzenten
- 🎛️ **Mausrad-Steuerung** für Senderwechsel im Panel
- 📝 **Logging** der gespielten Tracks
- 🌍 **Funktioniert global** - keine Geo-Beschränkungen

## 🚀 Installation

1. **Abhängigkeiten installieren**:
   ```bash
   # Arch Linux
   sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests
   
   # Ubuntu/Debian
   sudo apt install mpv qt6-base-dev python3-dbus python3-gi python3-requests
   
   # Fedora
   sudo dnf install mpv qt6-qtbase-devel python3-dbus python3-gobject python3-requests
   ```

2. **Widget installieren**:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Zum Panel hinzufügen**: Rechtsklick Panel → Widgets hinzufügen → "Global Player Deutschland"

## 🔧 Technische Details
- **D-Bus Service**: `org.mooheda.gpd.germany`
- **Konfiguration**: `~/.config/globalplayer-germany/`
- **Cache**: `~/.cache/globalplayer-germany/`
- **Logs**: `~/globalplayer/gp-germany.logs`

## 🛠️ Fehlerbehebung
- **Service Status**: `systemctl --user status gpd-germany.service`
- **Logs anzeigen**: `journalctl --user -u gpd-germany.service -f`
- **Plasma neustarten**: `systemctl --user restart plasma-plasmashell.service`

## 📜 Version
v3.2 Deutschland - Plasma 6 Kompatibel
Erstellt von X-Seti (Mooheda) - August 2025

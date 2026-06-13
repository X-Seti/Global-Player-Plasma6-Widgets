# Global Player - Plasma 6.4 Notes - X-Seti - Jun 2026

## What changed from Plasma 6.0

plasma6_4_main.qml replaces plasma6_main_qml for Plasma 6.4+ systems.

Key differences from the 6.0 file: Kirigami icons replace unicode symbols, ScrollView removed (not available in Plasma 6.4), ListView with clip used instead, D-Bus connection retry logic added, error banner added.

## D-Bus interface

Service: org.mooheda.gpd
Path: /org/mooheda/gpd
Interface: org.mooheda.gpd1

Methods available on the daemon:
- GetState - returns JSON with state, station, logging, volume, notifications
- GetStations - returns JSON array of station name strings
- GetNowPlaying - returns JSON with artist, title, show, state, artworkPath
- Play (station name) - start playing named station
- Pause - pause/stop playback
- Resume - resume playback
- SetVolume (int) - set volume 0-100
- GetVolume - returns current volume
- SetLogging (bool) - enable/disable logging
- SetNotifications (string) - enable/disable notifications
- SignIn - opens web login window

Not implemented in daemon (do not call): Ping, SetPlayDelay

## Testing D-Bus manually

```bash
# Check daemon is running
systemctl --user status gpd.service

# List stations
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations

# Get state
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetState

# Play a station
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Play "Capital UK"

# Get now playing
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetNowPlaying
```

## Known issues

The connection test calls GetState (not a Ping method which does not exist). If GetState returns valid JSON the daemon is considered connected.

artworkPath in GetNowPlaying is only populated when the iTunes search finds a match for the current artist/title. Most stations will return an empty artworkPath.

## Plasma cache

If changes to main.qml are not picked up after reload.sh, clear the cache:

```bash
rm -rf ~/.cache/plasma* ~/.cache/plasmashell
./reload.sh 64
```

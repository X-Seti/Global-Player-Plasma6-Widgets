#!/usr/bin/env python3
# Global Player Hotkey Daemon
# X-Seti - Global System Hotkeys for Global Player

import os
import sys
import time
import threading
import subprocess
import dbus
from pynput import keyboard
from pynput.keyboard import Key, Listener

class GlobalPlayerHotkeys:
    def __init__(self):
        self.bus = dbus.SessionBus()
        self.daemon_proxy = None
        self.connect_to_daemon()
        self.media_keys_registered = False
        
    def connect_to_daemon(self):
        """Connect to the Global Player daemon via D-Bus"""
        try:
            self.daemon_proxy = self.bus.get_object("org.mooheda.gpd", "/org/mooheda/gpd")
            print("✓ Connected to Global Player daemon")
            return True
        except Exception as e:
            print(f"❌ Could not connect to daemon: {e}")
            return False
    
    def register_media_keys(self):
        """Register with MPRIS2 to capture media keys"""
        try:
            # Create MPRIS2 interface for Global Player
            mpris_script = '''
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

class GlobalPlayerMPRIS(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, '/org/mpris/MediaPlayer2')
    
    @dbus.service.method('org.mpris.MediaPlayer2.Player', in_signature='', out_signature='')
    def PlayPause(self):
        os.system('qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Pause')
        
    @dbus.service.method('org.mpris.MediaPlayer2.Player', in_signature='', out_signature='')
    def Stop(self):
        os.system('qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Pause')
        
    @dbus.service.method('org.mpris.MediaPlayer2.Player', in_signature='', out_signature='')
    def Next(self):
        pass  # Will be handled by keyboard shortcuts
        
    @dbus.service.method('org.mpris.MediaPlayer2.Player', in_signature='', out_signature='')
    def Previous(self):
        pass  # Will be handled by keyboard shortcuts

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName('org.mpris.MediaPlayer2.globalplayer', bus)
mpris = GlobalPlayerMPRIS(bus)
loop = GLib.MainLoop()
loop.run()
'''
            
            # Save and run MPRIS script
            mpris_file = "/tmp/globalplayer_mpris.py"
            with open(mpris_file, "w") as f:
                f.write(mpris_script)
            
            # Start MPRIS service in background
            subprocess.Popen([sys.executable, mpris_file], 
                           stdout=subprocess.DEVNULL, 
                           stderr=subprocess.DEVNULL)
            
            self.media_keys_registered = True
            print("✓ Registered MPRIS2 media key handler")
            
        except Exception as e:
            print(f"⚠️  Could not register media keys: {e}")
    
    def setup_global_shortcuts(self):
        """Setup KDE global shortcuts"""
        shortcuts = [
            # Format: (action, description, key_combination, command)
            ("globalplayer-play", "Global Player Play/Pause", "XF86AudioPlay", "PlayPause"),
            ("globalplayer-stop", "Global Player Stop", "XF86AudioStop", "Stop"), 
            ("globalplayer-next", "Global Player Next Station", "XF86AudioNext", "NextStation"),
            ("globalplayer-prev", "Global Player Previous Station", "XF86AudioPrev", "PrevStation"),
            ("globalplayer-mode", "Global Player Mode Toggle", "Meta+Shift+M", "ModeToggle"),
            ("globalplayer-refresh", "Global Player Refresh", "Meta+Shift+R", "Refresh")
        ]
        
        for action, desc, key, command in shortcuts:
            try:
                # Register with kglobalshortcuts5
                subprocess.run([
                    "kglobalshortcuts5",
                    "--register", action,
                    "--description", desc,
                    "--key", key,
                    "--command", f"python3 -c \"import dbus; bus=dbus.SessionBus(); proxy=bus.get_object('org.mooheda.gpd', '/org/mooheda/gpd'); proxy.{command}()\"" 
                ], check=False, capture_output=True)
                
                print(f"✓ Registered: {desc} ({key})")
                
            except Exception as e:
                print(f"⚠️  Could not register {action}: {e}")
    
    def on_key_press(self, key):
        """Handle direct key press events"""
        try:
            if not self.daemon_proxy:
                if not self.connect_to_daemon():
                    return
            
            # Handle special key combinations
            if hasattr(key, 'name'):
                key_name = key.name
                
                # Media keys (if not handled by MPRIS)
                if key_name == 'media_play_pause':
                    self.send_command("Pause")
                    self.show_notification("Play/Pause")
                elif key_name == 'media_stop':
                    self.send_command("Pause") 
                    self.show_notification("Stop")
                elif key_name == 'media_next':
                    self.next_station()
                    self.show_notification("Next Station")
                elif key_name == 'media_previous':
                    self.prev_station()
                    self.show_notification("Previous Station")
                    
        except Exception as e:
            print(f"Key press error: {e}")
    
    def send_command(self, command, args=None):
        """Send D-Bus command to daemon"""
        try:
            if not self.daemon_proxy:
                return False
                
            method = getattr(self.daemon_proxy, command)
            if args:
                result = method(*args, dbus_interface="org.mooheda.gpd1")
            else:
                result = method(dbus_interface="org.mooheda.gpd1")
            return True
            
        except Exception as e:
            print(f"D-Bus command failed: {e}")
            return False
    
    def next_station(self):
        """Switch to next station"""
        # Get current stations and state
        try:
            stations_json = self.daemon_proxy.GetStations(dbus_interface="org.mooheda.gpd1")
            state_json = self.daemon_proxy.GetState(dbus_interface="org.mooheda.gpd1")
            
            import json
            stations = json.loads(stations_json)
            state = json.loads(state_json)
            
            if stations and len(stations) > 1:
                current_station = state.get('station', '')
                try:
                    current_index = stations.index(current_station)
                    next_index = (current_index + 1) % len(stations)
                    next_station = stations[next_index]
                    
                    self.send_command("Play", [next_station])
                    return True
                except ValueError:
                    # Station not in list, play first station
                    self.send_command("Play", [stations[0]])
                    return True
                    
        except Exception as e:
            print(f"Next station error: {e}")
            return False
    
    def prev_station(self):
        """Switch to previous station"""
        try:
            stations_json = self.daemon_proxy.GetStations(dbus_interface="org.mooheda.gpd1")
            state_json = self.daemon_proxy.GetState(dbus_interface="org.mooheda.gpd1")
            
            import json
            stations = json.loads(stations_json)
            state = json.loads(state_json)
            
            if stations and len(stations) > 1:
                current_station = state.get('station', '')
                try:
                    current_index = stations.index(current_station)
                    prev_index = (current_index - 1) % len(stations)
                    prev_station = stations[prev_index]
                    
                    self.send_command("Play", [prev_station])
                    return True
                except ValueError:
                    # Station not in list, play last station
                    self.send_command("Play", [stations[-1]])
                    return True
                    
        except Exception as e:
            print(f"Previous station error: {e}")
            return False
    
    def show_notification(self, message):
        """Show desktop notification"""
        try:
            subprocess.run([
                "notify-send", 
                "Global Player", 
                message,
                "--expire-time=2000",
                "--app-name=Global Player",
                "--icon=audio-headphones"
            ], check=False, capture_output=True)
        except:
            pass
    
    def run(self):
        """Start the hotkey daemon"""
        print("🎵 Global Player Hotkey Daemon Starting...")
        
        # Register media keys
        self.register_media_keys()
        
        # Setup KDE global shortcuts
        self.setup_global_shortcuts()
        
        print("\n📋 Active Hotkeys:")
        print("   • Media Play/Pause → Play/Pause radio")
        print("   • Media Stop → Stop playback")  
        print("   • Media Next → Next station")
        print("   • Media Previous → Previous station")
        print("   • Meta+Shift+M → Toggle mode")
        print("   • Meta+Shift+R → Refresh stations")
        print("\n✅ Hotkey daemon ready!")
        
        # Start keyboard listener for direct key capture
        with Listener(on_press=self.on_key_press) as listener:
            try:
                listener.join()
            except KeyboardInterrupt:
                print("\n🛑 Stopping hotkey daemon...")
                return

def main():
    # Check dependencies
    try:
        import pynput
        import dbus
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Install with: pip3 install pynput python-dbus")
        sys.exit(1)
    
    # Start daemon
    daemon = GlobalPlayerHotkeys()
    daemon.run()

if __name__ == "__main__":
    main()

echo "[+] Creating Italy station list..."
cat > "globalplayer-daemon/stations_static.json" << 'EOF'
[
  {
    "name": "RTL 102.5",
    "url": "https://streamingv2.shoutcast.com/rtl-1025"
  },
  {
    "name": "Radio Deejay",
    "url": "https://radiodeejay-lh.akamaihd.net/i/RadioDeejay_Live@189857/master.m3u8"
  },
  {
    "name": "RDS",
    "url": "https://rds.akacast.akamaistream.net/7/672/435747/v1/rm.akacast.akamaistream.net/rds"
  },
  {
    "name": "Radio 105",
    "url": "https://icy.unitedradio.it/Radio105.mp3"
  },
  {
    "name": "Virgin Radio",
    "url": "https://icy.unitedradio.it/Virgin.mp3"
  },
  {
    "name": "R101",
    "url": "https://icy.unitedradio.it/R101.mp3"
  },
  {
    "name": "Radio Kiss Kiss",
    "url": "https://ice07.fluidstream.net/KissKiss.mp3"
  },
  {
    "name": "Radio Capital",
    "url": "https://radiocapital-lh.akamaihd.net/i/RadioCapital_Live@783731/master.m3u8"
  },
  {
    "name": "Radio Rock",
    "url": "https://icy.unitedradio.it/RadioRock.mp3"
  },
  {
    "name": "Rai Radio 1",
    "url": "https://radiotoradiomainstream.akamaized.net/hls/live/2049811/RaiRadio1_AdaptiveStreaming/mp4:output_audio=64000/playlist.m3u8"
  },
  {
    "name": "Rai Radio 2",
    "url": "https://radiotoradiomainstream.akamaized.net/hls/live/2049812/RaiRadio2_AdaptiveStreaming/mp4:output_audio=64000/playlist.m3u8"
  },
  {
    "name": "Rai Radio 3",
    "url": "https://radiotoradiomainstream.akamaized.net/hls/live/2049813/RaiRadio3_AdaptiveStreaming/mp4:output_audio=64000/playlist.m3u8"
  },
  {
    "name": "Radio Italia",
    "url": "https://radioitalia-lh.akamaihd.net/i/radioitalia_1@531509/master.m3u8"
  },
  {
    "name": "Radio 24",
    "url": "https://ilsole24ore-radio.akacast.akamaistream.net/7/25/177478/v1/rm.akacast.akamaistream.net/ilsole24ore_radio"
  },
  {
    "name": "Radio Monte Carlo",
    "url": "https://icy.unitedradio.it/RMC.mp3"
  },
  {
    "name": "Subasio",
    "url": "https://subasio.shoutcast.it/autodj"
  },
  {
    "name": "Radio Zeta",
    "url": "https://radiozeta.shoutcast.it/radiozeta"
  },
  {
    "name": "M2o",
    "url": "https://icy.unitedradio.it/m2o.mp3"
  },
  {
    "name": "Radio Radicale",
    "url": "https://live.radioradicale.it/live.mp3"
  },
  {
    "name": "Isoradio",
    "url": "https://radiotoradiomainstream.akamaized.net/hls/live/2049814/RaiIsoradio_AdaptiveStreaming/mp4:output_audio=64000/playlist.m3u8"
  }
]

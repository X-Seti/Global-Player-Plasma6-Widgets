
echo "[+] Creating Germany station list..."
cat > "globalplayer-daemon/stations_static.json" << 'EOF'
[
  {
    "name": "1LIVE",
    "url": "https://wdr-1live-live.icecastssl.wdr.de/wdr/1live/live/mp3/128/stream.mp3"
  },
  {
    "name": "WDR 2",
    "url": "https://wdr-wdr2-rheinland.icecastssl.wdr.de/wdr/wdr2/rheinland/mp3/128/stream.mp3"
  },
  {
    "name": "Bayern 3",
    "url": "https://br-bayern3-live.cast.addradio.de/br/bayern3/live/mp3/128/stream.mp3"
  },
  {
    "name": "SWR3",
    "url": "https://swr-swr3-live.cast.addradio.de/swr/swr3/live/mp3/128/stream.mp3"
  },
  {
    "name": "NDR 2",
    "url": "https://ndr-ndr2-niedersachsen.cast.addradio.de/ndr/ndr2/niedersachsen/mp3/128/stream.mp3"
  },
  {
    "name": "HR3",
    "url": "https://hr-hr3-live.cast.addradio.de/hr/hr3/live/mp3/128/stream.mp3"
  },
  {
    "name": "MDR Jump",
    "url": "https://mdr-284280-0.cast.mdr.de/mdr/284280/0/mp3/high/stream.mp3"
  },
  {
    "name": "Radio Fritz",
    "url": "https://rbbmedia.cast.addradio.de/rbb/fritz/live/mp3/mid"
  },
  {
    "name": "Deutschlandfunk",
    "url": "https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3"
  },
  {
    "name": "Deutschlandfunk Nova",
    "url": "https://st03.sslstream.dlf.de/dlf/03/128/mp3/stream.mp3"
  },
  {
    "name": "Antenne Bayern",
    "url": "https://s1-webradio.antenne.de/antenne"
  },
  {
    "name": "Radio Hamburg",
    "url": "https://frontend.streams.radiohamburg.de/radiohamburg/mp3-192/radiohamburg/"
  },
  {
    "name": "89.0 RTL",
    "url": "https://streams.rtl.lu/rtlradio/mp3-192/rtlradio/"
  },
  {
    "name": "Energy Berlin",
    "url": "https://frontend.streams.nrjaudio.fm/energyberlin/mp3-192/energyberlin/"
  },
  {
    "name": "BigFM",
    "url": "https://streams.bigfm.de/bigfm-deutschland-128-mp3"
  },
  {
    "name": "Klassik Radio",
    "url": "https://klassikr.streamabc.net/klr-klassikrlive-mp3-192-4529346"
  },
  {
    "name": "Radio Bob",
    "url": "https://streams.radiobob.de/bob-live/mp3-192/streams.radiobob.de/"
  },
  {
    "name": "Rock Antenne",
    "url": "https://s1-webradio.rockantenne.de/rockantenne"
  }
]

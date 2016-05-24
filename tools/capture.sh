#/usr/bin/env bash

# Record the desktop defined by the DISPLAY env variable
# to ~/Desktop/capture-$timestamp.mkv with pulse audio sound.
#
# usage:
#
# run capture.sh to start capture
# run capture.sh to stop a running capture.sh
#
# On my Thinkpad X220 I have mapped the "blue think button" to a custom
# keyboard shortcut with the command "capture.sh". In this way I can
# start and stop desktop recordings.
#
# Required tools:
#
# sudo apt-get install ffmpeg pulseaudio pulseaudio-utils beep x11-utils
#

PROGRAM_FILE="$0"
PROGRAM_NAME="$(basename $0)"

loadModule(){
  MODULE_LOAD1=$(pactl load-module module-null-sink sink_name=GameAudio sink_properties=device.description="GameAudio") # For Game Audio
  MODULE_LOAD2=$(pactl load-module module-null-sink sink_name=MicAudio sink_properties=device.description="MicAudio") # For Mic Audio
  pactl load-module module-device-manager >> /dev/null
  pactl load-module module-loopback sink=GameAudio >> /dev/null
  pactl load-module module-loopback sink=MicAudio >> /dev/null
}

unloadModule(){
  echo "Stopping Audio (Don't worry if you see errors here)"
  pactl unload-module $MODULE_LOAD1
  pactl unload-module $MODULE_LOAD2
  pactl unload-module module-device-manager
  pactl unload-module module-null-sink
  pactl unload-module module-loopback
  echo "Exit!"
}

#echo >&2 "$PROGRAM_NAME: started from '$PROGRAM_FILE' with options: $*"

if [ $(( ${BASH_VERSINFO[0]} )) -lt 4 ]
then
  echo >&2
  echo >&2 "$PROGRAM_NAME: ERROR"
  echo >&2 "BASH version 4 or later is required."
  echo >&2 "You are running version: ${BASH_VERSION}"
  echo >&2 "Please upgrade."
  echo >&2
  exit 1
fi

require_cmd() {
  which "$1" >/dev/null
  if [ $? -ne 0 ]
  then
    echo >&2 "$PROGRAM_NAME: ERROR: Command '$1' is not found in the system path."
    return 1
  fi
  return 0
}

require_cmd beep     || exit 1
require_cmd xdpyinfo || exit 1
require_cmd ffmpeg   || exit 1
require_cmd pactl    || exit 1

pidfile=~/.capture.pid

if [ -f "$pidfile" ]; then
  echo "stopping capture.sh";
  kill $(cat $pidfile); sleep 0.5;
  beep -f 500; beep -f 400
  exit 0;
fi

D=~/Desktop/
F=capture-`date +%Y-%m-%d-%H:%M:%S`

loadModule

trap 'kill -TERM $PID; wait $PID; unloadModule; rm -f -- $pidfile' TERM
trap 'rm -f -- $pidfile' EXIT

echo $$ > "$pidfile"

beep -f 400; beep -f 500; sleep 0.5

echo "Capturing DISPLAY=$DISPLAY"

ffmpeg -loglevel error -y -video_size `xdpyinfo -display $DISPLAY | grep 'dimensions:'|awk '{print $2}'` -f x11grab -y -r 25 -i $DISPLAY+0.0 -f alsa -i pulse -ac 2 -c:v libx264 -qp 0 -preset ultrafast -tune film -acodec libmp3lame -b:a 128k -ac 2 -ar 44100 -threads 4 $D$F.mkv &

PID=$!
wait $PID

unloadModule

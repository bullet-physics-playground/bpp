#/usr/bin/env bash

# Record the desktop defined by the DISPLAY env variable
# to ~/Desktop/capture-$timestamp.mkv with pulse audio sound.
#
# usage:
#
# run capture.sh to start capture
# run capture.sh to stop a running capture.sh
#
#
# Required tools:
#
# sudo apt-get install ffmpeg pulseaudio pulseaudio-utils
#

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

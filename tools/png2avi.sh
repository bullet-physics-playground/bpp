#/usr/bin/env bash

PROGRAM_FILE="$0"
PROGRAM_NAME="$(basename $0)"

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

require_cmd mencoder || exit 1

#OPT=-mf fps=25 -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=1000:turbo:vpass=1
#OPT=-mf fps=25 -ovc lavc -lavcopts mbd=2:trell=yes:v4mv=yes:vbitrate=400000
#OPT=-mf fps=25 -ovc lavc -lavcopts vcodec=mpeg4:mbd=1:vbitrate=9000

export OPT="-mf fps=25 -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=1000:turbo:vpass=1"
mencoder "mf://*.png" $OPT -o anim.avi 

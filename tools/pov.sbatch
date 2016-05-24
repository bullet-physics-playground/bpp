#!/usr/bin/env bash

#SBATCH -N 1
#SBATCH -e /nfs/data/log/job-%A-%a.err
#SBATCH -o /nfs/data/log/job-%A-%a.out

#SBATCH --mail-user koppi
#SBATCH --mail-type ALL

# This sbatch script is used together with the
# slurm-pov-job shell script to submit POV-Ray
# rendering jobs to the SLURM workload manager.

SCENE=${1}
FRAMES=${2}

POVARGS="+W1280 +H720 +A0.3 -J"

if [ -z "${SCENE}" ]; then
  echo "SCENE is unset or set to the empty string"
  exit 1
fi

WORKDIR=`pwd`/$SCENE-$SLURM_ARRAY_JOB_ID
FRAME=$SLURM_ARRAY_TASK_ID

mkdir -p $WORKDIR

echo "$SLURMD_NODENAME:$WORKDIR"
echo "pwd: `pwd`"

PNG="$SCENE-$(printf "%07d" $FRAME).png"

time nice povray $SCENE.ini -V -D +KFI0 +KFF$FRAMES +SF$FRAME +EF$FRAME $POVARGS -O- > $WORKDIR/$PNG

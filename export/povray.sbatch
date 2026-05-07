#!/usr/bin/env bash

#SBATCH -e %a.err
#SBATCH -o %a.out

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --requeue

SCENE=${1}
FRAMES=${2}

if [ -z "${SCENE}" ]; then
  echo "SCENE is unset or set to the empty string"
  exit 1
fi

WORKDIR=`pwd`
FRAME=$SLURM_ARRAY_TASK_ID

mkdir -p $WORKDIR
cd $WORKDIR

echo "$SLURMD_NODENAME:$WORKDIR"
echo

PNG="$(printf "%05d" $FRAME).png"

nice povray /nfs/bpp/export/$SCENE/$SCENE.ini +L. +Lincludes +L/nfs/bpp/includes +L/nfs/bpp/export/$SCENE -V -D +KFI0 +KFF$FRAMES +SF$FRAME +EF$FRAME $POVOPT -O- > $WORKDIR/$PNG

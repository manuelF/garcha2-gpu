#! /bin/bash
if [ -z "$LIOBIN" ] ; then
  LIOBIN=../../../../liosolo/liosolo
fi
SALIDA=output
if [ -n "$1" ]
  then
    SALIDA=$1
fi

export GFORTRAN_UNBUFFERED_ALL=1

export GFORTRAN_UNBUFFERED_ALL=1
source ../../../../liohome.sh
${LIOHOME}/liosolo/liosolo -i co.in -c co.xyz -v > $SALIDA

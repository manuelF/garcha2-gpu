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

source ../../../../liohome.sh
${LIOBIN} -i form_wat.in -c form_wat.xyz -v > $SALIDA

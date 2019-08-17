#!/bin/bash

cd "$1"

BASENAME=`basename "$2" .bnd`

for f in $BASENAME???.bnd; do 
    mv -- "$1/$f" "$1/${f%.bnd}.wav"
done
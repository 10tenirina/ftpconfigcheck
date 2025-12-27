#!/bin/bash


filename=$1

if [ -z "$filename" ]; then
	echo "Introduceti un nume de fisier"
	exit 1;
fi

if [ ! -f "$filename" ]; then
	 echo "$filename nu exista"
	exit 1;
fi

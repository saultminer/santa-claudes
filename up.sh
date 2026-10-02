#!/bin/bash

# run system setup check
./util/setup-host.sh

while getopts "w:" opt
do
  case "$opt" in
    w) workshopdir="$OPTARG";;
  esac
done

if [ -z "$workshopdir" ]
then
    workshopdir="~/source"
    echo "Workshop directory parameter -w was not specified,  defaulting to " ${workshopdir}
fi

WORKSHOP_DIR="$workshopdir" USER_ID="$(id -u)" GROUP_ID="$(id -g)" docker compose up --build

#!/usr/bin/env bash

LINK=$(readlink $0)
if [ -z "$LINK" ]; then SCRIPTPATH=$0; else SCRIPTPATH=$LINK; fi
SCRIPTPATH="$(
  cd -- "$(dirname "$SCRIPTPATH")" >/dev/null 2>&1
  pwd -P
)"

source $SCRIPTPATH/utils.sh

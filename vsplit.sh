#!/usr/bin/env bash

# -------------------------------------------------------------------------------------------------------------------
# ABSOLUTE SCRIPT PATH
# -------------------------------------------------------------------------------------------------------------------
LINK=$(readlink $0)
if [ -z "$LINK" ]; then
  SCRIPTPATH=$0
else
  SCRIPTPATH=$LINK
fi
SCRIPTPATH="$(
  cd -- "$(dirname "$SCRIPTPATH")" >/dev/null 2>&1
  pwd -P
)"

# -------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
# -------------------------------------------------------------------------------------------------------------------
function usage() {
  echo "Usage: $0 [options] <input_file>"
  echo "options:"
  echo "-h     Print this Help."
  echo "-p     Number of parts to divide the input into. Optional (default 2)."
  echo "-o     Output Path (default the same dir of the input)."
}

function is_software_installed() {
  if ! command -v $1 &>/dev/null; then
    echo 0
  else
    echo 1
  fi
}

# -------------------------------------------------------------------------------------------------------------------
# PARSE ARGUMENTS
# -------------------------------------------------------------------------------------------------------------------
while getopts "h:p:o:" option; do
  case $option in
  h)
    usage
    exit 0
    ;;
  p)
    PARTS=$OPTARG
    ;;
  o)
    OUTPUT=$OPTARG
    ;;
  \?)
    usage
    exit 1
    ;;
  esac
done

INPUT=${@:$OPTIND:1}

# -------------------------------------------------------------------------------------------------------------------
# VALIDATION
# -------------------------------------------------------------------------------------------------------------------

if [ $(is_software_installed ffmpeg) -eq 0 ]; then echo "FFmpeg is required. Plese visit https://www.ffmpeg.org" && exit 1; fi
if [ -z $PARTS ]; then PARTS=2; fi
if [ -z "$INPUT" ]; then usage && exit 1; fi
if [ ! -f "$INPUT" ]; then echo "Input file not found: $INPUT" && exit 1; fi
if [ -z $OUTPUT ]; then OUTPUT=$(dirname "$INPUT"); fi
if [ ! -d "$OUTPUT" ]; then echo "Output folder not found: $OUTPUT" && exit 1; fi

DURATION=$(ffmpeg -i "$INPUT" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)

DURATION_SECONDS=$(echo "$DURATION" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }' | awk -F'.' '{print $1}')
DURATION_CHUNK=$(printf '%.*f\n' 0 "$(($DURATION_SECONDS / $PARTS))")

echo "Split Video in $PARTS chunks of duration: $DURATION_CHUNK seconds"

for i in $(seq 0 $((PARTS - 1))); do
  FROM=$((i * DURATION_CHUNK))
  TO=$((FROM + DURATION_CHUNK))

  FROM_FORMATTED=$(printf '%02d:%02d:%02d\n' $(($FROM / 3600)) $(($FROM % 3600 / 60)) $(($FROM % 60)))
  TO_FORMATTED=$(printf '%02d:%02d:%02d\n' $(($TO / 3600)) $(($TO % 3600 / 60)) $(($TO % 60)))

  OUTPUT_FILE=$(basename "$INPUT")
  OUTPUT_EXT=$(echo $OUTPUT_FILE | awk -F'.' '{print $NF}')
  OUTPUT_FILE="${OUTPUT_FILE%.*}__$((i + 1)).$OUTPUT_EXT"

  ffmpeg -v error -stats -ss $FROM_FORMATTED -i "$INPUT" -to $TO_FORMATTED -codec copy -avoid_negative_ts make_zero "$OUTPUT/$OUTPUT_FILE"

done

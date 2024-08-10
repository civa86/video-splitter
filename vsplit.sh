#!/usr/bin/env bash

# -------------------------------------------------------------------------------------------------------------------
# Script Absolute Path + Utils import
# -------------------------------------------------------------------------------------------------------------------
LINK=$(readlink $0)
if [ -z "$LINK" ]; then SCRIPTPATH=$0; else SCRIPTPATH=$LINK; fi
SCRIPTPATH="$(
  cd -- "$(dirname "$SCRIPTPATH")" >/dev/null 2>&1
  pwd -P
)"

source $SCRIPTPATH/utils.sh

# -------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
# -------------------------------------------------------------------------------------------------------------------
function usage() {
  echo "Usage: vsplit [options] <input_file>"
  echo ""
  echo "options:"
  echo "-h     Print this Help."
  echo "-p     Number of parts to divide the input into. Optional (default 2)."
  echo "-o     Output Path (default the same dir of the input)."
  echo ""
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

# -------------------------------------------------------------------------------------------------------------------
# EXECUTION
# -------------------------------------------------------------------------------------------------------------------

FILENAME=$(basename "$1")
FILE_EXTENSION="${FILENAME##*.}"

DURATION=$(ffmpeg -i "$INPUT" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)

DURATION_SECONDS=$(timestring_to_seconds $DURATION)
DURATION_CHUNK=$(printf '%.*f\n' 0 "$(($DURATION_SECONDS / $PARTS))")

INPUT_LINE=$(printf "Input Video,%s" "$FILENAME")
TOTAL_LENGTH_LINE=$(printf "Total Duration,%s" $DURATION)
PARTS_LINE=$(printf "Number of Chunks,%s" $PARTS)
PARTS_DURATION_LINE=$(printf "Single Chunk Duration,%s" "$(seconds_to_timestring $DURATION_CHUNK)")
OUTPUT_LINE=$(printf "Output Folder,%s" "$OUTPUT")

TABLE_STRING=$(printf "%s\n%s\n%s\n%s\n%s" "$INPUT_LINE" "$TOTAL_LENGTH_LINE" "$PARTS_LINE" "$PARTS_DURATION_LINE" "$OUTPUT_LINE")

clear

TABLE=$(print_table "," "$TABLE_STRING")

TABLE_FIRST_LINE=$(echo $TABLE | awk -F' ' '{print $1}')
TABLE_FIRST_LINE_LENGTH=${#TABLE_FIRST_LINE}
TITLE="VIDEO SPLITTER"
TITLE_LENGTH=${#TITLE}

SPACES=$((TABLE_FIRST_LINE_LENGTH - TITLE_LENGTH - 2))
LEFT_SPACES="$((SPACES / 2))"
RIGHT_SPACES=$((SPACES - LEFT_SPACES))

printf "+%s+\n" "$(repeat_string "-" $((TABLE_FIRST_LINE_LENGTH - 2)))"
printf "|%s%s%s|\n" "$(repeat_string " " $LEFT_SPACES)" "$TITLE" "$(repeat_string " " $RIGHT_SPACES)"
printf "%s\n\n" "$TABLE"

read -p "* Start Splitting Video? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted. Bye bye."
  exit 0
fi

for i in $(seq 0 $((PARTS - 1))); do
  echo ""
  FROM=$((i * DURATION_CHUNK))
  TO=$((FROM + DURATION_CHUNK))

  FROM_FORMATTED=$(seconds_to_timestring $FROM)
  TO_FORMATTED=$(seconds_to_timestring $TO)

  FILENAME_NO_EXT="${FILENAME%.*}"
  echo $FILENAME_NO_EXT

  OUTPUT_FILE="${FILENAME_NO_EXT}__$((i + 1)).${FILE_EXTENSION}"

  echo "[$FROM_FORMATTED - $TO_FORMATTED][$OUTPUT_FILE]"

  ffmpeg -v error -stats -ss $FROM_FORMATTED -i "$INPUT" -to $TO_FORMATTED -codec copy -avoid_negative_ts make_zero "$OUTPUT/$OUTPUT_FILE"

done

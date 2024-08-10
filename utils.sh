# COLORS

BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
COLOR_RESET="\033[0m"

function print_black() {
  echo -e $BLACK"$1"$COLOR_RESET
}

function print_red() {
  echo -e $RED"$1"$COLOR_RESET
}

function print_green() {
  echo -e $GREEN"$1"$COLOR_RESET
}

function print_yellow() {
  echo -e $YELLOW"$1"$COLOR_RESET
}

function print_cyan() {
  echo -e $BLUE"$1"$COLOR_RESET
}

function print_magenta() {
  echo -e $MAGENTA"$1"$COLOR_RESET
}

function print_cyan() {
  echo -e $CYAN"$1"$COLOR_RESET
}

function print_white() {
  echo -e $WHITE"$1"$COLOR_RESET
}

function is_software_installed() {
  if ! command -v $1 &>/dev/null; then
    echo 0
  else
    echo 1
  fi
}

function timestring_to_seconds() {
  local -r timestring="${1}"
  echo "$timestring" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }' | awk -F'.' '{print $1}'
}

function seconds_to_timestring() {
  local -r seconds="${1}"
  printf '%02d:%02d:%02d\n' $(($seconds / 3600)) $(($seconds % 3600 / 60)) $(($seconds % 60))
}

function remove_empty_lines() {
  local -r content="${1}"

  echo -e "${content}" | sed '/^\s*$/d'
}

function repeat_string() {
  local -r string="${1}"
  local -r numberToRepeat="${2}"

  if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]; then
    local -r result="$(printf "%${numberToRepeat}s")"
    echo -e "${result// /${string}}"
  fi
}

function trim_string() {
  local -r string="${1}"

  sed 's,^[[:blank:]]*,,' <<<"${string}" | sed 's,[[:blank:]]*$,,'
}

function is_empty_string() {
  local -r string="${1}"

  if [[ "$(trim_string "${string}")" = '' ]]; then
    echo 'true' && return 0
  fi

  echo 'false' && return 1
}

function print_table() {
  local -r delimiter="${1}"
  local -r data="$(remove_empty_lines "${2}")"

  if [[ "${delimiter}" != '' && "$(is_empty_string "${data}")" = 'false' ]]; then

    local -r numberOfLines="$(echo -e "$data" | wc -l)"

    if [[ "${numberOfLines}" -gt '0' ]]; then
      local table=''
      local i=1

      for ((i = 1; i <= "${numberOfLines}"; i = i + 1)); do
        local line=''
        line="$(sed "${i}q;d" <<<"${data}")"

        local numberOfColumns='0'
        numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<<"${line}")"

        # Add Line Delimiter

        if [[ "${i}" -eq '1' ]]; then
          table="${table}$(printf '%s#+' "$(repeat_string '#+' "${numberOfColumns}")")"
        fi

        # Add Header Or Body

        table="${table}\n"

        local j=1

        for ((j = 1; j <= "${numberOfColumns}"; j = j + 1)); do
          table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<<"${line}")")"
        done

        table="${table}#|\n"

        # Add Line Delimiter

        if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]; then
          table="${table}$(printf '%s#+' "$(repeat_string '#+' "${numberOfColumns}")")"
        fi
      done

      if [[ "$(is_empty_string "${table}")" = 'false' ]]; then
        echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
      fi
    fi
  fi
}

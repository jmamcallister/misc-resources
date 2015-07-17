#!/bin/bash

ECHO="echo -e"
MKDIR=/bin/mkdir
MV=/bin/mv
RM=/bin/rm
SED=/bin/sed
TMP_FILES=""

die() { ${ECHO} "FATAL: ${*}" >&2; exit 1; }
info() { ${ECHO} "INFO: ${*}"; }
warn() { ${ECHO} "WARN: ${*}"; }
error() { ${ECHO} "ERROR: ${*}" >&2; }

cleanup()
{
    for _file in ${TMP_FILES}; do
        ${RM} -f ${_file} || warn "Could not remove file [ ${_file} ]"
    done
}

graceful_exit()
{
    [ "${#}" -gt 1 -a "${1}" -eq 0 ] && info "${2}"
    [ "${#}" -gt 1 -a "${1}" -gt 0 ] && error "${2}"
    cleanup
    exit "${1}"
}

prg=$( basename "${0}" )
prg_dir=$( cd "$(dirname "$0")" ; pwd -P )

_usage="
Usage: ${prg} -i IP_START [-n NUM] [-c FILE] [-h]

Prints NUM IP addresses starting at IP_START

Options:

    -c FILE         Use FILE for configuration
    -i IP_START     IP address from which to begin printing
    -n NUM          Print NUM IP addresses after IP_START. Default is 160
    -h              Display this help
"

[ -r "/usr/local/etc/${prg%.*}.conf" ] && . "/usr/local/etc/${prg%.*}.conf"
[ -r "${prg_dir}/../etc/${prg%.*}.conf" ] && . "${prg_dir}/../etc/${prg%.*}.conf"
[ -r "${prg_dir}/${prg%.*}.conf" ] && . "${prg_dir}/${prg%.*}.conf"

iflag=false

while getopts ":c:i:n:h" opt; do
    case $opt in
        c)
            [ ! -r "${OPTARG}" ] && die "Cannot read config file ${OPTARG}"
            . "${OPTARG}"
            ;;
        h)
            echo "${_usage}"; exit 0
            ;;
        i)
            iflag=true
            IP_START="${OPTARG}"
            ;;
        n)
            if ! ${iflag}; then
                die "-n option requires -i to be set"
            fi
            IP_COUNT="${OPTARG}"
            ;;
        \?)
            die "Invalid option: -$OPTARG"
            ;;
        :)
            die "Option -$OPTARG requires an argument"
            ;;
    esac
done

[ "${iflag}" = false ] && die "-i option must be specified"

[ -z "${AWK}" ] && AWK=/bin/awk
[ -z "${GREP}" ] && GREP=/bin/grep
[ -z "${SED}" ] && SED=/bin/sed
[ -z "${IP_COUNT}" ] && IP_COUNT=160

VALID_IP=$( ${ECHO} ${IP_START} | ${AWK} -F"." \
    ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ \
    && $1 <= 255 \
    && $2 <= 255 \
    && $3 <= 255 \
    && $4 <= 255 ' )

[ -z "${VALID_IP}" ] && die "${IP_START} not a valid IPv4 address"

_oct1=${VALID_IP%%.*}
_oct2_tmp=${VALID_IP#*.}
_oct2=${_oct2_tmp%%.*}
_oct3_tmp=${_oct2_tmp#*.}
_oct3=${_oct3_tmp%.*}
_oct4=${VALID_IP##*.}

while [ ${IP_COUNT} -gt 0 ]; do
    ${ECHO} "${_oct1}.${_oct2}.${_oct3}.${_oct4}"
    (( _oct4++ ))
    (( IP_COUNT-- ))
    if [ ${_oct4} -gt 255 ]; then
        _oct4=0
        (( _oct3++ ))
    fi
    if [ ${_oct3} -gt 255 ]; then
        _oct3=0
        (( _oct2++ ))
    fi
    if [ ${_oct2} -gt 255 ]; then
        _oct2=0
        (( _oct1++ ))
    fi
    [ ${_oct1} -gt 255 ] && die "${_oct1}.${_oct2}.${_oct3}.${_oct4} out of IPv4 range"

done

graceful_exit 0

#!/bin/bash
##
## Template for bash scripts
##

ECHO="echo -e"
RM=/bin/rm
TMP_FILES=""

prg=$( basename "${0}" )
prg_dir=$( cd "$(dirname "$0")" ; pwd -P )

_usage="Usage: ${prg} [-c FILE] [-h]
Some script

Options:

    -c FILE, --config FILE      Use FILE for configuration. Order of configuration loading:
                                /usr/local/etc/${prg%.*}.conf
                                ${prg_dir}/../etc/${prg%.*}.conf
                                ${prg_dir}/${prg%.*}.conf
                                These configurations can be overridden by FILE. The second entry
                                in the order is based on users having a folder structure like
                                '~/bin/' for their own scripts and '~/etc/' for their own
                                configurations

    -h, --help                  Display this help
"

die() { ${ECHO} "FATAL: ${*}" >&2; exit 1; }
info() { ${ECHO} "INFO: ${*}"; }
warn() { ${ECHO} "WARN: ${*}"; }
error() { ${ECHO} "ERROR: ${*}" >&2; }
usage() { echo "${_usage}"; exit 0; }

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

[ -r "/usr/local/etc/${prg%.*}.conf" ] && . "/usr/local/etc/${prg%.*}.conf"
[ -r "${prg_dir}/../etc/${prg%.*}.conf" ] && . "${prg_dir}/../etc/${prg%.*}.conf"
[ -r "${prg_dir}/${prg%.*}.conf" ] && . "${prg_dir}/${prg%.*}.conf"

#
# http://stackoverflow.com/a/5255468
#
# translate long options to short
for arg in "$@"
do
    delim=""
    case "$arg" in
       --help) args="${args}-h ";;
       --config) args="${args}-c ";;
       # pass through anything else
       *) [[ "${arg:0:1}" == "-" ]] || delim="\""
           args="${args}${delim}${arg}${delim} ";;
    esac
done
# reset the translated args
eval set -- $args

while getopts ":c:h" opt; do
    case $opt in
        c)
            [ ! -r "${OPTARG}" ] && die "Cannot read config file ${OPTARG}"
            . "${OPTARG}"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG"; usage
            ;;
        :)
            die "Option -$OPTARG requires an argument"
            ;;
    esac
done

[ -z "${MY_VAR}" ] && MY_VAR=myvalue

graceful_exit 0 "It worked!"

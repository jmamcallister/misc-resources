#!/bin/bash
##
## Template for bash scripts
##

ECHO="echo -e"
LOGGER_TAG="YOUR_PROG"
RM=/bin/rm
TMP_FILES=""

cmds="single multi help"

prg=$( basename "${0}" )
prg_dir=$( cd "$(dirname "$0")" ; pwd -P )

_usage="Usage: ${prg} { func | help }
Some script

Commands:
    single      Do something
    multi       Do something else
    help        Show help
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

case ${1} in
    single)
        # TODO - improve using parameter substitution
        #[ "${#}" -gt 1 ] && die "Invalid option(s)- ${*%% *}"
        if [ "${#}" -gt 1 ]; then
            shift
            die "Invalid option(s) - ${*}"
        fi
        echo "Your options:" "${@}"
        ;;
    multi)
        if [ "${#}" -lt 2 ]; then
            die "Missing option(s) - ${1}"
        fi
        echo "Your options:" "${@}"
        ;;
    help)
        echo "${_usage}"; exit 0
        ;;
    shortlist)
        echo "${cmds}"; exit 0            
        ;;
    *)
        die "Unkown command '${1}'\n${_usage}"
        ;;
esac

echo "It worked!"
exit 0

#!/bin/bash
##
## Template for bash scripts
##

ECHO="echo -e"
LOGGER_TAG="PRINT_DAYS"
RM=/bin/rm
AWK=/bin/awk
TMP_FILES=""
today=$( date +%s )
one_day=86400

die() { ${ECHO} "FATAL: ${*}" >&2; exit 1; }

prg=$( basename "${0}" )
prg_dir=$( cd "$(dirname "$0")" ; pwd -P )

[ -r "/usr/local/etc/${prg%.*}.conf" ] && . "/usr/local/etc/${prg%.*}.conf"
[ -r "${prg_dir}/../etc/${prg%.*}.conf" ] && . "${prg_dir}/../etc/${prg%.*}.conf"
[ -r "${prg_dir}/${prg%.*}.conf" ] && . "${prg_dir}/${prg%.*}.conf"

while getopts ":c:d:" opt; do
    case $opt in
        c)
            [ ! -r "${OPTARG}" ] && die "Cannot read config file ${OPTARG}"
            ;;
        d)
            DAYS_TO_PRINT=${OPTARG}
            ;;
        \?)
            die "Invalid option: -$OPTARG"
            ;;
        :)
            die "Option -$OPTARG requires an argument"
            ;;
    esac
done

[ -z "${LOGGER}" ] && LOGGER=/bin/logger
[ -z "${LOGGER_INFO_PRIORTY}" ] && LOGGER_INFO_PRIORTY="user.notice"
[ -z "${LOGGER_WARN_PRIORTY}" ] && LOGGER_WARN_PRIORTY="user.notice"
[ -z "${LOGGER_ERROR_PRIORTY}" ] && LOGGER_ERROR_PRIORTY="user.err"
[ -z "${AWK}" ] && AWK=/bin/awk
[ -z "${DAYS_TO_PRINT}" ] && DAYS_TO_PRINT=21

info()
{
    if [ ${#} -eq 0 ]; then
        while read data; do
            ${LOGGER} -s -t ${LOGGER_TAG} -p ${LOGGER_INFO_PRIORTY} "INFORMATION: ${data}"
        done
    else
        ${LOGGER} -s -t ${LOGGER_TAG} -p ${LOGGER_INFO_PRIORTY} "INFORMATION: ${*}"
    fi
}

warn()
{
    if [ ${#} -eq 0 ]; then
        while read data; do
            ${LOGGER} -s -t ${LOGGER_TAG} -p ${LOGGER_WARN_PRIORTY} "WARN: ${data}"
        done
    else
        ${LOGGER} -s -t ${LOGGER_TAG} -p ${LOGGER_WARN_PRIORTY} "WARN: ${*}"
    fi
}

error()
{
    if [ ${#} -eq 0 ]; then
        while read data; do
            ${LOGGER} -s -t ${LOGGER_TAG} -p ${LOGGER_ERROR_PRIORTY} "ERROR: ${data}"
        done
    else
        ${LOGGER} -s -t ${LOGGER_TAG} -p ${LOGGER_ERROR_PRIORTY} "ERROR: ${*}"
    fi
}

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

while [ ${DAYS_TO_PRINT} -gt 0 ]; do
    _date_str="$( date --date=@${today} +'%a %d %b %Y' )"
    _today_short=$( ${ECHO} "${_date_str}" | ${AWK} '{print $1}')
    if [ "${_today_short}" != "Sat" -a "${_today_short}" != "Sun" ]; then
        echo "${_date_str}"
    fi
    DAYS_TO_PRINT=$(( DAYS_TO_PRINT - 1 ))
    today=$(( today + one_day ))
done

graceful_exit 0

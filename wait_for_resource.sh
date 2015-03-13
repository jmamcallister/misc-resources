#!/bin/sh

##
## wait_for_resource.sh
##
## Waits for a configurable amount of time for a defined
## set of resource types. After the timeout period the
## script exits
##
## Currently supported:
##
## - directory
## - file
## - URL HTTP response body text matching
## - URL HTTP response code matching
##
##
## Arguments
##
##  -f <file>
##
##  -d <directory>
##
##  -u <url> [-r <response code> | -R <response text> ]
##
##      URL of a resource to wait for.
##
##      Default behaviour is to wait for response code '200' unless -r
##      is specified.
##
##      A URL with parameters, e.g., 'http://url/?key1=value1&key2=value2',
##      must be quoted (single or double)

ECHO="echo -e"
LOGGER_TAG="WAIT_FOR_RESOURCE"
RM=/bin/rm
GREP=/bin/grep
TMP_FILES=""

die() { ${ECHO} "FATAL: ${*}" >&2; exit 1; }

prg=$( basename "${0}" )
prg_dir=$( cd "$(dirname "$0")" ; pwd -P )

[ -r "/usr/local/etc/${prg%.*}.conf" ] && . "/usr/local/etc/${prg%.*}.conf"
[ -r "${prg_dir}/../etc/${prg%.*}.conf" ] && . "${prg_dir}/../etc/${prg%.*}.conf"
[ -r "${prg_dir}/${prg%.*}.conf" ] && . "${prg_dir}/${prg%.*}.conf"

uflag=false
dflag=false
fflag=false
Rflag=false

FILENAME=
DIRNAME=
URL=
RESPONSE_CODE=
RESPONSE_BODY=

while getopts ":c:d:f:i:m:u:r:R:" opt; do
    case $opt in
        c)
            [ ! -r "${OPTARG}" ] && die "Cannot read config file ${OPTARG}"
            . "${OPTARG}"
            ;;
        d)
            DIRNAME=${OPTARG}
            dflag=true
            ;;
        f)
            FILENAME=${OPTARG}
            fflag=true
            ;;
        i)
            INTERVAL=${OPTARG}
            ;;
        m)
            MAX_RETRIES=${OPTARG}
            ;;
        r)
            if ! ${uflag}; then
                die "-r option requires -u to be set"
            fi
            RESPONSE_CODE=${OPTARG}
            ;;
        R)
            if ! ${uflag}; then
                die "-R option requires -u to be set"
            fi
            RESPONSE_BODY=${OPTARG}
            Rflag=true
            ;;
        u)
            URL=${OPTARG}
            uflag=true
            ;;
        \?)
            die "Invalid option: -${OPTARG}"
            ;;
        :)
            die "Option -${OPTARG} requires an argument"
            ;;
    esac
done

[ -z "${LOGGER}" ] && LOGGER=/bin/logger
[ -z "${LOGGER_INFO_PRIORTY}" ] && LOGGER_INFO_PRIORTY="user.notice"
[ -z "${LOGGER_WARN_PRIORTY}" ] && LOGGER_WARN_PRIORTY="user.notice"
[ -z "${LOGGER_ERROR_PRIORTY}" ] && LOGGER_ERROR_PRIORTY="user.err"
[ -z "${CURL}" ] && CURL=/usr/bin/curl
[ -z "${INTERVAL}" ] && INTERVAL=5
[ -z "${MAX_RETRIES}" ] && MAX_RETRIES=12
[ -z "${RESPONSE_CODE}" ] && RESPONSE_CODE=200

MAX_RETRIES_ORIGINAL=${MAX_RETRIES}

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

wait_for_true()
{
    until eval "${1}"; do
        if [ ${MAX_RETRIES} -gt 0 ]; then
            info "Resource not found, waiting for ${INTERVAL}s ${MAX_RETRIES} more times"
            sleep ${INTERVAL}
            MAX_RETRIES=$((MAX_RETRIES-1))
        else
            info "Resource not available in $(( INTERVAL * MAX_RETRIES_ORIGINAL ))s"
            return 1
        fi
    done
    info "Resource found: ${1}"
    return 0
}

if ${fflag}; then
    _test="[ -f ${FILENAME} ]"
elif ${dflag}; then
    _test="[ -d ${DIRNAME} ]"
elif ${uflag}; then

    if ${Rflag}; then
        _curl_cmd="${CURL} -k --max-time 2 -s '${URL}'"
        _test="${_curl_cmd} | ${GREP} '${RESPONSE_BODY}' > /dev/null 2>&1"
    else
        _curl_cmd="${CURL} -k --max-time 2 -w %{http_code} -o /dev/null -s ${URL}"
        _test="[ $( ${_curl_cmd} ) -eq ${RESPONSE_CODE} ]"
    fi

fi

[ ! -z "${_test}" ] && wait_for_true "${_test}"

graceful_exit ${?}

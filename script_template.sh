#!/bin/bash
##
## Template for bash scripts
##

ECHO="echo -e"
LOGGER_TAG="YOUR_PROG"
RM=/bin/rm
TMP_FILES=""

#######################################
# Action : 
#   Exit script with failure status and
#   print message to stdout
# Globals:
#   ECHO
# Arguments:
#   Message string
# Returns:
#  
#######################################
die() { ${ECHO} "FATAL: $@" >&2; exit 1; }

prg=$( basename "${BASH_SOURCE[0]}" )
prg_dir=$( cd `dirname "${BASH_SOURCE[0]}"` && pwd )

[ -r "${prg_dir}/${prg%.*}.conf" ] && . "${prg_dir}/${prg%.*}.conf"
[ -r "${prg_dir}/../etc/${prg%.*}.conf" ] && . "${prg_dir}/../etc/${prg%.*}.conf"

while getopts ":c:" opt; do
    case $opt in
        c)
            [ ! -r "${OPTARG}" ] && die "Cannot read config file ${OPTARG}"
            . ${OPTARG}
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

#######################################
# Action : 
#   Log at INFO level
# Globals:
#   LOGGER
#   LOGGER_TAG
#   LOGGER_INFO_PRIORTY
# Arguments:
#   Message string
# Returns:
#  
#######################################
info()
{
    if [ ${#} -eq 0 ]; then
        while read data; do
            ${LOGGER} -s \
                -t ${LOGGER_TAG} \
                -p ${LOGGER_INFO_PRIORTY} "INFORMATION: ${data}"
        done
    else
        ${LOGGER} -s \
            -t ${LOGGER_TAG} \
            -p ${LOGGER_INFO_PRIORTY} "INFORMATION: $@"
    fi
}

#######################################
# Action : 
#   Log at WARN level
# Globals:
#   LOGGER
#   LOGGER_TAG
#   LOGGER_INFO_PRIORTY
# Arguments:
#   Message string
# Returns:
#  
#######################################
warn()
{
    if [ ${#} -eq 0 ]; then
        while read data; do
            ${LOGGER} -s \
            -t ${LOGGER_TAG} \
            -p ${LOGGER_WARN_PRIORTY} "WARN: ${data}"
        done
    else
        ${LOGGER} -s \
            -t ${LOGGER_TAG} \
            -p ${LOGGER_WARN_PRIORTY} "WARN: $@"
    fi
}

#######################################
# Action : 
#   Log at ERROR level
# Globals:
#   LOGGER
#   LOGGER_TAG
#   LOGGER_INFO_PRIORTY
# Arguments:
#   Message string
# Returns:
#  
#######################################
error()
{
    if [ ${#} -eq 0 ]; then
        while read data; do
            ${LOGGER} -s \
                -t ${LOGGER_TAG} \
                -p ${LOGGER_ERROR_PRIORTY} "ERROR: ${data}"
        done
    else
        ${LOGGER} -s \
            -t ${LOGGER_TAG} \
            -p ${LOGGER_ERROR_PRIORTY} "ERROR: $@"
    fi
}

#######################################
# Action : 
#   Perform cleanup tasks before
#   exiting script
#   - Remove any temporary files
# Globals:
#   RM
#   TMP_FILES
# Arguments:
#   None
# Returns:
#  
#######################################
cleanup()
{
    for _file in ${TMP_FILES}; do
        ${RM} -f ${_file} || warn "Could not remove file [ ${_file} ]"
    done
}

#######################################
# Action : 
#   - Log info or error message
#   - Perform clean tasks
#   - Exit script with provided status
#     code
# Globals:
#   None
# Arguments:
#   1 - Status code to exit with
#   2 - (Optional) Message to log
# Returns:
#  
#######################################
graceful_exit()
{
    [ "${#}" -gt 1 -a "${1}" -eq 0 ] && info "${2}"
    [ "${#}" -gt 1 -a "${1}" -gt 0 ] && error "${2}"
    cleanup
    exit ${1}
}

graceful_exit 0 "It worked!"

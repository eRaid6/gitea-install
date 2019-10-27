#!/usr/bin/env bash

# Uninstall Gitea on CentOS 7/RHEL 7
# Uninstalls Gitea that was installed by 'gitea-install.sh'

# variables
PROG_NAME=$(/bin/basename "$0" | cut -d . -f1)                                  
LOGFACILITY="local7"                                                            
LOGLEVEL="notice"

# Standard logging
logmessage() {                                                                     
    msg="${1}"                                                                     
    logger -p ${LOGFACILITY}.${LOGLEVEL} -t "${PROG_NAME}" "${msg}"                  
    echo "$(date) $(uname -n) ${PROG_NAME}: ${msg}"                                
}

# Debug logging
function debugecho() {                                                             
    [[ $VERBOSE ]] && logmessage "$@"                                              
}                                                                                  

# Help/usage
function usage() {
	echo "usage: ${PROG_NAME} -v"
	exit 1
}

# Command line options
while getopts "hv" o 2>/dev/null; do                                            
    case "${o}" in                                                              
        v)                                                                      
            VERBOSE=1                                                           
            ;;                                                                  
        h)                                                                      
            usage                                                               
            ;;                                                                  
        *)                                                                      
            usage                                                               
            ;;                                                                  
    esac                                                                        
done

# Check current user permissions
# we need root permissions to delete files
WHOAMI=$(whoami)
# Determine if we are root user or not
if [[ "$WHOAMI" != "root" ]]; then
        logmessage "This script needs to be run as root or with sudo, exiting"
        exit 1
else
        debugecho "current user has correct permissions"
fi

# Stop gitea
systemctl stop gitea >> /dev/null 2>&1
# Remove systemd unit file
rm -f /etc/systemd/system/gitea.service >> /dev/null 2>&1
systemctl daemon-reload >> /dev/null 2>&1
# Remove configuration directory
rm -rf /etc/gitea >> /dev/null 2>&1
# Remove data, logging and custom directory
rm -rf /var/lib/gitea/ >> /dev/null 2>&1
# Remove binary
rm -f /usr/local/bin/gitea >> /dev/null 2>&1

# The end
debugecho 'the end'
exit 0

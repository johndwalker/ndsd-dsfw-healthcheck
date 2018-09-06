#!/bin/bash
#######################################################################################
# Novell Inc.
# 1800 South Novell Place
# Provo, UT 84606-6194
# Script Name:      ndsd_dsfw_healthchk.sh
# Description:      This script can be used to do a basic health check on DSfW.  
#  			                              
# %Version:         3.1
# %Creating Date:   Monday Oct 2 07:37:24 MDT 2012
# %Created by:      Rance Burker - Novell Technical Services
# %Modified on:     Mon Aug 29 17:34:41 MDT 2012
# %Modified by:     Rance Burker - Novell Technical Services
# %Modified on:     Friday Jan 18 07:32:45 MST 2013
# %Change log:      Added more TID suggestions and ndstrace heatbeat
# %Modified by:     Rance Burker - Novell Technical Services
# %Change log:      Added e-mail option, eDir healthcheck,
# %Modified on:     Saturday Jan 26 12:27:05 MST 2013  
# %Modified by:     Rance Burker - Novell Technical Services
# %Change log:      Added GSS-SPNEGO,DNSCHK (for adc not running dns), and eDir/DSfW check
#                   The script is now compatible with eDir servers and DSfW servers  
# %Modified on:     Monday March 11 15:27:54 MDT 2013  
# %Modified by:     Rance Burker - Novell Technical Services
# %Change log:      Fixed nslookup tasks
# %Modified on:     Monday March 14 17:44:22 MDT 2013  
# %Modified by:     Rance Burker - Novell Technical Services
# %Change log:      Changed kdc.log reporting and e-mail settings
# %Modified on:     Tuesday April 11 10:5:20 MDT 2013  
# %Modified by:     Sebastian Lukasz and Rance Burker
# %Change log:      Added SLES, OES, and DS versioning info, along with more eDir checks
# %Modified on:     Fri Apr 26 12:12:26 MDT 2013
# %Modified by:     Rance Burker
# %Change log:      Added full path to ndsconfig and ifconfig
# %Modified on:     Tue May 28 17:04:49 MDT 2013
# %Modified by:     Rance Burker
# %Change log:      CRON_SETTING,FSMO, Parameters, Validate the Partition List, duplicateobjectsids, changed case for variables
# %Modified on:     Saturday July 6 10:38:04 MDT 2013
# %Modified by:     Rance Burker 
# %Change log:      Validate Partitions and containers with computer objects have password policies, added backup options, prompts to fix issues, and error count
# %Modified on:     Friday July 19 14:30:22 MDT 2013
# %Modified by:     Aaron Burgermister and Rance Burker
# %Change log:      Fix bug with Validate Partitions and containers when a space is in the container name
# %Modified on:     Wednesday July 24 07:05:11 MDT 2013
# %Modified by:     Rance Burker
# %Change log:      Added NetBIOS check
# %Modified on:     Thu Aug  1 17:51:48 MDT 2013
# %Modified by:     Rance Burker
# %Change log:      update copyies settings
# %Modified on:     Wed Mar 12 18:48:03 MDT 2014
# %Modified by:     Rance Burker
# %Change log:      Fixed duplicateUID task and rpcclient ncalrpc task
# %Modified on:     Sat Mar 15 16:39:55 MDT 2014
# %Modified by:     Rance Burker
# %Change log:      Added configuration menu, restore option, additional checks like guid, and more options to enable or disable
# %Modified on:     Fri May 23 06:02:34 MDT 2014
# %Modified by:     Rance Burker (Tyler Harris and Shane Neilson with auto update)
# %Change log:      Added check for dib backup, GPO comparison checks, auto update and option for uidNumbers to be displayed or not
#                   Total, clasify, and report errors and task.  Colored TID suggestions
#
#######################################################################################
#                 User Configuration Section
#######################################################################################
# Set CRON_SETTING=1 to run script as a cron job.  Run with cron switch to enable, but not hard set
CRON_SETTING=0

# Set AUTO_UPDATE=1 checks for newer version and updates. Set to 0 to disable or 1 to enable
AUTO_UPDATE=1

# ADD_JOB is the setting put into the crontab.  Must have $0 cron or $0 cron_all at the end. cron or cron_all are acceptable
ADD_JOB="0 05 * * * $0 na"

# Run dsbk every Sunday at 4:00 - Options are bk_dib, bk_nds, bk_dsbk, or bk_all
ADD_BACKUP_JOB="0 03 * * 0 $0 bk_dsbk"

# Backup dib and nici.  Set to 0 to disable or 1 to enable
# Setting to 1 will skip healthcheck and perform backups depending on settings below
BACKUP_NDSD=0

# ndsbackup user
ADMNUSER="admin.novell"

# Backup directory/var/opt/novell/eDirectory/backup # Backup directory
BACKUP_DIR_NDSD="/var/opt/novell/eDirectory/backup"

# Backup dib and nici directories along with conf files.  Set to 0 to disable or 1 to enable
BACKUP_NDS_DIB=0

# Check for dib backup file when script finishes.  Set to 0 to disable or 1 to enable
CHECK_NDS_DIB=1

# Backup eDirectory using dsbk
BACKUP_NDS_DSBK=0

# Password used by dsbk to backup nici
NICIPASSWD="novell"

# Backup eDirectory using ndsbackup
BACKUP_NDS_NDSBACKUP=0

# Number of days to keep backups
BACKUP_KEPT="40"

# Set EMAIL_SETTING to 1 to send e-mail log when finished.  Set to 0 to disable or 1 to enable
EMAIL_SETTING=0

# Set EMAIL_ON_ERROR to 1 to send e-mail log if an error is returned.  Set to 0 or remove the 1 to disable
EMAIL_ON_ERROR=1

# Set CHK_DISK_SPACE to the minimume size (in Gigabytes) before a warning is listed: Default 5
CHECK_DISK_SPACE=5

# Set OBIT_CHECK to 1 to check for obits.  Set to 0 to disable or 1 to enable
OBIT_CHECK=1

# Set EXREF_CHECK to 1 to check for external references.  Set to 0 to disable or 1 to enable
EXREF_CHECK=1

# Set HOST_FILE_CHECK to 1 to check host file.  Set to 0 to disable or 1 to enable
HOST_FILE_CHECK=1

# Set REPLICA_SYNC to 1 to run replica sync check.  Set to 0 to disable or 1 to enable
REPLICA_SYNC=1

# Set NTP_CHECK to 1 to run ntp checks.  Set to 0 to disable or 1 to enable
NTP_CHECK=1

# Set TIME_SYNC to 1 to run time sync check.  Set to 0 to disable or 1 to enable
TIME_SYNC=1

# Set REPAIR_NETWORK_ADDR to 1 to run repair network addresses.  Set to 0 to disable or 1 to enable
REPAIR_NETWORK_ADDR=0

# Set SCHEMA_SYNC to 1 to check schema synchronization.  Set to 0 to disable or 1 to enable
SCHEMA_SYNC=0

# Use this in conjuction with SCHEMA_SYNC.  If schema sync fails it is possible the trace ended before schema sync was finished.
SYNC_TIME=10

# Set DISPLAY_FSMO to 1 to display the server(s) assinged to FSMO Roles.  Set to 0 to disable or 1 to enable
DISPLAY_FSMO=1

# Set REPAIR_LOCAL_DB to 1 to run ndsrepair -R.  Set to 0 to disable or 1 to enable
REPAIR_LOCAL_DB=0

# Set DISPLAY_PARTITIONS to 1 to run ndsrepair -P.  Set to 0 to disable or 1 to enable
DISPLAY_PARTITIONS=1

# Set DISPLAY_UNKNOWN_OBJECTS to 1 to search for unknown objects, must have replica of root.  
DISPLAY_UNKNOWN_OBJECTS=1

# Set DUP_UIDNUMBER to 1 to search for duplicate uidNumbers.  
DUP_UIDNUMBER=0

# Set ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS to 1 so not prompted for user and password.  
# Only used if displayunknownobjects=1.  Set to 0 to disable or 1 to enable
ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS=1

# Enter a base context to start the search for unknown objects in a specific container.
# Example "ou=prc,o=novell", default will do root dse search
BASE=""

# $EMAIL_TO is the recipient of the e-mail.  For two or more addresses seperate each address with a ,
EMAIL_TO="dsfwdude@gmail.com"

# Set RESET_LOG to 1 to reset the health check log.  Set to 0 to disable or 1 to enable
RESET_LOG=1

# Set LOGTOSYSLOG to 1 to send messages to /var/log/messages syslog
LOGTOSYSLOG=1

# Store administrators credentials in casa
ADM_CASA=1

# END of User Configuration Section
#######################################################################################
#Colors
RED='\e[1;31m' #Bold Red
red='\e[31m' # Red
GREEN='\e[1;32m' #Bold Green
green='\e[32m' #Green
YELLOW='\e[1;33m' #Bold Yellow
yellow='\e[33m' #Yellow
BCYAN='\e[1;36m' # Cyan
URED='\e[4;91m' #Underline Red
UGREEN='\e[4;92m' #Underline Green
BOLD='\e[1m'  #Bold
UBOLD=`tput bold; tput smul` #Underline Bold
#`tput sgr0`
STRIKE='\e[9m' # Strike
BLINKON='\e[5m' # Blinking
NC='\e[0m' # No Color - default
#######################################################################################
# Display ASCII art
clear
echo ' ___   ___   __ __      __  ___            __                      '
echo '|   \ / __| / _|\ \    / / / _ \ __ __ ___/ /___    __  ___  __ __ '
echo '| |) |\__ \|  _| \ \/\/ / / // // // // _  // -_)_ / _|/ _ \|     |'
echo '|___/ |___/|_|    \_/\_/ /____/ \_,_/ \_,_/ \__/(_)\__|\___/|_|_|_|'
echo '                                                                   '

echo -e "Run ${BOLD}$(basename $0) -l${NC} to list configuration options"
echo -e "Run ${BOLD}$(basename $0) -h${NC} to see all script options"
sleep 1

# check user is root
if [[ $EUID -ne 0 ]]; then
        echo "You must be root to run this script"
        exit 1
fi

#######################################################################################
#                                VARIABLES 
#######################################################################################
# Script Info
SCRIPT_NAME=ndsd_dsfw_healthchk
SCRIPT_VERSION=3.01-8
SCRIPT_BINARY_VERSION=3018

# kill script function
die(){ echo "$@" 1>&2 ; exit 999; }

# Quick sanity check
[ ! -x /sbin/ifconfig ] && die "ifconfig command not found."
[ ! -x /usr/bin/mutt ] && EMAIL_ON_ERROR=0 && EMAIL_SETTING=0 && echo "mutt command not found."
[ ! -x /sbin/pidof ] && echo "pidof command not found."
[ ! -x /bin/logger ] && LOGTOSYSLOG=0 && echo "logger command not found."
[ ! -x /usr/sbin/ntpq ] && NTP_CHECK=0 &&echo "ntpq command not found."
[ ! -x /bin/hostname ] && echo "hostname command not found."
[ ! -x /usr/bin/crontab ] && echo "crontab command not found."
[ ! -x /bin/mktemp ] && echo "mktemp command not found"
[ ! -x /usr/bin/basename ] && echo "basename command not found"

# IPADDR get ip address.
IPADDR=$(/sbin/ifconfig | grep 'inet addr:'| cut -d: -f2 | awk '{ print $1}'|head -1) #> /dev/null 2>&1

# $SERVER_NAME and $DOMAIN is a variable for populating the alert email as to the server and domain
SERVER_NAME=`/usr/bin/perl -e '$srv = \`/bin/hostname\`; print uc($srv);'`
DOMAIN=`/usr/bin/perl -e '$dom = \`/bin/dnsdomainname\`; print uc($dom);'`

# $EMAIL_SUB is is the subject of the email.
EMAIL_SUB="eDir/DSfW Healthcheck for $SERVER_NAME at $DOMAIN ($IPADDR)"

# Set host, hostipaddr, and resolveipaddr 
HOST=`/bin/hostname`
HOSTS_IPADDR=$(grep -m1 $IPADDR /etc/hosts |cut -d ' ' -f1) #> /dev/null 2>&1
RESOLV_IPADDR=$(grep -m1 $IPADDR /etc/resolv.conf |cut -d ' ' -f2)

XADINST=0
if [ -f /etc/init.d/xadsd ]; then XADINST=1; fi

LDAPSEARCH=/usr/bin/ldapsearch

# Check if SLES or Redhat server
if [ -f /etc/SuSE-release ]; then suse_release=$(cat /etc/SuSE-release); fi
if [ -f /etc/redhat-release ]; then redhat_release=$(cat /etc/redhat-release); fi

# Check if OES is installed
if [ -f /etc/novell-release ]; then novell_release=$(cat /etc/novell-release); fi

# Check if eDir is installed and running, if so set variables
if [ -d /etc/opt/novell/eDirectory/conf/.edir ] &&  test `pidof ndsd`; then
    #if [ `pidof ndsd|awk -F " " '{ print $1 }'` -gt "0" ]; then
    DS_VERSION=$(/etc/init.d/ndsd status |awk /'Product/ {print $6,$7,$8}')
    DS_BINARY=$(/etc/init.d/ndsd status |awk /'Binary/ {print $3}')
    DS_SERVER=$(/etc/init.d/ndsd status |awk /'Server/ {print $3}')
    CONF_DIR=$(grep -m1 ^n4u.server.configdir /etc/opt/novell/eDirectory/conf/nds.conf | awk -F"configdir=" '{print $2}'|grep -v ^$)
    if [ $? -eq "1" ]; then
        if test `pidof ndsd`; then
        CONF_DIR=$(/opt/novell/eDirectory/bin/ndsconfig get n4u.server.configdir | awk -F"configdir=" '{print $2}'|grep -v ^$);
        fi
    fi
    VAR_DIR=$(grep -m1 ^n4u.server.vardir /etc/opt/novell/eDirectory/conf/nds.conf | awk -F"vardir=" '{print $2}'|grep -v ^$)
    if [ $? -eq "1" ];then
        if test `pidof ndsd`; then
        VAR_DIR=$(/opt/novell/eDirectory/bin/ndsconfig get n4u.server.vardir | awk -F"vardir=" '{print $2}'|grep -v ^$);
        fi
    fi
    LOG_DIR=$(grep -m1 ^n4u.server.log-file /etc/opt/novell/eDirectory/conf/nds.conf | awk -F"log-file=" '{print $2}' | awk -F"log" '{print $1}'|grep -v ^$)\log
    if [ $? -eq "1" ]; then
        if test `pidof ndsd`; then
        LOG_DIR=$(/opt/novell/eDirectory/bin/ndsconfig get n4u.server.log-file | awk -F"log-file=" '{print $2}' | awk -F"log" '{print $1}'|grep -v ^$)\log;
        fi
    fi
    LOG_FILE=$(grep -m1 ^n4u.server.log-file /etc/opt/novell/eDirectory/conf/nds.conf | awk -F"log" '{print $1}'|grep -v ^$)\log;
    if [ $? -eq "1" ]; then
        if test `pidof ndsd`; then
        LOG_FILE=$(/opt/novell/eDirectory/bin/ndsconfig get n4u.server.log-file | awk -F"log" '{print $1}'|grep -v ^$)\log
        fi
    fi
    DIB_DIR=$(grep -m1 ^n4u.nds.dibdir /etc/opt/novell/eDirectory/conf/nds.conf | awk -F"dibdir=" '{print $2}'|grep -v ^$);
    if [ $? -eq "1" ]; then
        if test `pidof ndsd`; then
        DIB_DIR=$(/opt/novell/eDirectory/bin/ndsconfig get n4u.nds.dibdir  | awk -F"dibdir=" '{print $2}'|grep -v ^$)
        fi
    fi
    NCP_INTERFACE=$(grep -m1 ^n4u.server.interfaces /etc/opt/novell/eDirectory/conf/nds.conf |awk -F"interfaces=" '{print $2}' |cut -f 1 -d @ |grep -v ^$);
    if [ $? -eq "1" ]; then
        if test `pidof ndsd`; then
        NCP_INTERFACE=$(/opt/novell/eDirectory/bin/ndsconfig get n4u.server.interfaces |awk -F"interfaces=" '{print $2}' |cut -f 1 -d @ |grep -v ^$)
        fi
    fi
fi # END Check if eDir is installed, if so set variables

# Check if eDir is running
  if [[ $1 = -l ]] || [[ $1 = --logs ]] || [[ $1 = -h ]] ||[[ $1 = --help ]] || [[ $1 = -r ]]; then
      echo > /dev/null
  elif test `pidof ndsd`; then
      echo > /dev/null
  else
      TIMELIMIT=20
     #read -t $TIMELIMIT REPLY # set timelimit on REPLY
      echo "eDirectory (ndsd) is not running"
      echo -ne "Do you want continue? (Y/n): "
      read -t $TIMELIMIT REPLY # set timelimit on REPLY
      if [ -z "$REPLY" ]; then
          rcndsd restart
      else
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
              echo;
          else
              echo -ne "Do you want restart eDirectory? (Y/n): "
              read REPLY
              if [[ $REPLY =~ ^[Yy]$ ]]; then
                  rcndsd restart
                  echo
                  sleep 2
              fi
          fi
      fi
  fi
# END Check if eDir is installed, if so set variables

# Check if xad is installed, export paths for secure binds
if [ -f /etc/init.d/xadsd ]; then
export _LIB=`/opt/novell/xad/share/dcinit/printConfigKey.pl "_Lib"`
export SASL_PATH=/opt/novell/xad/$_LIB/sasl2
export LDAPCONF=/etc/opt/novell/xad/openldap/ldap.conf
fi

# Check if DNS is set to start
DNSCHK=`find /etc/init.d/rc3.d/ -name S[0-9][0-9]novell-named`
if [[ -s $DNSCHK ]]; then DNSSTATUS=1; else DNSSTATUS=0; fi

# Update script
UPDATE_FILE="ndsd_dsfw_healthchk-update.sh"
UPDATE_URL="http://dsfwdude.com/downloads/${UPDATE_FILE}"
BACKUP_FILE=$0.`date +%F_time-%H:%M`.version-${SCRIPT_VERSION}.bk
THIS_FILE=$0
ARG=$1

#######################################################################################
#                                FUNCTIONS 
#######################################################################################
# e-Mail address setting displayed
emailSetting(){
    echo -e ""
    echo -e "To see script options run ${BOLD}${THIS_FILE} -h${NC}"
    echo -e "To change configuration options run${BOLD} ${THIS_FILE} -l${NC}\n"
}

# Send e-Mail function
sendEmail(){
    echo -e "Healtcheck script "$(basename $0)"\n\n""Completed healthcheck on server "$SERVER_NAME".\n $(cat $LOG)"| mutt -s "$EMAIL_SUB" "$EMAIL_TO" -a $LOG
 }  
# END-of-function send_email

# Logging to screen and logfile function
log(){
    setLogsToGather
    echo -e "$@"
    echo -e "$@"|sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" >> $LOG
}

#
dsfwCredentials(){
    if [ $XADINST -eq 1 ] && [ $CRON_SETTING -eq 0 ] && [ $BACKUP_NDSD -eq 0 ]; then
       echo
       echo -en "Please enter Administrator's password: "
       read -s ADMPASSWD
    fi
}

# set Administator in CASA
setAdministratorCasa(){
    if [[ -z $ADMPASSWD ]]; then
        LUM_PROXY_USERF=`grep CONFIG_LUM_PROXY_USER /etc/sysconfig/novell/lum* |cut -d '"' -f2`;
        if [[ ! -z $LUM_PROXY_USERF ]]; then
               ADM_CASA=0
        fi
        if [[ $ADM_CASA = 1 ]]; then
                if [[ -f /usr/sbin/rcmicasad ]]; then
                        /usr/sbin/rcmicasad status 1>&2 > /dev/null
                        if [ $? = "0" ]; then
                                CASA_RUNNING="true"
                        else
                                CASA_RUNNING="false"
                        fi
                fi
                if [ $CASA_RUNNING = "false" ]
                then
                        /usr/sbin/rcmicasad start
                fi
                echo -en "Please enter Administrator's password: "
                read -s ADMPASSWD
                echo
                KEYVALUE=${ADMPASSWD} CASAcli -s -n novell-lum -k Password
        else
                dsfwCredentials
        fi
    fi
}


# get administrator users credentials from novell-lum casa key
getAdministratorCasa(){
    if [ $XADINST -eq 1 ] && [ $CRON_SETTING -eq 0 ] && [ $BACKUP_NDSD -eq 0 ] && [ $ADM_CASA -eq 1 ]; then
        LUM_PROXY_USERF=`grep CONFIG_LUM_PROXY_USER /etc/sysconfig/novell/lum* |cut -d '"' -f2`;
        if [[ -z $LUM_PROXY_USERF ]]; then
            > /var/lib/novell-lum/pass.txt
            /usr/bin/lum_retrieve_proxy_cred password /var/lib/novell-lum/pass.txt
            ADMPASSWD=`cat /var/lib/novell-lum/pass.txt`
#            /opt/novell/proxymgmt/bin/oes-enc-dec 
            rm /var/lib/novell-lum/pass.txt
            if [[ -z ${ADMPASSWD} ]]; then
                setAdministratorCasa
            fi
        else
            ADM_CASA=0
            dsfwCredentials
        fi
    fi
}

getAdminUser(){
       # get credentials from CASA novell-lum keys
        > /var/lib/novell-lum/user.txt
        > /var/lib/novell-lum/pass.txt
        /usr/bin/lum_retrieve_proxy_cred username /var/lib/novell-lum/user.txt
        /usr/bin/lum_retrieve_proxy_cred password /var/lib/novell-lum/pass.txt
        ADMUSER=`cat /var/lib/novell-lum/user.txt`
        ADMPASSWD=`cat /var/lib/novell-lum/pass.txt`
#        /opt/novell/proxymgmt/bin/oes-enc-dec
        rm /var/lib/novell-lum/user.txt
        rm /var/lib/novell-lum/pass.txt
}

# log location
setLogsToGather(){
    if [ $XADINST -eq 1 ]; then
       LOG=/var/opt/novell/xad/log/dsfw_healthchk.log
       DSREPAIR_LOG=/var/opt/novell/eDirectory/log/ndsrepair.log
    else
       LOG=$LOG_DIR/ndsd_healthchk.log
       DSREPAIR_LOG=$LOG_DIR/ndsrepair.log
    fi
    MESSAGES_LOG=/var/log/messages
    NDSD_LOG=${LOG_DIR}/ndsd.log
    #NDSD_LOG=$(/opt/novell/eDirectory/bin/ndsconfig get n4u.server.log-file |grep -v ^$)
    LOGGER="/bin/logger -t ndsd_health_check"
}

# ndsrepair -N Repair Network Addresses
reparinetworkaddress() {
/opt/novell/eDirectory/bin/ndsrepair -N <<ENDR
1
1
ENDR
}

# ndsrepair -P Display Partitions - if more than 5 partitions put ENTER before the q.  If more than 10 and a second ENTER.
displaypartitions() {
/opt/novell/eDirectory/bin/ndsrepair -P <<ENDR
ENDR
}

# Get IP Address
getip(){
    ifconfig | grep 'inet addr:'| cut -d: -f2 | awk '{ print $1}'|head -1
}

# Credentials for admin user in LDAP syntax 
dscredentials(){
    clear
    echo -ne "Enter admin user  (cn=admin,o=novell): "
    read ADMUSER
    clear
    echo -e The user is $ADMUSER
    echo -ne "Enter user's password: "
    read -s ADMPASSWD
    echo
    sleep 1
}

# add to crontab
addToCron(){
    TMP_FILE=`mktemp`
    trap 'rm $TMP_FILE; ' EXIT
    RES=0
    /usr/bin/crontab -l >> $TMP_FILE
    grep "$(basename $0) na" $TMP_FILE >> /dev/null
    JOB_NOT_EXIST=$?
    if test $JOB_NOT_EXIST == 1; then
        echo "$ADD_JOB" >> $TMP_FILE
        /usr/bin/crontab $TMP_FILE >> /dev/null
        RES=$?
        echo 
        echo "$ADD_JOB added crontab"
        echo "Run crontab -l to view"
        echo "Run crontab -e to edit"
    else
        echo "$(basename $0) is already present in crontab"
        echo "Run crontab -l to view"
        echo "Run crontab -e to edit"
        RES=$?
    fi
    #rm $TMP_FILE
    exit $RES
}

# add backup to crontab
addToCronBk(){
    TMP_FILE=`mktemp`
    trap 'rm $TMP_FILE; ' EXIT
    RES=0
    /usr/bin/crontab -l >> $TMP_FILE
    grep "$(basename $0) bk" $TMP_FILE >> /dev/null
    JOB_NOT_EXIST=$?
    if test $JOB_NOT_EXIST == 1; then
        echo "$ADD_BACKUP_JOB" >> $TMP_FILE
        /usr/bin/crontab $TMP_FILE >> /dev/null
        RES=$?
        echo 
        echo "$ADD_BACKUP_JOB added crontab"
        echo "Run crontab -l to view"
        echo "Run crontab -e to edit"
    else
        echo "$(basename $0) is already present in crontab"
        echo "Run crontab -l to view"
        echo "Run crontab -e to edit"
        RES=$?
    fi
    #rm $TMP_FILE
    exit $RES
}

# Check diskspace warn if less than 5G
chkDiskSpace(){
    df -H | grep -vE '^udev|_admin|tmpfs|pool|cdrom|media|Filesystem' | awk '{ print $4 "  " $1 "  " $6}' | while read op;
    do
        log "    Size Filesystem Mounted"
        log "    $op"
        ug=$(echo $op | awk '{ print $1}' | sed 's/G//g' )
        partition=$(echo $op | awk '{ print $2 }' )
        RES=`echo "$ug >= $CHECK_DISK_SPACE" | bc`
        if [[ $RES == "0" ]]; then
            WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
            log "    $partition is low on disk space ($ug G)\n"
        else
            log "    ${GREEN}GOOD${NC}\n"
        fi
    done
}

# Timer countdown
timerCount(){
        for i in `seq $TIMELIMIT -1 1`; do k=1; echo -n " $i";
          read -t 1 k
          if [ "$k" != 1 ]; then
            k=2; break
          fi
        done
}

# DIB BACKUP
dibBk(){
#   log "    ${RED}Shutting down eDirectory${NC}"
    if test `uname -p` == x86_64; then # Must be 64 bit
    ndstrace -u > /dev/null 2>&1
#   /etc/init.d/ndsd stop
    log "${yellow}eDirectory must be stopped to continue with the backup (rcndsd stop)${NC}\n"
    TIMELIMIT=180
    echo -e "You have 3 minutes to make a decision"  #yes not to continue
    echo -e "The default action is proceed with the backup\n"  #yes not to continue
    echo -ne "Do you want to stop ndsd and backup the dib? (Y/n): "  #yes not to continue
    read -t $TIMELIMIT REPLY  # set timelimit on REPLY
    echo
    if [ -z "$REPLY" ]; then   # if REPLY is null then
        log "    ${RED}Shutting down eDirectory${NC}"
        /etc/init.d/ndsd stop
    elif [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "The dib was ${RED}not${NC} backed up"
        log "To disable this option do: ${BOLD}$(basename $0) -d${NC}"
        exit 0;
    else
        log "    ${RED}Shutting down eDirectory${NC}"
        /etc/init.d/ndsd stop
    fi
    tar -czf `date -I`_dib.tgz -C /var/opt/novell/eDirectory/data dib  -C /var/opt/novell nici -C /etc/opt/novell/eDirectory/conf/ nds.conf -C /etc/opt/novell/ nici.cfg -C /etc/opt/novell/ nici64.cfg -C /etc/opt/novell/eDirectory/conf/ ndsimon.conf -C /etc/init.d/ ndsd -C /etc/opt/novell/eDirectory/conf/ ndsmodules.conf

    /etc/init.d/ndsd start
    # Make backup directory
        if [ -d $BACKUP_DIR_NDSD ]; then
            &> /dev/null
        else
            /bin/mkdir -p $BACKUP_DIR_NDSD
        fi
    # Move dib tarball to backup
    mv `date -I`_dib.tgz $BACKUP_DIR_NDSD
    else
        echo Must be 64 bit for this backup option
        exit
    fi
    echo
    echo -e "The backup is located in $BACKUP_DIR_NDSD"
    echo -e "Backups are stored for $BACKUP_KEPT"
    echo -e "These parameters can be changed in the List Script Options Menu"
    echo -e "\t $(basename $0) -l"
    echo
    echo "Backups older than $BACKUP_KEPT days will be deleted"
    echo
    log "Checking for backups older than $BACKUP_KEPT days"
        # Remove old backups
        find $BACKUP_DIR_NDSD/*_dib.tgz -mtime +$BACKUP_KEPT >> /tmp/bkdib_del
        bklist=( `cat /tmp/bkdib_del` )
        for i in "${bklist[@]}"
            do
                log "    $i"
                # Clean up
                log "Deleting backups older than $BACKUP_KEPT days"
                rm ${i}
             done
        if [ ! -s /tmp/bkdib_del ]; then echo "No backups older than $BACKUP_KEPT days found"; fi
        rm /tmp/bkdib_del
}

# pause 'Press [Enter] key to continue ...'
pause(){
   read -p "$*"
}

# Top of script, display server info
serverInfo(){
#    clear
	log "\n\e[0;31m========================= ${NC}${BOLD}$SCRIPT_NAME $SCRIPT_VERSION\e[0;31m ==========================${NC}"
	log "Health Check on server: $(hostname)"
        log "Date: $(date) "
        log "IP Address: $IPADDR"
	log "---------------------------------------------------------------------------"
	log "Kernel Information: `uname -smr`"
	[ -f /etc/SuSE-release ] && log $suse_release
	[ -f /etc/redhat-release ] && log $redhat_release
	[ -f /etc/novell-release ] && log $novell_release
	if [ -d /etc/opt/novell/eDirectory/conf/.edir ]; then
	log "---------------------------------------------------------------------------"
	log "eDir Server: $DS_SERVER"
	log "eDir Version: $DS_VERSION"
	log "eDir Binary: $DS_BINARY"; fi
	log "\e[0;31m===========================================================================${NC}"
    [ $EMAIL_SETTING -eq 1 ] && emailSetting;
    echo
}

# ndsbackup user
#ADMNUSER
#NICIPASSWD
#EMAIL_SETTING
#EMAIL_ON_ERROR
# Toggle SCHEMA_SYNC setting

displaySettings(){
echo -e "Cron Job settings" `if [ "$ADD_JOB" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo
echo -e "Cron Job backup settings" `if [ "${ADD_BACKUP_JOB}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo
echo -e "Perform ndsd backups settings" `if [ "${BACKUP_NDSD}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo ndsbackup user $ADMNUSER
echo backukp directory $BACKUP_DIR_NDSD
echo
echo -e "Backup dib and nici directories along with conf files" `if [ "${BACKUP_NDS_DIB}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo
echo -e"Backup eDirectory using dsbk" `if [ "${BACKUP_NDS_DIB}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo
echo -e "Password used by dsbk to backup nici $NICIPASSWD"
echo
echo -e "Backup eDirectory using ndsbackup" `if [ "${BACKUP_NDS_NDSBACKUP}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo
echo -e "Number of days to keep backups ${BACKUP_KEPT}"
echo
echo -e "Always send e-mail" `if [ "${EMAIL_SETTING}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo 
echo -e "Send e-mail only when an error is reported" `if [ "${EMAIL_ON_ERROR}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo 

echo Perform repair network address setting `if [ "${BACKUP_NDS_NDSBACKUP}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`

echo Perform schema sync `if [ "${SCHEMA_SYNC}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo 
echo Amount of time for  trace to run `if [ "${SCHEMA_SYNC_TIME}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo 
echo -e "Display the FSMO roles" `if [ "${DISPLAY_FSMO}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo

echo Perform a local database repair `if [ "${REPAIR_LOCAL_DB}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo

echo Display partitions server holds `if [ "${DISPLAY_PARTITIONS}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo
echo -e "Report unknown objects (uses ldapsearch)" `if [ "${DISPLAY_UNKNOWN_OBJECTS}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo
echo Use anonymous bind to do the ldapsearch for unknown objects `if [ "${ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo The start of the ldapsearch 
echo $BASE

echo E-Mail address $EMAIL_TO

echo Reset the health check log before `if [ "${RESET_LOG}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo 

echo Send messages to /var/log/messages `if [ "${LOGTOSYSLOG}" == "1" ]; then echo ENABLED; else echo DISABLED; fi`
echo 

}

restoredsbk(){
((C++))

#bklist=(`ls -a`)
#len=${#bklist[*]}

#i=0
#while [ $i -lt $len ]; do
#echo "$i: ${array[$i]}"
#let i++
#done

#for i in $( ls -a $BACKUP_DIR_NDSD/*_dsbk.bak ); do
#echo "$i"
#done
echo
log "Restore eDirectory backup, ie: ${BOLD}dsbk restore -f $BACKUP_DIR_NDSD/`date -I`_dsbk.bak -l $BACKUP_DIR_NDSD/`date -I`_dsbk-restore.log -e $NICIPASSWD -t -w${NC}\n"
        RES=0
#        ls -a $BACKUP_DIR_NDSD/*_dsbk.bak


    bkarray=(`ls -r $BACKUP_DIR_NDSD/*_dsbk.bak`);
    len=${#bkarray[*]}
    b=1
    for i in ${bkarray[@]}; do
        echo -e " $b) $i" 
        ((b++))
#        echo -e " $len) $i "
#        len=$(expr $len - 1)
    done
        RES=$?
    echo #$RES
    if test $RES = 0; then
        t=0
        DSBK_RESTORE_FILE=""
        REPLY=""
        REGEX="^[0-9]{1,2}"

       #while [ -z $DSBK_RESTORE_FILE ] && [ $t -lt 3 ]; do
        while [ -z $REPLY ] && [ $t -lt 3 ]; do
            #read -ep "Please enter the dsbk restore file: " DSBK_RESTORE_FILE
            read -ep "Please select the dsbk restore file: " REPLY
            ((t++))
            if [  -z $REPLY ]; then
                echo No backup specified
                echo 
                REPLY=""
            elif [[ ! $REPLY =~ $REGEX ]];then
                echo Invalid selection
                echo A non numeric character was entered
                echo Must be a number from 1 to $len
                echo 
                REPLY=""
            elif [[ $REPLY > $len ]];then
                echo Invalid selection
                echo Must be a number from 1 to $len
                echo 
                REPLY=""
            else
                echo Selected $REPLY > /dev/null
            fi
        done
        if [  -z $REPLY ]; then
            echo Exiting, no backup specified
        else
            echo
            REPLY=$(expr $REPLY - 1)
            DSBK_RESTORE_FILE=${bkarray[$REPLY]}
        fi
        echo -e "Selected $DSBK_RESTORE_FILE\n"
        else
            echo There are no dsbk backups in $BACKUP_DIR_NDSD
            exit $RES
        fi


    bkarray=(`ls -r $BACKUP_DIR_NDSD/*restore.log`);
    len=${#bkarray[*]}
    b=1
    RES=$?
    if test $RES = 0; then
        t=0
        DSBK_RESTORE_LOG=""
        while [ -z $DSBK_RESTORE_LOG ] && [ $t -lt 3 ]; do
       #read -ep "Please enter the dsbk restore file: " DSBK_RESTORE_LOG
       #read -ep "Please enter the dsbk restore file: " REPLY

      #REPLY=$(expr $REPLY - 1)
            if [[ `echo ${bkarray[$REPLY]}| awk -F/ '{print $NF}'| cut -d "_" -f1` == `echo $DSBK_RESTORE_FILE | awk -F/ '{print $NF}'| cut -d "_" -f1` ]]; then
           DSBK_RESTORE_LOG=${bkarray[$REPLY]}
           ((t++))
        else
            for i in ${bkarray[@]}; do
                echo -e " $b) $i"
                ((b++))
            done
            echo
            REPLY=""
            while [ -z $REPLY ] && [ $t -lt 3 ]; do
                read -ep "Please enter the dsbk restore log: " REPLY
                ((t++))
            if [[ -z $REPLY ]]; then
                echo No backup log specified
                echo 
                REPLY=""
            elif [[ ! $REPLY =~ $REGEX ]];then
                echo Invalid selection
                echo A non numeric character was entered
                echo Must be a number from 1 to $len
                echo 
                REPLY=""
            elif [[ $REPLY > $len ]]; then
                echo Invalid selection
                echo Must be a number from 1 to $len
                echo 
                REPLY=""
            else
                echo Selected $REPLY > /dev/null
            fi
            done
            if [ -z $REPLY ];then
                echo Exiting, no backup log specified
                echo 
                exit
            else
                echo
                REPLY=$(expr $REPLY - 1)
                DSBK_RESTORE_LOG=${bkarray[$REPLY]}
                ((t++))
            fi
        fi
        done
                echo -e "Selected $DSBK_RESTORE_LOG\n"

                dsbk restore -f $DSBK_RESTORE_FILE -l $DSBK_RESTORE_LOG -e $NICIPASSWD -r -a -o -n -v -k
                sleep 10
                echo 
                echo -e "Viewing end of ndsd.log\n"
                tail $NDSD_LOG
                exit $RES
        else
                echo There are no dsbk backups in $BACKUP_DIR_NDSD
                exit $RES
        fi
}

# Set BACKUP_KEPT setting, days to keep backups
backupKept(){
    BACKUP_KEPT=""
    BACKUP_REGEX="^[0-9]{1,3}"
    while [[ ! $BACKUP_KEPT =~ $BACKUP_REGEX ]]; do
    echo -n "Enter days to keep backups (example 40): "
    read BACKUP_KEPT
    if [[ ! $BACKUP_KEPT =~ $BACKUP_REGEX ]];then
        echo 'Invalid input'
        echo 'Please enter a number'
    fi
    done
    echo " Keeping backups for ${BACKUP_KEPT} days"
    sleep .2
    sed -i "s/^BACKUP_KEPT=.*/BACKUP_KEPT=\"${BACKUP_KEPT}\"/g" ${THIS_FILE}
}

# Set EMail Recipient
changeEmailTo(){
    EMAIL_TO=""
    EMAIL_REGEX="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    while [[ ( ! $EMAIL_TO =~ $EMAIL_REGEX ) ]]; do
    echo -n "Enter an e-mail account: "
    read EMAIL_TO
    if [[ ( ! $EMAIL_TO =~ $EMAIL_REGEX ) ]];then
        echo 'Invalid input'
        echo 'Please use e-mail format: your@mail.com'
    fi
    done
    echo " The e-mail recipient is ${EMAIL_TO}"
    sleep .2
    sed -i "s/^EMAIL_TO=.*/EMAIL_TO=\"${EMAIL_TO}\"/g" ${THIS_FILE}
}


# Set sync time in seconds, how long to run trace
changeSyncTime(){
    SYNC_TIME=""
    SYNC_REGEX="^[0-9]{1,3}"
    while [[ ! $SYNC_TIME =~ $SYNC_REGEX ]]; do
    echo -n "Enter for schema sync to run in seconds: "
    read SYNC_TIME
    if [[ ! $SYNC_TIME =~ $SYNC_REGEX ]];then
        echo 'Invalid input'
        echo 'Please enter a number'
    fi
    done
    echo " The schema sync time is ${SYNC_TIME} seconds"
    sleep .2
    sed -i "s/^SYNC_TIME=.*/SYNC_TIME="${SYNC_TIME}"/g" ${THIS_FILE}
}

# Set search base
changeBaseSearch(){
    echo -n "Enter container to start the search (Example ou=prc,o=novell): "
    read BASE
    echo " The search will start at ${BASE}"
    sleep .2
    sed -i "s/^BASE=.*/BASE=\"${BASE}\"/g" ${THIS_FILE}
}

# Set ndsbackup user
changeNdsbackupUser(){
    echo -n "Enter ndsbackup user (example admin.novell): "
    read ADMNUSER
    echo " The ndsbackup user ${ADMNUSER}"
    sleep .2
    sed -i "s/^ADMNUSER=.*/ADMNUSER=\"${ADMNUSER}\"/g" ${THIS_FILE}
}

# Change BACKUP_DIR_NDSD setting
backupDirNdsd(){
    echo -n "Enter backup directory (example /var/opt/novell/eDirectory/backup): "
    read BACKUP_DIR_NDSD
    echo " The backup directory ${BACKUP_DIR_NDSD}"
    sleep .2
    sed -i "s:^BACKUP_DIR_NDSD=.*:BACKUP_DIR_NDSD=\"${BACKUP_DIR_NDSD}\":g" ${THIS_FILE}
}

# Change cron job for ADD_BACKUP_JOB setting
addNdsdBackupJob(){
    CRON_REGEX="^[0-9*]{1,2}\ [0-9*]{1,2}\ [0-9*]{1,2}\ [0-9*]{1,2}"
    echo -e "Enter eDirectory cronjob setting"
    echo -e 'You must have $0 and an option for the script to run properly'
    echo -e "Options are bk_dib, bk_nds, bk_dsbk, or bk_all"
    echo -n 'Example 0 03 * * 0 $0 bk_dsbk: '
    read ADD_BACKUP_JOB
    echo " The cronjob setting ${ADD_BACKUP_JOB}"
    if [[ -z "${ADD_BACKUP_JOB}" ]]; then
        echo applying default setting
        ADD_BACKUP_JOB="0 03 * * 0 \$0 bk_dsbk"
    elif [[ ! $ADD_BACKUP_JOB =~ $CRON_REGEX ]]; then
        addNdsdBackupJob
        echo invalid input
        echo 'input must conatin $0 and one of the bk options'
    fi
#    if [[ ${ADD_BACKUP_JOB} != .*'bk_dsbk' ]] || [[ ${ADD_BACKUP_JOB} != .*'bk_nds' ]] || [[ ${ADD_BACKUP_JOB} != .*'bk_nds' ]] || [[ ${ADD_BACKUP_JOB} != .*'bk_dsbk' ]] || [[ ${ADD_BACKUP_JOB} != .*'bk_all' ]]; then
#        addNdsdBackupJob
#        echo invalid input
#        echo 'input must conatin $0 and one of the bk options'
#    fi
    sleep .2
    sed -i "s:^ADD_BACKUP_JOB=.*:ADD_BACKUP_JOB=\"${ADD_BACKUP_JOB}\":g" ${THIS_FILE}
}

# Change cron job for ADD_JOB setting
addBackupJob(){
    CRON_REGEX="^[0-9*]{1,2}\ [0-9*]{1,2}\ [0-9*]{1,2}\ [0-9*]{1,2}"
    echo -e "Enter cronjob setting to run this script"
    echo -e 'You must have $0 for the script to run properly'
    echo -n 'Example 0 05 * * * $0 : '
    read ADD_JOB
    echo " The cronjob setting ${ADD_JOB}"
    if [[ -z "${ADD_JOB}" ]]; then
        echo applying default setting
        ADD_JOB="0 05 * * * \$0"
    elif [[ ! $ADD_JOB =~ $CRON_REGEX ]]; then
        echo 'invalid input: must conatin $0'
        addBackupJob
#    if ! echo "${ADD_JOB}" | grep -m1 ^ -q [0-9*]{1,2}\ [0-9*]{1,2}\ [0-9*]{1,2}\ [0-9*]{1,2}\ [0-9*]{1,2}\ ;
#    if [[ ! ${ADD_JOB} =~ $CRON_REG ]]; then
#        echo 'invalid input: must conatin cron syntax'
#        addBackupJob
    fi
    sleep .2
    sed -i "s:^ADD_JOB=.*:ADD_JOB=\"${ADD_JOB}\":g" ${THIS_FILE}
}


# Set EMail Recipient
changeNiciPasswd(){
    echo -n "Enter container to start the search (Example novell): "
    read NICIPASSWD
    echo " The search will start at ${NICIPASSWD}"
    sleep .2
    sed -i "s/^NICIPASSWD=.*/NICIPASSWD=\"${NICIPASSWD}\"/g" ${THIS_FILE}
}

# Toggle from 1 to 0 or 0 to1
toggle(){
   if [ "${VAR1}" == "0" ]; then
        sed -i "s/^$VAR2=.*/$VAR2=1/g" ${THIS_FILE}
        ${VAR2}=1 > /dev/null 2>&1
    else
        sed -i "s/^$VAR2=.*/$VAR2=0/g" ${THIS_FILE}
        ${VAR2}=0 > /dev/null 2>&1
    fi
}

# Status enabled is bold, else red
statusColorBoldRed(){
    if [ ${STATUS} = Enabled ]; then SCOLOR=${BOLD}; else SCOLOR=${RED}; fi
}

# Status enabled is green, else red
statusColorGreenRed(){
    if [ ${STATUS} = Enabled ]; then SCOLOR=${GREEN}; else SCOLOR=${RED}; fi
}

# listOption Menu - Configuration options
listOptions(){
    echo 
    echo -e "List Script Options"
    echo -e "Press the corresponding number to enable or disable\n"

    echo -e "Logging and e-mail options"
    if [[ ${AUTO_UPDATE} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}1)${NC}\tAuto update script${NC}\t\t${SCOLOR}${STATUS}      ${NC}\t"

    if [[ ${LOGTOSYSLOG} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}2)${NC}\tLog To /var/log/messages${NC}\t${SCOLOR}${STATUS}      ${NC}\t"

    if [[ ${RESET_LOG} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}3)${NC}\tReset Health Check Log${NC}\t\t${SCOLOR}${STATUS}${NC}";

    if [[ ${EMAIL_SETTING} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}4)${NC}\te-Mail Always${NC}\t\t\t${SCOLOR}${STATUS}${NC}"

    if [[ ${EMAIL_ON_ERROR} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}5)${NC}\te-Mail on Error${NC}\t\t\t${SCOLOR}${STATUS} ${NC}"

    echo -e "   ${BOLD}6)${NC}\tSend e-Mail To${NC}\t\t\t${BOLD}${EMAIL_TO} ${NC}"
    echo -e "        NOTE: sending e-Mails can cause the /root/sent file to grow in size ${NC}"
    echo -e "        To clear the file run ${BOLD}> /root/sent${NC}\n"

    echo -e "Checks and Repairs to perform"
    if [[ ${OBIT_CHECK} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}7)${NC}\tCheck for Obituaries${NC}\t\t${SCOLOR}${STATUS} ${NC}"

    if [[ ${EXREF_CHECK} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}8)${NC}\tCheck External References${NC}\t${SCOLOR}${STATUS} ${NC}"

    if [[ ${HOST_FILE_CHECK} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}9)${NC}\tCheck /etc/hosts file${NC}\t\t${SCOLOR}${STATUS} ${NC}"

    if [[ ${REPLICA_SYNC} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}10)${NC}\tCheck Replica Sync${NC}\t\t${SCOLOR}${STATUS} ${NC}"

    if [[ ${NTP_CHECK} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}11)${NC}\tCheck NTP${NC}\t\t\t${SCOLOR}${STATUS}${NC}"

    if [[ ${TIME_SYNC} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}12)${NC}\tCheck Time Synchronization${NC}\t${SCOLOR}${STATUS} ${NC}"

    if [[ ${REPAIR_NETWORK_ADDR} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}13)${NC}\tRepair Network Addresses${NC}\t${SCOLOR}${STATUS} ${NC}"

    if [ ${SCHEMA_SYNC} -eq 1 ]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}14)${NC}\tRun Schema Sync ${NC}\t\t${SCOLOR}${STATUS}${NC}"

    if [ ${REPLICA_SYNC} -eq 1 ] ||  [ ${SCHEMA_SYNC} -eq 1 ]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorBoldRed
    echo -e "   ${BOLD}15)${NC}\tLength of Time for Sync ${NC}\t  ${SCOLOR}${SYNC_TIME}${NC}"                   

    if [ ${DUP_UIDNUMBER} -eq 1 ]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}16)${NC}\tDisplay Duplicate uidNumbers${NC}\t${SCOLOR}${STATUS}      ${NC}\t";

    if [ ${REPAIR_LOCAL_DB} -eq 1 ]; then STATUS=Enabled; else STATUS=Disabled; fi
        statusColorGreenRed
    echo -e "   ${BOLD}17)${NC}\tRepair Local Database${NC}\t\t${SCOLOR}${STATUS}      ${NC}\t";

    if [ ${DISPLAY_PARTITIONS} -eq 1 ]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}18)${NC}\tDisplay Partitions${NC}\t\t${SCOLOR}${STATUS}      ${NC}\t";

    if [[ ${DISPLAY_UNKNOWN_OBJECTS} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}19)${NC}\tDisplay Unknown Ojbects${NC}\t\t${SCOLOR}${STATUS} ${NC}\t";

    if [[ ${ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS} -eq 1 ]] && [[ ${DISPLAY_UNKNOWN_OBJECTS} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}20)${NC}\tAnonymouse bind ${NC}\t\t${SCOLOR}${STATUS} ${NC}\t";

    if [ ${DISPLAY_UNKNOWN_OBJECTS} -eq 1 ]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorBoldRed
    if [ -z ${BASE} ]; then STATUS=rootdse; else STATUS=${BASE}; fi
    echo -e "   ${BOLD}21)${NC}\tStart search at ${NC}\t\t${SCOLOR}${STATUS}      ${NC}\t\n"
    echo -e "Backup options"
    if [[ ${CHECK_NDS_DIB} -eq 1 ]]; then STATUS=Enabled; else STATUS=Disabled; fi
    statusColorGreenRed
    echo -e "   ${BOLD}22)${NC}\tCheck for dib backup${NC}\t\t${SCOLOR}${STATUS} ${NC}\t";
    echo -e "   \t(when script finishes)${NC}";

    STATUS=Enabled
    statusColorBoldRed
    echo -e "   ${BOLD}23)${NC}\tThe ndsbackup user${NC}\t\t${SCOLOR}${ADMNUSER}${NC}";

    echo -e "   ${BOLD}24)${NC}\tPassword to backup NICI (dsbk)${NC}\t${SCOLOR}${NICIPASSWD}${NC}";

    echo -e "   ${BOLD}25)${NC}\tLocation of backup tarballs${NC}\t${SCOLOR}${BACKUP_DIR_NDSD}${NC}";

    echo -e "   ${BOLD}26)${NC}\tDays to keep backups${NC}\t\t  ${SCOLOR}${BACKUP_KEPT}${NC}\n";

    echo -e "Cron Job Settings"
    echo -e "   ${BOLD}27)${NC}\tHealth check${NC}\t\t\t${SCOLOR}${ADD_JOB}${NC}";
    echo -e "   ${BOLD}28)${NC}\tndsd backup${NC}\t\t\t${SCOLOR}${ADD_BACKUP_JOB}${NC}";
#    echo -e "       NOTE: run ${BOLD}$(basename $0) add ${NC} to add health check cronjob"
#    echo -e "             run ${BOLD}$(basename $0) add_bk ${NC} to add ndsd backup cronjob"
    echo
    echo -e "   ${BOLD}r${NC} to run ${BOLD}$(basename $0)${NC}"
    echo -e "   ${BOLD}h${NC} to view options running ${BOLD}$(basename $0)${NC}"
    echo -e "   ${BOLD}q${NC} or Press ${BOLD}[Enter]${NC} to Exit\n"
    echo
    echo -n "Enter an option: "

    read IN

case $IN in

        1)
            VAR1=${AUTO_UPDATE}
            VAR2=AUTO_UPDATE
            toggle
            ${THIS_FILE} -l
            ;;

        2)
            VAR1=${LOGTOSYSLOG}
            VAR2=LOGTOSYSLOG
            toggle
            ${THIS_FILE} -l
            ;;

        3)
            VAR1=${RESET_LOG}
            VAR2=RESET_LOG
            toggle
            ${THIS_FILE} -l
            ;;

        4)
            VAR1=${EMAIL_SETTING}
            VAR2=EMAIL_SETTING
            toggle
            ${THIS_FILE} -l
            ;;

        5)
            VAR1=${EMAIL_ON_ERROR}
            VAR2=EMAIL_ON_ERROR
            toggle
            ${THIS_FILE} -l
            ;;

        6)
            changeEmailTo
            ${THIS_FILE} -l
            ;;

        7)
            VAR1=${OBIT_CHECK}
            VAR2=OBIT_CHECK
            toggle
            ${THIS_FILE} -l
            ;;

        8)
            VAR1=${EXREF_CHECK}
            VAR2=EXREF_CHECK
            toggle
            ${THIS_FILE} -l
            ;;

        9)
            VAR1=${HOST_FILE_CHECK}
            VAR2=HOST_FILE_CHECK
            toggle
            ${THIS_FILE} -l
            ;;

        10)
            VAR1=${REPLICA_SYNC}
            VAR2=REPLICA_SYNC
            toggle
            ${THIS_FILE} -l
            ;;

        11)
            VAR1=${NTP_CHECK}
            VAR2=NTP_CHECK
            toggle
            ${THIS_FILE} -l
            ;;

        12)
            VAR1=${TIME_SYNC}
            VAR2=TIME_SYNC
            toggle
            ${THIS_FILE} -l
            ;;

        13)
            VAR1=${REPAIR_NETWORK_ADDR}
            VAR2=REPAIR_NETWORK_ADDR
            toggle
            ${THIS_FILE} -l
            ;;

        14)
            VAR1=${SCHEMA_SYNC}
            VAR2=SCHEMA_SYNC
            toggle
            ${THIS_FILE} -l
            ;;

        15)
            changeSyncTime
            ${THIS_FILE} -l
            ;;

        16)
            VAR1=${DUP_UIDNUMBER}
            VAR2=DUP_UIDNUMBER
            toggle
            ${THIS_FILE} -l
            ;;

        17)
            VAR1=${REPAIR_LOCAL_DB}
            VAR2=REPAIR_LOCAL_DB
            toggle
            ${THIS_FILE} -l
            ;;

        18)
            VAR1=${DISPLAY_PARTITIONS}
            VAR2=DISPLAY_PARTITIONS
            toggle
            ${THIS_FILE} -l
            ;;

        19)
            VAR1=${DISPLAY_UNKNOWN_OBJECTS}
            VAR2=DISPLAY_UNKNOWN_OBJECTS
            toggle
            ${THIS_FILE} -l
            ;;

        20)
            VAR1=${ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS}
            VAR2=ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS
            toggle
            ${THIS_FILE} -l
            ;;

        21)
            changeBaseSearch
            ${THIS_FILE} -l
            ;;

        22)
            VAR1=${CHECK_NDS_DIB}
            VAR2=CHECK_NDS_DIB
            toggle
            ${THIS_FILE} -l
            ;;

        23)
            changeNdsbackupUser
            ${THIS_FILE} -l
            ;;

        24)
            changeNiciPasswd
            ${THIS_FILE} -l
            ;;

        25)
            backupDirNdsd
            ${THIS_FILE} -l
            ;;

        26)
            backupKept
            ${THIS_FILE} -l
            ;;

        27)
            addBackupJob
            ${THIS_FILE} -l
            ;;

        28)
            addNdsdBackupJob
            ${THIS_FILE} -l
            ;;

        r|R|run|RUN)
            ${THIS_FILE}
            ;;
        h|H|--help)
            ${THIS_FILE} -h
            ;;
        *)
            exit;;
esac
}
# END listOptions

backupScript(){
    echo "Backing up $(basename $0) to ${BACKUP_FILE}"
    cp ${THIS_FILE} ${BACKUP_FILE}
}

# get updated health check file
getUpdate() {
 # Make backup directory
    if [ -d /tmp/download ]; then
        &> /dev/null
    else
        /bin/mkdir -p /tmp/download
    fi
 
    [ "${ARGUMENT}" = "up" ] #&& echo "checking for update"
    if [ ! -e $UPDATE_FILE ]; then
        [ "${ARGUMENT}" = "up" ] && echo "attempting to download update"
        wget -q -T 5 $UPDATE_URL
    fi
    [ "${ARGUMENT}" = "up" ] && echo "checking again (in case download failed)"
        if [ ! -e $UPDATE_FILE ]; then
        wget -T 5 $UPDATE_URL
        echo "update not found"
        cat $THIS_FILE > $UPDATE_FILE
    fi
}

# Execute updated file 
executeUpdate() {
#  echo "executing updated file"
  chmod +x $UPDATE_FILE
  ./$UPDATE_FILE run # must invoke with --run
}

# Copy settings to updated file
# Adding new option add template below and do search and replace s/TEMPLATE/NEW_VALUE/g
# CPTEMPLATE=`grep ^\TEMPLATE= $THIS_FILE`
# sed -i "s/^TEMPLATE=./$CPTEMPLATE/g" $UPDATE_FILE
# unset CPTEMPLATE
copySettings(){
CPAUTO_UPDATE=`grep -m1 ^\AUTO_UPDATE= $THIS_FILE`
CPCRON_SETTING=`grep -m1 ^\CRON_SETTING= $THIS_FILE`
CPADD_JOB=`grep -m1 ^\ADD_JOB= $THIS_FILE`
CPADD_BACKUPJOB=`grep -m1 ^\ADD_BACKUP_JOB= $THIS_FILE`
CPBACKUP_NDSD=`grep -m1 ^\BACKUP_NDSD= $THIS_FILE`
CPADMNUSER=`grep -m1 ^\ADMNUSER= $THIS_FILE`
CPBACKUP_DIR_NDSD=`grep -m1 ^\BACKUP_DIR_NDSD= $THIS_FILE`
CPBACKUP_NDS_DIB=`grep -m1 ^\BACKUP_NDS_DIB= $THIS_FILE`
CPCHECK_NDS_DIB=`grep -m1 ^\CHECK_NDS_DIB= $THIS_FILE`
CPBACKUP_NDS_DSBK=`grep -m1 ^\BACKUP_NDS_DSBK= $THIS_FILE`
CPBACKUP_KEPT=`grep -m1 ^\BACKUP_KEPT= $THIS_FILE`
CPNICIPASSWD=`grep -m1 ^\NICIPASSWD= $THIS_FILE`
CPBACKUP_NDS_NDSBACKUP=`grep -m1 ^\BACKUP_NDS_NDSBACKUP= $THIS_FILE`
CPEMAIL_SETTING=`grep -m1 ^\EMAIL_SETTING= $THIS_FILE`
CPEMAIL_ON_ERROR=`grep -m1 ^\EMAIL_ON_ERROR= $THIS_FILE`
CPCHECK_DISK_SPACE=`grep -m1 ^\CHECK_DISK_SPACE= $THIS_FILE`
CPOBIT_CHECK=`grep -m1 ^\OBIT_CHECK= $THIS_FILE`
CPREPAIR_NETWORK_ADDR=`grep -m1 ^\REPAIR_NETWORK_ADDR= $THIS_FILE`
CPSYNC_TIME=`grep -m1 ^\SYNC_TIME= $THIS_FILE`
CPREPLICA_SYNC=`grep -m1 ^\REPLICA_SYNC= $THIS_FILE`
CPSCHEMA_SYNC=`grep -m1 ^\SCHEMA_SYNC= $THIS_FILE`
CPDISPLAY_FSMO=`grep -m1 ^\DISPLAY_FSMO= $THIS_FILE`
CPDUP_UIDNUMBER=`grep -m1 ^\DUP_UIDNUMBER= $THIS_FILE`
CPREPAIR_LOCAL_DB=`grep -m1 ^\REPAIR_LOCAL_DB= $THIS_FILE`
CPDISPLAY_PARTITIONS=`grep -m1 ^\DISPLAY_PARTITIONS= $THIS_FILE`
CPDISPLAY_UNKNOWN_OBJECTS=`grep -m1 ^\DISPLAY_UNKNOWN_OBJECTS= $THIS_FILE`
CPANONYMOUS_DISPLAY_UNKNOWN_OBJECTS=`grep -m1 ^\ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS= $THIS_FILE`
CPBASE=`grep -m1 ^\BASE=* $THIS_FILE`
CPEMAIL_TO=`grep -m1 ^\EMAIL_TO= $THIS_FILE`
CPRESET_LOG=`grep -m1 ^\RESET_LOG= $THIS_FILE`
CPLOGTOSYSLOG=`grep -m1 ^\LOGTOSYSLOG= $THIS_FILE`
test $CPAUTO_UPDATE; if [[ $? == 0 ]]; then sed -i "s/^AUTO_UPDATE=./$CPAUTO_UPDATE/g" $UPDATE_FILE; fi
test $CPCRON_SETTING; if [[ $? == 0 ]]; then sed -i "s/^CRON_SETTING=./$CPCRON_SETTING/g" $UPDATE_FILE; fi
#test $CPADD_JOB; if [[ $? == 0 ]]; then sed -i "s/^ADD_JOB=.*/$CPADD_JOB/g" $UPDATE_FILE; fi
#test $CPADD_BACKUPJOB; if [[ $? == 0 ]]; then sed -i "s/^ADD_BACKUPJOB=.*/$CPADD_BACKUPJOB/g" $UPDATE_FILE; fi
test $CPBACKUP_NDSD; if [[ $? == 0 ]]; then sed -i "s/^BACKUP_NDSD=.*/$CPBACKUP_NDSD/g" $UPDATE_FILE; fi
test $CPADMNUSER; if [[ $? == 0 ]]; then sed -i "s/^ADMNUSER=.*/$CPADMNUSER/g" $UPDATE_FILE; fi
test $CPBACKUP_DIR_NDSD; if [[ $? == 0 ]]; then sed -i s:^$BACKUP_DIR_NDSD=.*:$CPBACKUP_DIR_NDSD:g $UPDATE_FILE; fi
test $CPBACKUP_NDS_DIB; if [[ $? == 0 ]]; then sed -i "s/^BACKUP_NDS_DIB=.*/$CPBACKUP_NDS_DIB/g" $UPDATE_FILE; fi
test $CPCHECK_NDS_DIB; if [[ $? == 0 ]]; then sed -i "s/^CHECK_NDS_DIB=.*/$CPCHECK_NDS_DIB/g" $UPDATE_FILE; fi
test $CPBACKUP_NDS_DSBK; if [[ $? == 0 ]]; then sed -i "s/^BACKUP_NDS_DSBK=.*/$CPBACKUP_NDS_DSBK/g" $UPDATE_FILE; fi
test $CPBACKUP_KEPT; if [[ $? == 0 ]]; then sed -i "s/^BACKUP_KEPT=.*/$CPBACKUP_KEPT/g" $UPDATE_FILE; fi
test $CPNICIPASSWD; if [[ $? == 0 ]]; then sed -i "s/^NICIPASSWD=.*/$CPNICIPASSWD/g" $UPDATE_FILE; fi
test $CPBACKUP_NDS_NDSBACKUP; if [[ $? == 0 ]]; then sed -i "s/^BACKUP_NDS_NDSBACKUP=.*/$CPBACKUP_NDS_NDSBACKUP/g" $UPDATE_FILE; fi
test $CPEMAIL_SETTING; if [[ $? == 0 ]]; then sed -i "s/^EMAIL_SETTING=./$CPEMAIL_SETTING/g" $UPDATE_FILE; fi
test $CPEMAIL_ON_ERROR; if [[ $? == 0 ]]; then sed -i "s/^EMAIL_ON_ERROR=./$CPEMAIL_ON_ERROR/g" $UPDATE_FILE; fi
test $CHECK_DISK_SPACE; if [[ $? == 0 ]]; then sed -i "s/^CHECK_DISK_SPACE=./$CPCHECK_DISK_SPACE/g" $UPDATE_FILE; fi
test $OBIT_CHECK; if [[ $? == 0 ]]; then sed -i "s/^OBIT_CHECK=./$CPOBIT_CHECK/g" $UPDATE_FILE; fi
test $CPREPAIR_NETWORK_ADDR; if [[ $? == 0 ]]; then sed -i "s/^REPAIR_NETWORK_ADDR=./$CPREPAIR_NETWORK_ADDR/g" $UPDATE_FILE; fi
test $CPSYNC_TIME; if [[ $? == 0 ]]; then sed -i "s/^SYNC_TIME=.*/$CPSYNC_TIME/g" $UPDATE_FILE; fi
test $CPREPLICA_SYNC; if [[ $? == 0 ]]; then sed -i "s/^REPLICA_SYNC=./$CPREPLICA_SYNC/g" $UPDATE_FILE; fi
test $CPSCHEMA_SYNC; if [[ $? == 0 ]]; then sed -i "s/^SCHEMA_SYNC=./$CPSCHEMA_SYNC/g" $UPDATE_FILE; fi
test $CPDISPLAY_FSMO; if [[ $? == 0 ]]; then sed -i "s/^DISPLAY_FSMO=./$CPDISPLAY_FSMO/g" $UPDATE_FILE; fi
test $CPDUP_UIDNUMBER; if [[  $? == 0 ]]; then sed -i "s/^DUP_UIDNUMBER=./$CPDUP_UIDNUMBER/g" $UPDATE_FILE; fi
test $CPREPAIR_LOCAL_DB; if [[ $? == 0 ]]; then sed -i "s/^REPAIR_LOCAL_DB=./$CPREPAIR_LOCAL_DB/g" $UPDATE_FILE; fi
test $CPDISPLAY_PARTITIONS; if [[ $? == 0 ]]; then sed -i "s/^DISPLAY_PARTITIONS=./$CPDISPLAY_PARTITIONS/g" $UPDATE_FILE; fi
test $CPDISPLAY_UNKNOWN_OBJECTS; if [[ $? == 0 ]]; then sed -i "s/^DISPLAY_UNKNOWN_OBJECTS=./$CPDISPLAY_UNKNOWN_OBJECTS/g" $UPDATE_FILE; fi
test $CPANONYMOUS_DISPLAY_UNKNOWN_OBJECTS; if [[ $? == 0 ]]; then sed -i "s/^ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS=./$CPANONYMOUS_DISPLAY_UNKNOWN_OBJECTS/g" $UPDATE_FILE; fi
test $CPBASE; if [[ $? == 0 ]]; then sed -i "s/^BASE=.*/$CPBASE/g" $UPDATE_FILE; fi
test $CPEMAIL_TO; if [[ $? == 0 ]]; then sed -i "s/^EMAIL_TO=.*/$CPEMAIL_TO/g" $UPDATE_FILE; fi
test $CPRESET_LOG; if [[ $? == 0 ]]; then sed -i "s/^RESET_LOG=./$CPRESET_LOG/g" $UPDATE_FILE; fi
test $CPLOGTOSYSLOG; if [[ $? == 0 ]]; then sed -i "s/^LOGTOSYSLOG=./$CPLOGTOSYSLOG/g" $UPDATE_FILE; fi
unset CPAUTO_UPDATE
unset CPCRON_SETTING
unset CPADD_JOB
unset CPADD_BACKUPJOB
unset CPBACKUP_NDSD
unset CPADMNUSER
unset CPBACKUP_DIR_NDSD
unset CPBACKUP_NDS_DIB
unset CPCHECK_NDS_DIB
unset CPBACKUP_NDS_DSBK
unset CPBACKUP_KEPT
unset CPNICIPASSWD
unset CPBACKUP_NDS_NDSBACKUP
unset CPEMAIL_SETTING
unset CPEMAIL_ON_ERROR
unset CPCHECK_DISK_SPACE
unset CPOBIT_CHECK
unset CPREPAIR_NETWORK_ADDR
unset CPSYNC_TIME
unset CPREPLICA_SYNC
unset CPSCHEMA_SYNC
unset CPDISPLAY_FSMO
unset CPDUP_UIDNUMBER
unset CPREPAIR_LOCAL_DB
unset CPDISPLAY_PARTITIONS
unset CPDISPLAY_UNKNOWN_OBJECTS
unset CPANONYMOUS_DISPLAY_UNKNOWN_OBJECTS
unset CPBASE
unset CPEMAIL_TO
unset CPRESET_LOG
unset CPLOGTOSYSLOG
}

# Replace the original file with updated file
replaceCurrentFileWithUpdate() {
  [ "${ARGUMENT}" = "up" ] && echo "overwriting current file with update file"
  chmod +x $UPDATE_FILE
  if [ "$UPDATE_FILE" != ./"$THIS_FILE" ]; then mv -f $UPDATE_FILE $THIS_FILE; fi
  echo Finished updating $(basename $0) to version $UPDATE_VERSION
  echo 
  echo Run $(basename $0) -l to modify the "User Configuration Section"
  echo Proceeding with the health check
}

# Run all updates if no options
update() {
  # if the currently running script is not invoked with --run,
  # then it is not the updated one
  if [ -z "${ARGUMENT}" ]; then
    backupScript
    getUpdate
    copySettings
#    executeUpdate
    replaceCurrentFileWithUpdate
    RES=$?
    exit $RES # must exit, or script will recursively call itself for all eternity
  fi
}

#Auto update function
autoUpdate() {
    # Check FTP connectivity
    if [ $(checkDSfWDude) -eq 0 ];then
        # Fetch and store to memory, check version
        UPDATE_VERSION=`curl -s http://dsfwdude.com/downloads/autoupdate-ndsd_dsfw_healthchk.sh | grep -m1 ^SCRIPT_BINARY_VERSION= |cut -f2 -d=`
        # Compare version, download if newer version is available
        if [[ "$SCRIPT_BINARY_VERSION" -lt "$UPDATE_VERSION" ]];then
            echo -e "\nChecking for newer version ..."
            sleep 1
            echo -e "Current binary version $SCRIPT_BINARY_VERSION"
            echo -e "Updating to binary version $UPDATE_VERSION"
            backupScript
            getUpdate
            copySettings
            replaceCurrentFileWithUpdate
        fi
    fi
}

checkDSfWDude() {
    # Echo back 0 or 1 into if statement
    # To call/use: if [ $(checkDSfWDude) -eq 0 ];then
    netcat -z -w 1 dsfwdude.com 80;
    if [ $? -eq 0 ]; then
         UPDATE=YES
         echo "0"
    else #echo "Can not contact DSfWDude.com ....  update"
         UPDATE=NO
         echo "1"
    fi
}


# Perfomr the Health Check
healthCheck(){

((C=1)) # Set Count to 1
declare -a ERROR_NUMBER
declare -a ERROR_NDS
declare -a ERROR_DNS
declare -a ERROR_XAD
declare -a ERROR_KDC
declare -a ERROR_SMB
declare -a ERROR_SYSVOL
declare -a ERROR_GPO
declare -a ERROR_DOMAINCNTRL
declare -a ERROR_MESSAGES
declare -a ERROR_PASS
declare -a WARNING_NUMBER
declare -a FIXED_NUMBER

# Check disk sapce on each partition
log "$C)  Checking Disk Space is greather than ${BOLD}"$CHECK_DISK_SPACE"G${NC}"
chkDiskSpace

# check that eDirectory is configured
((C++))
log "$C)  Checking for eDirectory database file and if ndsd is running-${BOLD}"`echo $DIB_DIR`/nds.db"${NC}"
    if [ -f "`echo $DIB_DIR`/nds.db" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: ndsd is not running and/or eDirectory database is not found!!! ${NC}\n"
        RES=$?
        exit $RES
    fi

if [ $XADINST -eq 1 ] && [ $DNSSTATUS -eq 1 ] && [ $BACKUP_NDS_DSBK -eq 0 ]; then # xadsd file exists and dns is set to run then do the following
# Check that all DSfW services are running
((C++))
log "$C)  Checking that the DSfW services are running - ${BOLD}xadxntrl validate${NC}"
    if [ `pidof ndsd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof novell-named |awk -F " " '{ print $1 }'` > 0 ] && [ `pidof nscd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof rpcd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof rsyncd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof xadsd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof krb5kdc|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof kpasswdd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof nmbd |cut -f1 -d " "` > 0 ] && [ `pidof winbindd |cut -f1 -d " "` > 0 ] && [ `pidof smbd |cut -f1 -d " "` > 0 ] > /dev/null 2>&1
    then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        log "One or more DSfW service are not running, please run xadcntrl reload to restart the services"
        TIMELIMIT=20
        echo -ne "Do you want continue? (Y/n): " #yes not to continue
        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]; then   # if REPLY is null then
            /opt/novell/xad/bin/xadcntrl reload
        elif [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo;                       
        else
            echo -ne "Do you want restart DSfW services? (Y/n): "
            read REPLY
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                /opt/novell/xad/bin/xadcntrl reload
                echo
            fi	
        fi
    fi

elif [ $XADINST -eq 1 ] && [ $DNSSTATUS -eq 0 ] && [ $BACKUP_NDS_DSBK -eq 0 ]; then
# Check that all DSfW services are running with not novell-named
((C++))
elif [ $XADINST -eq 1 ] && [ $DNSSTATUS -eq 0 ]; then
log "$C)  Checking that the DSfW services are running - ${BOLD}xadxntrl validate${NC}"
	if [ `pidof ndsd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof nscd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof rpcd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof rsyncd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof xadsd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof krb5kdc|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof kpasswdd|awk -F " " '{ print $1 }'` > 0 ] && [ `pidof nmbd |cut -f1 -d " "` > 0 ] && [ `pidof winbindd |cut -f1 -d " "` > 0 ] && [ `pidof smbd |cut -f1 -d " "` > 0 ] > /dev/null 2>&1
    then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        log "One or more DSfW service are not running, please run xadcntrl reload to restart the services"
        TIMELIMIT=20
        echo -ne "Do you want continue? (Y/n): "
        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]; then   # if REPLY is null then
            /opt/novell/xad/bin/xadcntrl reload
        elif [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo;                       
        else
            echo -ne "Do you want restart DSfW services? (Y/n): "
            read REPLY
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                /opt/novell/xad/bin/xadcntrl reload
                echo
            fi	
        fi
    fi

else

((C++))
log "$C)  Checking that eDirectory (ndsd) is running - ${BOLD}rcndsd status${NC}"
    if [ `pidof ndsd|awk -F " " '{ print $1 }'` > 0 ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "eDirectory (ndsd) is not running"
        echo -ne "Do you want continue? (y/n): "
        read REPLY
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo;                       
        else
            echo -ne "Do you want restart eDirectory? (y/n): "
            read REPLY
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rcndsd restart
                echo
            fi	
        fi
    fi
fi # END xadsd and dnsstatus checks

if [ $BACKUP_NDSD -eq 0 ]; then # if BACKUP_NDSD is 1 (enabled) then skip and just backup
 if [ $NTP_CHECK -eq 1 ]; then
# Check ntp is running for next command
((C++))
log "$C)  Checking that ntpd is running - ${BOLD}rcntp status${NC}"
    test `pgrep ntpd`
    if [ $? -ne "0" ]
        then echo -e "    ntpd is not running, restarting ntpd\n"
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        rcntp restart >/dev/null
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi

# Check ntp is running for next command
((C++))
log "$C)  Report ntpd peers - ${BOLD}ntpq -p${NC}"
    ntpq -p
    ntpq -p >> $LOG
    log ""

# Check system time and hardware clock
((C++))
log "$C)  Report system clock and hardware clock are in sync ${BOLD}date = hwclock${NC}"
    hwclock -w
    if test `grep ^HWCLOCK /etc/sysconfig/clock` = 'HWCLOCK="--localtime"'; then
        if test `hwclock | awk '{print $5}' |awk -F ":" '{print $1 ":" $2}'` = `date +%H:%M`; then
            log "    ${GREEN}GOOD${NC}\n"
        elif test `hwclock | awk '{print $5}' |awk -F ":" '{print $1 ":" $2}'` = `date +%I:%M`; then
            log "    ${GREEN}GOOD${NC}\n"
        elif test `hwclock | awk '{print $4}' |awk -F ":" '{print $1 ":" $2}'` = `date +%H:%M`; then
            log "    ${GREEN}GOOD${NC}\n"
        elif test `hwclock | awk '{print $4}' |awk -F ":" '{print $1 ":" $2}'` = `date +%I:%M`; then
            log "    ${GREEN}GOOD${NC}\n"
        else
            log "    The system time is `date`"
            log "    The hwclock is `hwclock`"
            log "    Run hwclock -w to sync the hardware clock to the system time\n"

        fi
    else
        log "    The system time is `date`"
        log "    The hwclock is `hwclock`"
        log "    Run hwclock -w to sync the hardware clock to the system time\n"
    fi
 # END time section
 fi # END NTP section

if [ $TIME_SYNC -eq 1 ]; then
# check eDirectory time is in sync
((C++))
log "$C)  Checking eDirectory Time Synchronization using command ${BOLD}ndsrepair -T${NC}"
    edirtimesync=$(/opt/novell/eDirectory/bin/ndsrepair -T | grep -s "Total errors: 0")
    if [ "$edirtimesync" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: Time Not in Sync ${NC}"
        log "    Check the /etc/ntp configuration"
        log "    Last Error in ndsrepair.log"
        log "    $(cat /var/opt/novell/eDirectory/log/ndsrepair.log |grep -B1 ERROR: | tail -n1)${NC}"
        log "    Check /var/log/messages for errors regarding ntpd\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
fi # END time sync section

if [ $REPLICA_SYNC -eq 1 ]; then
# check eDirectory synchronization
((C++))
log "$C)  Checking eDirectory Replica Synchronization using command ${BOLD}ndsrepair -E${NC}"
    # Create trace file
    TMP_FILE_TRACE=`mktemp`
    trap 'rm $TMP_FILE_TRACE; ' EXIT
    ndstrace -u > /dev/null 2>&1
    ndstrace -l > $TMP_FILE_TRACE & #> /dev/null 2>&1 &
    trap 'ndstrace -u > /dev/null 2>&1 ' EXIT
    sleep .2
    ndstrace -c "set ndstrace=nodebug;ndstrace on;ndstrace fmax=500000000" > /dev/null 2>&1 &
    sleep .2
    ndstrace -c "set ndstrace=*u;set ndstrace=*h" >/dev/null 2>&1
    sleep $SYNC_TIME
    edirreportsync=$(/opt/novell/eDirectory/bin/ndsrepair -E | grep -s "Total errors: 0")
    sleep 1
    if [ "$edirreportsync" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: Replicas not synchronized${NC}"
        log "    $(cat /var/opt/novell/eDirectory/log/ndsrepair.log |grep -B1 ERROR: | tail -n1)${NC}"
        log "    Look up the error(s) reported in the ndsrepair.log at http://novell.com/support\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    rm $TMP_FILE_TRACE
fi # END replica sync section

if [ $OBIT_CHECK -eq 1 ]; then
# check eDirectory obituaries
((C++))
log "$C)  Checking for eDirectory Obituaries using command ${BOLD}ndsrepair -C -Ad -a${NC}"
    edircheckobits=$(/opt/novell/eDirectory/bin/ndsrepair -C -Ad -a | grep "Found: 0 total obituaries in this DIB")
    if [ "$edircheckobits" == "Found: 0 total obituaries in this DIB, " ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: Unprocessed Obits exist${NC}"
        log "    See ${BCYAN}TID 7011536${NC} Obituary Troubleshooting"
        log "    See ${BCYAN}TID 7002659${NC} How to progress stuck obituaries"
        log "    $(tail -n4 /var/opt/novell/eDirectory/log/ndsrepair.log)${NC}\n"
    fi
fi # END obit check

if [ $EXREF_CHECK -eq 1 ]; then
# check external references
((C++))
log "$C)  Checking for eDirectory External References using command ${BOLD}ndsrepair -C${NC}"
	sleep .5
	edircheckexref=$(/opt/novell/eDirectory/bin/ndsrepair -C | grep "Total errors: 0")
	if [ "$edircheckexref" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: External Reference Check reports errors${NC}"
        log "    Look up the error(s) reported in the ndsrepair.log at http://novell.com/support"
        log "    Last Error in ndsrepair.log"
        log "    $(cat /var/opt/novell/eDirectory/log/ndsrepair.log |grep ERROR:)${NC}\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
fi # END check external references

if [ $HOST_FILE_CHECK -eq 1 ]; then
# check that the nds4.server.interfaces matches that in the /etc/hosts
((C++))
log "$C) Checking the ip address assigned to the ncpserver is correct - ${BOLD}$IPADDR${NC}"
	sleep .5
	if [ "$NCP_INTERFACE" == "$IPADDR" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: n4u.server.interfaces does not match the IP Address (ifconfig)${NC}"
        log "    run 'ndsconfig get n4u.server.interfaces' and verify the IP address is listed correctly"
        #sed -i 's/$NCP_INTERFACE/$IPADDR/g' /etc/sysconfig/network/ifcfg-eth0
        #sed -i 's/$NCP_INTERFACE/$IPADDR/g' /etc/hosts
        log "    Novell Documentation http://www.novell.com/documentation/oes11/oes_implement_lx/?page=/documentation/oes11/oes_implement_lx/data/ipchange.html\n"
    fi

# check that the servers ip address is listed in the /etc/hosts.conf
((C++))
log "$C) Checking the ip address in the /etc/hosts file is correct - ${BOLD}$IPADDR = $HOSTS_IPADDR${NC}"
    sleep .5
    if [ "$IPADDR" == "$HOSTS_IPADDR" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: ip address in /etc/hosts is incorrect ${NC}"
        log "    Correct the ip address in the /etc/hosts file then run SuSEconfig\n"
    fi
fi # END host file check

# check that the loopback address is listed in the /etc/hosts.conf
((C++))
log "$C) Checking for the 127.0.0.1 loopback address in the /etc/hosts file - ${BOLD}grep ^127.0.0.1 /etc/hosts${NC}"
    sleep .5
    grep ^127.0.0.1 /etc/hosts > /dev/null 2>&1; 
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: loopback address is not listed in the /etc/hosts ${NC}"
        log "    ADD 127.0.0.1 localhost is in the /etc/hosts file then run SuSEconfig\n"
    fi

# check that the loopback address is listed in the /etc/hosts.conf
((C++))
log "$C) Checking that 127.0.0.2 loopback address is not in the /etc/hosts file - ${BOLD}grep ^127.0.0.2 /etc/hosts${NC}"
    sleep .5
    grep ^127.0.0.2 /etc/hosts > /dev/null 2>&1;
    if [ $? -eq "1" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: 127.0.0.2 loopback address is listed in the /etc/hosts ${NC}"
        log "    Rem out 127.0.0.2 in the /etc/hosts file then run SuSEconfig\n"
    fi

# check for the ipV6 address is remmed in the /etc/hosts.conf
#((C++))
#log "$C) Checking for the ipv6 loopback address in the /etc/hosts file - ${BOLD}grep ^::1 /etc/hosts${NC}"
#    sleep .5
#    grep ^::1 /etc/hosts > /dev/null 2>&1; 
#   if [ $? -eq "1" ]; then
#       log "    ${GREEN}GOOD${NC}\n"
#    else
#        NUMBER_WARNINGS=`expr $NUMBER_WARNINGS + 1`
#        log "    \e[1;33mWARNING: ipv6 loopback address is active in /etc/hosts ${NC}"
#        log "    The ipv6 loopback address (::1) Might cause issues "
#        log "    Rem out the ::1 address in the /etc/hosts file then run SuSEconfig\n"
#    fi

if [ $REPAIR_NETWORK_ADDR -eq 1 ]; then    # REPAIR_NETWORK_ADDR must be enabled to run this section
# check that the servers ip address is listed in the /etc/hosts.conf
((C++))
log "$C)  Checking Network Addresses using command ${BOLD}ndsrepair -N${NC}"
    TMP_FILE_NETWORK=`mktemp`
    trap 'rm $TMP_FILE_NETWORK; ' EXIT
    sleep .5
    reparinetworkaddress > $TMP_FILE_NETWORK
    edirchecknaddress=$(grep -i "Total errors: 0" $TMP_FILE_NETWORK)
    if [ "$edirchecknaddress" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: Checking Network Addresses${NC}"
        log "    Check the ndsrepair -N for errors"
        log "    Look up the error(s) reported in the ndsrepair.log at http://novell.com/support"
        log "    Last Error in ndsrepair.log"
        log "    $(cat /var/opt/novell/eDirectory/log/ndsrepair.log |grep ERROR: | tail -n1)${NC}\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    rm $TMP_FILE_NETWORK
fi # END REPAIR_NETWORK_ADDR check

if [ $SCHEMA_SYNC -eq 1 ]; then  # SCHEMA_SYNC option must be enabled (set to 1) to run this sectipn
# check eDirectory time is in sync
((C++))
log "$C) Checking eDirectory Schema Synchronization using command ${BOLD}set ndstrace=*ss${NC}"
    # Create trace file
    TMP_FILE_TRACE=`mktemp`
    trap 'rm $TMP_FILE_TRACE; ' EXIT
    ndstrace -u > /dev/null 2>&1
    ndstrace -l > $TMP_FILE_TRACE & #> /dev/null 2>&1 &
    sleep .2
    ndstrace -c "set ndstrace=nodebug;ndstrace on;ndstrace fmax=500000000" > /dev/null 2>&1 &
    sleep .2
    ndstrace -c "ndstrace tags time scma scmd svty;set ndstrace=*ssa;set ndstrace=*ssd;set ndstrace=*ss;set ndstrace=*u;s
et ndstrace=*h" >/dev/null 2>&1
    sleep $SYNC_TIME
    edirschsync=$( grep -i "All processed = YES" $TMP_FILE_TRACE)
    if [ "$edirschsync" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: Schema Not in Sync ${NC}"
        log "    Run the command in a terminal"
        log "    load ndstrace, enable scma and scmd"
        log "    set ndstrace=*scma and *scmd"
        log "    Look for All processed = YES or NO"
        log "    Increase the SYNC_TIME setting in the configuration section of this script"
        log "    Check the ndstrace.log for errors\n"
        log "  *** ndstrace schema synchronization ***"
        log "$(tail -n15 $TMP_FILE_TRACE)\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    rm $TMP_FILE_TRACE
fi
# END SCHEMA_SYNC check

if [ $XADINST -eq 1 ] && [[ $DNSSTATUS -eq 0 ]]; then   # file xadsd must exist and dns not be set to run
# check that resolv.conf has the servers ip address listed
((C++))
log "$C)  Checking that the DSfW server is listed as a nameserver in the /etc/resolv.conf - ${BOLD}$RESOLV_IPADDR = $IPADDR${NC}"
    log "    ${GREEN}novell-named is not set to load"
    log "    Ignore${NC}\n"
log $IPADDR address nic listening on
log $RESOLV_IPADDR resovle address
fi # END file xadsd must exist and dns not be set to run

if [ $XADINST -eq 1 ] && [[ $DNSSTATUS -eq 1 ]]; then  # xadsd file exists and dns is set to run
# check that resolv.conf has the servers ip address listed
((C++))
log "$C) Checking that the DSfW server is listed as a nameserver in the /etc/resolv.conf - ${BOLD}$RESOLV_IPADDR = $IPADDR${NC}"
	sleep .5
    if [ $RESOLV_IPADDR == $IPADDR ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${yellow}ERROR: DSfW server is not listed as nameserver in /etc/resolv.conf${NC}"
        log "     If this is an ADC or DNS is running on another server do: chkconfig novell-named off"
        log "     See ${BCYAN}TID 7006844${NC} - How to Consolidate Matching DNS Zone"
        log "     Verify the dns is working using nslookup or dig"
        log "     nslookup $DOMAIN"
        log "     nslookup -type=srv _ldap._tcp.dc._msdcs.$DOMAIN\n"

    fi
fi # END file xadsd must exist and dns is be set to run

if [ $XADINST -eq 1 ]; then  # DSfW Specific Section
# check dns is responding with nslookup domain name
((C++))
log "$C) Checking dns is returning the domain name - ${BOLD}nslookup $DOMAIN${NC}"
    sleep .5
    nslookup $DOMAIN|grep Name: > /dev/null 2>&1
    if [ $? -eq "0" ]; then
		        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_DNS=("${ERROR_DNS[@]}" "$C")
        log "    ${RED}ERROR: nslookup failed for Domain $DOMAIN ${NC}"
        log "	 Verify the DNS server is running"
        log "    Verify the nameserver is listed correctly in the /etc/resolv.conf\n"
    fi

# check dns is responding with nslookup domain name
((C++))
log "$C) Checking that the DSfW server is listed as a DC in dns - ${BOLD}nslookup -type=srv _ldap._tcp.dc._msdcs.$DOMAIN${NC}"
    sleep .5
    nslookup -type=srv _ldap._tcp.dc._msdcs.$DOMAIN|grep ^_ldap > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_DNS=("${ERROR_DNS[@]}" "$C")
        log "    ${RED}ERROR: nslookup failed for Domain $DOMAIN ${NC}"
        log "	 Verify the DNS server is running"
        log "    Verify the nameserver is listed correctly in the /etc/resolv.conf\n"
    fi

# check dns is responding with dig server name
((C++))
log "$C) Checking that the DSfW server returns the ip in dns - ${BOLD}dig $DOMAIN +short${NC}"
    sleep .5
    dig $DOMAIN +short|grep $IPADDR> /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_DNS=("${ERROR_DNS[@]}" "$C")
        log "    ${RED}ERROR: dig $DOMAIN +short failed for Domain $DOMAIN ${NC}"
        log "    Verify the DNS server is running"
        log "    Verify the nameserver is listed correctly in the /etc/resolv.conf\n"
    fi

# check dns is responding with dig ip
((C++))
log "$C) Checking that the DSfW server returns the netbios name in dns - ${BOLD}dig -x $IPADDR +short${NC}"
    sleep .5
    dig -x $IPADDR +short > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_DNS=("${ERROR_DNS[@]}" "$C")
        log "    ${RED}ERROR: dig -x$IPADDR +short failed for Domain $DOMAIN ${NC}"
        log "    Verify the DNS server is running"
        log "    Verify the nameserver is listed correctly in the /etc/resolv.conf\n"
    fi



# Check Domain SID
#((C++))
#log "$C) Reporting ${BOLD}Domain SID${NC}"
#    SIDLOOKUP=""
#    DEFAULTNAMINGCONTEXT=`/usr/bin/ldapsearch -x -b "" -s base|grep -i 'DEFAULTNAMINGCONTEXT: '|awk '{print $2}'`
#    SID=`/usr/bin/ldapsearch -x -b "$DEFAULTNAMINGCONTEXT" -s base -LLL objectSid|grep 'objectSid:: '|awk -F 'objectSid: ' '{print $2}'`
#    DOMAINSID=`/opt/novell/xad/share/dcinit/base64ToSid.pl $SID`
#    if test "$SID" = "00000000-0000-0000-0000-000000000000"; then
#        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
#        log "    ${RED}ERROR: Can not report Domain SID${NC}"
#        log "    Verify anonymous bind is enabled"
#        log "    Run ${BOLD}/usr/bin/ldapsearch -x -b "$DEFAULTNAMINGCONTEXT" -s base -LLL objetSid${NC}"
#        log "    If the SID is not reported, the cause might be anonymous bind is disabled"
#        log "    Or the LDAP Proxy user or [Public] does not have rights to read the objectSid attribute "
#        log "    Or if the objectSid attribute is NULL"
#        log "    Get the objectSid value using iManager from the Domain Mapped Container"
#        log "    Then run ${BOLD}/opt/novell/xad/share/dcinit/base64ToSiD.pl <objectSid value>${NC}"
#        log "    Note: do not include the <>\n"
#    else
#        log "    The Domain SID is $DOMAINSID"
#        log "    ${GREEN}GOOD${NC}\n"
#        SIDLOOKUP=YES
#    fi

# Check ldap
((C++))
log "$C) Checking LDAP Server status ${BOLD}ldapsearch -x -b -s base${NC}"
    LDAPSEARCHRES=0
    /usr/bin/ldapsearch -x -b "" -s base > /dev/null 2>&1
    RES=$?
    if [[ $RES == 13 ]]; then
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        LDAPSEARCHRES="this server requires a TLS connection"
        log "    ${yellow}WARNING: $LDAPSEARCHRES ${NC}\n"
        LDAPSEARCH="/usr/bin/ldapsearch -H ldaps://"
    elif [[ $RES == 48 ]]; then
        LDAPSEARCHRES="Anonymous Simple Bind Disabled"
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: $LDAPSEARCHRES ${NC}"
        log "    DSfW requires anonymous bind"
        log "    winbind and many other requests will fail"
        log "    Allow anonymous bind before proceeding further in troubleshooting\n"
        sleep 10
    elif [[ $RES == 255 ]]; then
        LDAPSEARCHRES="can't contact LDAP server"
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: $LDAPSEARCHRES ${NC}"
        log "    Troubleshoot LDAP before proceeding further in troubleshooting\n"
        sleep 10
    else
        log "    The LDAP Server is up"
        LDAPSEARCH=/usr/bin/ldapsearch
        log "    ${GREEN}GOOD${NC}\n"
    fi


# Check Domain GUID
((C++))
log "$C) Reporting ${BOLD}Domain GUID${NC}"
if [[ $LDAPSEARCHRES == 0 ]]; then
    DEFAULTNAMINGCONTEXT=`/usr/bin/ldapsearch -x -b "" -s base|grep -i 'DEFAULTNAMINGCONTEXT: '|awk '{print $2}'`
    GUIDLOOKUP=""
    MAPPEDDOMANICONTEXT=`/opt/novell/xad/share/dcinit/printConfigKey.pl MAPPEDDOMAINNC`
    GUID=`$LDAPSEARCH -x -b "$DEFAULTNAMINGCONTEXT" -s base -LLL GUID|grep 'GUID:: '|awk -F 'GUID:: ' '{print $2}'`
    if test ${#GUID} == 0; then
        GUID=`$LDAPSEARCH -x -b "$MAPPEDDOMANICONTEXT" -s base -LLL GUID|grep 'GUID:: '|awk -F 'GUID:: ' '{print $2}'`
        if test ${#GUID} == 0; then
            WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
            log "    ${YELLOW}WARNING: Domain GUID is 0${NC}"
            log "    Do: /usr/bin/ldapsearch -x -b "$DEFAULTNAMINGCONTEXT" -s base -LLL GUID"
            log "    or"
            log "    Do: /usr/bin/ldapsearch -x -b "$MAPPEDDOMANICONTEXT" -s base -LLL GUID"
            log "    or"
            log "    If nothing is returned, check to see if anonymous bind is disabled\n"
        else
            DOMAINGUID=`/opt/novell/xad/share/dcinit/base64ToGUID.pl $GUID`
            if [[ $DOMAINGUID == 00000000-0000-0000-0000-000000000000 ]]; then
                ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
                ERROR_XAD=("${ERROR_XAD[@]}" "$C")
                log "    ${RED}ERROR: Can not report Domain GUID${NC}"
                log "    Verify anonymous bind is enabled"
                log "    Run ${BOLD}/usr/bin/ldapsearch -x -b "$DEFAULTNAMINGCONTEXT" -s base -LLL GUID${NC}"
                log "    If the GUID is not reported, the cause might be anonymous bind is disabled"
                log "    Or the LDAP Proxy user or [Public] does not have rights to read the GUID attribute "
                log "    Or if the GUID attribute is NULL"
                log "    Get the GUID value using iManager from the Domain Mapped Container"
                log "    Then run ${BOLD}/opt/novell/xad/share/dcinit/base64ToGUID.pl <GUID value>${NC}"
                log "    Note: do not include the <>"
                log "    See ${BCYAN}TID 7005314${NC}\n"
            else
                WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
                log "    The Domain GUID is $DOMAINGUID"
                log "    ${YELLOW}WARNING: Domain GUID could not be found with $DEFAULTNAMINGCONTEXT${NC}"
                log "    The Domain GUID was found with /usr/bin/ldapsearch -x -b "$MAPPEDDOMANICONTEXT" -s base -LLL GUID\n"
                GUIDLOOKUP=YES
            fi
        fi
    else
        DOMAINGUID=`/opt/novell/xad/share/dcinit/base64ToGUID.pl $GUID`
        if [[ $DOMAINGUID == 00000000-0000-0000-0000-000000000000 ]]; then
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            log "    ${RED}ERROR: Can not report Domain GUID${NC}"
            log "    Verify anonymous bind is enabled"
            log "    Run ${BOLD}/usr/bin/ldapsearch -x -b "$DEFAULTNAMINGCONTEXT" -s base -LLL GUID${NC}"
            log "    If the GUID is not reported, the cause might be anonymous bind is disabled"
            log "    Or the LDAP Proxy user or [Public] does not have rights to read the GUID attribute "
            log "    Or if the GUID attribute is NULL"
            log "    Get the GUID value using iManager from the Domain Mapped Container"
            log "    Then run ${BOLD}/opt/novell/xad/share/dcinit/base64ToGUID.pl <GUID value>${NC}"
            log "    Note: do not include the <>"
            log "    See ${BCYAN}TID 7005314${NC}\n"
        else
            log "    The Domain GUID is $DOMAINGUID"
            log "    ${GREEN}GOOD${NC}\n"
            GUIDLOOKUP=YES
        fi
    fi
else
    WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
    log "    Can not perform this check because $LDAPSEARCHRES, Skipping\n"
fi


# check SRV _ldap._tcp.$DOMAINGUID.domains._msdcs.$DOMAIN
((C++))
log "$C) Checking domain guid msdcs record with nslookup - ${BOLD}nslookup -type=SRV _ldap._tcp.$DOMAINGUID.domains._msdcs.$DOMAIN${NC}"
if [ "$GUIDLOOKUP" = "YES" ]; then
    sleep .2
    nslookup -type=SRV _ldap._tcp.$DOMAINGUID.domains._msdcs.$DOMAIN |grep $DOMAINGUID
    if [ $? == "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}nslookup failed for Domain $DOMAINGUID ${NC}"
        log "    $DOMAINGUID does not equal $DNSGUID"
        log "    Verify the DNS server is running"
        log "    Verify the nameserver is listed correctly in the /etc/resolv.conf\n"
        log "    Then run ${BOLD}/opt/novell/xad/share/dcinit/base64ToGUID.pl <GUID value>${NC}"
        log "    Note: do not include the <>"
        log "    See ${BCYAN}TID 7005314${NC}\n"
    fi
else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}Reporting Domain GUID failed${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
fi

# check /opt/novell/xad/libexec/xadsd -S
((C++))
log "$C) Checking the Domain service is active using command ${BOLD}/opt/novell/xad/libexec/xadsd -S${NC}"
    sleep .5
    /opt/novell/xad/libexec/xadsd -S > /dev/null 2>&1
    if [ $? -eq "1" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: Domain Controller is NOT located ${NC}"
        log "	 Take a ldap/nmas trace (TID 7009602) and check the /var/log/messages\n"
    fi

 if test `uname -p` == x86_64; then
# check /etc/ntp for authprove
((C++))
log "$C) Checking for ${BOLD}authprove in /etc/ntp.conf${NC}"
    sleep .5
    grep "authprov /opt/novell/xad/lib64/libw32time.so" /etc/ntp.conf > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: NTP is not configured properly ${NC}"
        log "    add authprov /opt/novell/xad/lib64/libw32time.so 131072:4294967295 global"
        log "    to the bottom of the /etc/ntp.con then restart ntp\n"
        TIMELIMIT=20
        echo -ne "Do you want fix the ntp.conf ${BOLD}${NC} now? (y/N):"
        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]; then   # if REPLY is null then exit
            log "    Timeout, did not fix the ntp.conf\n"
        elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
            NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
            FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
            sed -i -e '$ i\authprov /opt/novell/xad/lib64/libw32time.so 131072:4294967295 global' /etc/ntp.conf > /dev/null
            log "    Fixed ntp.conf\n"
            sleep 1
        fi
    fi
 fi

# Check ntp is running for next command
# check /proc maps for w32
#((C++))
#log "$C) Checking that ntpd is running ${BOLD}cat /proc/`pgrep ntpd`/maps |grep w32${NC}"
#    test `pgrep ntpd` 
##    if [ $? -ne "0" ]; then
#        NTPSTATUS=NO
#        rcntp restart >/dev/null
#    else
#        NTPSTATUS=YES
#    fi
#    if test "$NTPSTATUS" = "YES"; then
#        sleep .5
#        cat /proc/`pgrep ntpd`/maps |grep w32 > /dev/null 2>&1
#        if [ $? -eq "0" ]; then
#            log "    ${GREEN}GOOD${NC}\n"
#        else
#            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
#            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
#            log "    ${RED}ERROR: NTP is not configured properly ${NC}"
#            log "    verify authprov /opt/novell/xad/lib64/libw32time.so 131072:4294967295 global"
#            log "    to the bottom of the /etc/ntp.conf then restart ntp\n"
#        fi
#    else
#        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
#        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
#        log "    Can not perform this check because ntpd is not running, Skipping\n"
#    fi #END check /proc maps for w32

# check ldapInterfaces eDirLDAP ports
((C++))
DCSERVER=`/usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "" -s base |grep serverName: |awk -F '=|,' '{ print $2 }'`
log "$C) Checking ports 389, 1389, 636, and 1636 are listening${BOLD}${NC}"
netstat -tualpn -A inet |grep 'LISTEN' |egrep "389|636"
echo

# check ldapInterfaces
((C++))
DCSERVER=`/usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "" -s base |grep serverName: |awk -F '=|,' '{ print $2 }'`
log "$C) Checking for ldapi ldapInterface ${BOLD}(ldapInterfaces=ldap://:389 ldaps://:636 ldapi://%2fvar%2fopt%2fnovell%2fxad%2)${NC} for ${BOLD}$DCSERVER${NC}"
    sleep .5
if [[ $LDAPSEARCHRES == 0 ]]; then
    DEFAULTNAMINGCONTEXT=`/usr/bin/ldapsearch -x -b "" -s base DEFAULTNAMINGCONTEXT | grep -i 'DEFAULTNAMINGCONTEXT: ' | awk '{print $2}'`
#    /usr/bin/ldapsearch -x -b "ou=OESSystemObjects,$DEFAULTNAMINGCONTEXT" "(&(objectClass=ldapServer)(ldapHostServer= cn=$DCSERVER,ou=OESSystemObjects,$DEFAULTNAMINGCONTEXT)(ldapInterfaces= ldap://:389 ldaps://:636 ldapi://%2fvar%2fopt%2fnovell%2fxad%2))" > /dev/null 2>&1
    /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "ou=OESSystemObjects,$DEFAULTNAMINGCONTEXT" "(&(objectClass=ldapServer)(ldapHostServer=cn=$DCSERVER,ou=OESSystemObjects,$DEFAULTNAMINGCONTEXT))"|grep "ldap://:389 ldaps://:636 ldapi://%2fvar%2fopt%2fnovell%2fxad%2" > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
    /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "ou=OESSystemObjects,$DEFAULTNAMINGCONTEXT" "(&(objectClass=ldapServer)(ldapHostServer=cn=$DCSERVER,ou=OESSystemObjects,$DEFAULTNAMINGCONTEXT))"|grep "ldapi://%2fvar%2fopt%2fnovell%2fxad%2" > /dev/null 2>&1
      if [ $? -eq "0" ]; then
          log "    ${GREEN}GOOD${NC}\n"
      else
          /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "ou=novell,$DEFAULTNAMINGCONTEXT" "(&(objectClass=ldapServer)(ldapHostServer= cn=$DCSERVER,ou=OESSystemObjects,$DEFAULTNAMINGCONTEXT))"|grep "ldap://:389 ldaps://:636 ldapi://%2fvar%2fopt%2fnovell%2fxad%2" > /dev/null 2>&1
        if [ $? -eq "0" ]; then
            log "    ${GREEN}GOOD${NC}\n"
        else
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            log "    ${RED}ERROR: ldapInterface is not configured correctly ${NC}"
            log "     Run ${BOLD}ldapconfig -s "ldapinterfaces=ldap://:389 ldaps://:636 ldapi://%2fvar%2fopt%2fnovell%2fxad%2frun%2fldapi cldap:// ldap://:3268 ldaps://:3269"${NC}"
            if [ ! -f ~/bin/delete_ObjectSid_User.sh ]; then # if script does not exist then download
                if [ $UPDATE = "YES" ]; then
                    wget -q -T 5 -P ~/bin/ http://dsfwdude.com/downloads/fix_ldap_objects.sh
                    chmod +x ~/bin/fix_ldap_objects.sh
                fi
            fi
            TIMELIMIT=20
            echo -ne "Do you want fix the ldapInterface ${BOLD}${NC} now? (y/N):"
            read -t $TIMELIMIT REPLY # set timelimit on REPLY 
            if [ -z "$REPLY" ]; then   # if REPLY is null then exit
                log "    Timeout, did not fix ldapInterface"
            elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
                log "    Fixing ldapInterfaces"
                ~/bin/fix_ldap_objects.sh
                sleep 1
                xadcntrl reload
                sleep 5
            fi
            log "    See ${BCYAN}TID 7010319${NC} for more information\n"
        fi
      fi
    fi
else
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        log "    Can not perform this check because $LDAPSEARCHRES, Skipping\n"
fi

NMASMETH=(IPCLCMLIN IPCLSMLIN libkrb5 gssapi SPNEGO LCMMD5LIN LSMMD5LIN)
for method in ${NMASMETH[*]}; do
((C++))
#log "$C) Checking IPCEXTERNAL method is loaded in ndsd memory ${BOLD}lsof -p `pidof ndsd`|grep IPC${NC}"
log "$C) Checking $method method is loaded in ndsd memory ${BOLD}lsof -p `pidof ndsd`|grep $method${NC}"
    sleep .5
    lsof -p `pidof ndsd`|egrep -i $method --quiet
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: $method is NOT in ndsd memory ${NC}"
        log "	 Verify the Method is installed and the Sequence is active"
        log "	 Take a ldap/nmas trace (TID 7009602) and check the /var/log/messages"
        log "	 Verify the stream file for the method (TID 7009590)"
        log "    Add a replica of ROOT (TID 7011515)\n"
    fi
done


NMASMETH=(LCMKRB5LIN LSMKRB5LIN)
for method in ${NMASMETH[*]}; do
((C++))
log "$C) Checking $method method is loaded in ndsd memory ${BOLD}lsof -p `pidof ndsd` |grep -i $method ${NC}"
    sleep .5
    lsof -p `pidof ndsd` |egrep -i $method --quiet #> /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
#        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
#        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    KERBEROS is NOT in ndsd memory ${NC}"
        log "    This method is ${BOLD}NOT${NC} required for DSfW"
        log "    This method is used by Novell CIFS"
        log "    If Novell CIFS is installed on another server:"
        log "     Verify the Method is installed and the Sequence is active"
        log "	  Take a ldap/nmas trace (TID 7009602) and check the /var/log/messages"
        log "	  Verify the stream file for the method (TID 7009590)"
        log "	  Add a replica of ROOT (TID 7011515)\n"
    fi
done
#((C++))
# /usr/bin/ldapsearch -x -LLL -Q -b "cn=Default Password Policy,cn=Password Policies,cn=System,$DOMAIN" |grep -i -E 'nspmNonAlphaCharactersAllowed: FALSE|nspmLowerAsLastCharacter: TRUE|nspmLowerAsFirstCharacter: TRUE|nspmExtendedCharactersAllowed: TRUE|nspmCaseSensitive: FALSE|nspmSpecialAsLastCharacter: TRUE|nspmSpecialAsFirstCharacter: TRUE|nspmSpecialCharactersAllowed: TRUE|nspmNumericAsLastCharacter: TRUE|nspmNumericAsFirstCharacter: TRUE|nspmNumericCharactersAllowed: TRUE|nspmAdminsDoNotExpirePassword: TRUE' |sort -u


# check netbios name with nbmlookup
((C++))
NETBIOSNAME=`grep "workgroup =" /etc/samba/smb.conf | cut -d = -f2 |sed -e 's/^[ \t]*//'`
log "$C) Checking the netbios name using command ${BOLD}nmblookup ${NETBIOSNAME}${NC}"
    sleep .5
    nmblookup ${NETBIOSNAME} > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        MMD5LIN
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: Domain Controller is NOT located ${NC}"
        log "	 Check netbios is working (TID 7012934)"
        log "	 Take a ldap/nmas trace (TID 7009602) and check the /var/log/messages\n"
    fi

# check that the DC is responding
((C++))
log "$C) Checking the Domain Controller using command ${BOLD}provision --locate-dc $DOMAIN${NC}"
    sleep .5
    /opt/novell/xad/sbin/provision --locate-dc $DOMAIN > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: Domain Controller is NOT located ${NC}"
        log "	 Check netbios is working (TID 7012934)"
        log "	 Take a ldap/nmas trace (TID 7009602) and check the /var/log/messages\n"
    fi

# check keytab exits
((C++))
log "$C) Checking krb5.keytab exits ${BOLD}/var/opt/novell/xad/ds/krb5kdc/krb5.keytab${NC}"
    if [[  ! -z /var/opt/novell/xad/ds/krb5kdc/krb5.keytab  ]]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: krb5.keytab file does not exist ${NC}"
        log "    Follow TID 7004954 to create the keytab and symbolic link\n" 
    fi

# check keytab permissions
((C++))
    log "$C) Checking ${BOLD}krb5.keytab permissions${NC}"
    KEYTABPERMISSION=`ls -l /var/opt/novell/xad/ds/krb5kdc/krb5.keytab | awk '{ print $1 }'`
    if [[ "$KEYTABPERMISSION" = '-rw-r-----' ]]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: krb5.keytab permissions are incorrect${NC}"
        log "	 The krb5.keytab permissions are $KEYTABPERMISSION"
        log "	 Should be -rw-r-----"
    fi

 if [ $CRON_SETTING -eq 0 ]; then
# check that kinit is able to issue a ticket for Administrator
((C++))
    log "$C) Checking kinit is able to issue a ticket for Administrator - ${BOLD}kinit Administrator@$DOMAIN${NC}"
        sleep .5
        echo $ADMPASSWD | /opt/novell/xad/bin/kinit Administrator@$DOMAIN > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
        KINITSTATUS=YES
    else
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        log "    ${yellow}WARNING: kinit is NOT operational ${NC}"
        echo -ne "\tDo you want to re-enter Administrators password and continue? (y/n): "
        read REPLY
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
            ADMPASSWD=""
            if [[ $ADM_CASA = 1 ]]; then
             #   setAdministratorCasa
                echo -en "Please enter Administrator's password: "
                read -s ADMPASSWD    
            else
                echo -en "Please enter Administrator's password: "
                read -s ADMPASSWD    
            fi
            echo $ADMPASSWD | /opt/novell/xad/bin/kinit Administrator@$DOMAIN > /dev/null 2>&1
            if [ $? -eq "0" ]; then
                log "\n    ${GREEN}GOOD${NC}\n"
                KINITSTATUS=YES
            else
                ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
                ERROR_KDC=("${ERROR_KDC[@]}" "$C")
                unset WARNING_NUMBER[${#WARNING_NUMBER[@]}-1]
                KINITSTATUS=NO
                log "\n    ${RED}kinit is still NOT operational${NC}"
                log "\tBe sure the Administrators password was entered correctly"
                log "\tVerify the Administrator's userPrincipalName is unique - TID 7015463"
                log "\tRun 'kinit Administrator'"
                log "\tTake a ldap/nmas trace (TID 7009602) and check the /var/log/messages for troubleshooting"
                log ""
                log "\tIf the following error is returned while running kinit Administrator"
                log "\tkinit(v5): Clients credentials have been revoked while getting initial credentials"
                log "\tThen most likely the account is locked out\n"
            fi
        else
                ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
                ERROR_KDC=("${ERROR_KDC[@]}" "$C")
                unset WARNING_NUMBER[${#WARNING_NUMBER[@]}-1]
                log "\n    ${RED}kinit is still NOT operational${NC}"
                log "\tBe sure the Administrators password was entered correctly"
                log "\tRun 'kinit Administrator'"
                log "\tTake a ldap/nmas trace (TID 7009602) and check the /var/log/messages for troubleshooting"
                log "\tIf while running kinit Administrator the following error is returned"
                log "\tkinit(v5): Clients credentials have been revoked while getting initial credentials"
                log "\tThe account is locked out\n"
        fi
    fi

# check for netbios name
((C++))
log "$C) Checking the NetBIOS Name - ${BOLD}/opt/novell/xad/sbin/provision -q --query $DOMAIN | grep -i 'NetBIOS Name:'${NC}"
    if test "$KINITSTATUS" = "YES"; then
    /opt/novell/xad/sbin/provision -q --query $DOMAIN | grep -i 'NetBIOS Name:' > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        sleep 10
        /opt/novell/xad/sbin/provision -q --query $DOMAIN | grep -i 'NetBIOS Name:' > /dev/null 2>&1
        if [ $? -eq "0" ]; then
            log "    ${GREEN}GOOD${NC}\n"
        else
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_SMB=("${ERROR_SMB[@]}" "$C")
            log "    ${RED}ERROR: NetBIOS name was not returned $DOMAIN ${NC}"
            log "    Start with NetBIOS name resolution"
            log "    Enable Wins - (TID 7012934)"
            log "    Run the command provision -q --query $DOMAIN | grep -i 'NetBIOS Name:'"
            log "    See TID 7012934 for more information"
            log "    Verify the CA server is up and root partition is in sync\n"
        fi
    fi
    fi
 fi # end [ CRON_SETTING -eq 0]

# check that the IPCEXTERNAL method is working
((C++))
log "$C) Checking ldap using command ${BOLD}ldapsearch -Y EXTERNAL -b '' -s base dn${NC}"
    sleep .5
    /usr/bin/ldapsearch -Y EXTERNAL -b '' -s base dn -LLL > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: LDAPI EXTERNAL method is NOT working ${NC}"
        log "    Check that IPCEXTERNAL method is installed"
        log "	 Take a ldap trace (TID 7009602) and look for errors\n"
    fi

if [ $CRON_SETTING -eq 0 ]; then # if CRON_SETTING is not enabled then run this section
domaincntrl --list > /dev/null 2>&1
# check ldap and SASL-GSSAPI
((C++))
    log "$C) Checking SASL-GSSAPI using command ${BOLD}ldapsearch -Y GSSAPI -b '' -s base${NC}"
    if test "$KINITSTATUS" = "YES"; then
        sleep .5
        /usr/bin/ldapsearch -Y GSSAPI -b '' -s base dn -LLL > /dev/null 2>&1
        if [ $? -eq "0" ]; then
             log "    ${GREEN}GOOD${NC}\n"
        else
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            log "    ${RED}ERROR: ldapsearch using SASL-GSSAPI bind is NOT working ${NC}"
            log "    Most likely this is because kinit Administrator fails"
            log "    Check that GSSAPI method is installed"
            log "	 Take a ldap/nmas trace (TID 7009602) and look for errors\n"
        fi
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: kinit Administrator is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
    fi

# check ldap and SASL-GSS-SPNEGO
((C++))
    log "$C) Checking SASL-GSS-SPNEGO using command ${BOLD}ldapsearch -Y GSS-SPNEGO -b '' -s base${NC}"
    if test "$KINITSTATUS" = "YES"; then
        sleep .5
        /usr/bin/ldapsearch -Y GSSAPI -b '' -s base dn -LLL > /dev/null 2>&1
        if [ $? -eq "0" ]; then
            log "    ${GREEN}GOOD${NC}\n"
        else
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            log "    ${RED}ERROR: ldapsearch using SASL-GSSAPI bind is NOT working ${NC}"
            log "    Most likely this is because kinit Administrator fails"
            log "    Check that GSS-SPNEGO method is installed"
            log "	 Take a ldap/nmas trace (TID 7009602) and look for errors\n"
        fi # END check ldap and SASL-GSS-SPNEGO
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: kinit Administrator is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
    fi

# check rpc connection
((C++))
log "$C) Checking rpc connection using command ${BOLD}rpcclient -k localhost -c dsroledominfo${NC}"
    if test "$KINITSTATUS" = "YES"; then
        sleep .5
        /usr/bin/rpcclient -k localhost -c dsroledominfo > /dev/null 2>&1
        if [ $? -eq "0" ]; then
            log "    ${GREEN}GOOD${NC}\n"
        else
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            log "    ${RED}ERROR: rpcclient -k localhost -c dsroledominfo is NOT working${NC}"
            log "	 Look at NetBIOS name resolution"
            log "	 Enable Wins - (TID 7012934)"
            log "	 Take a ldap trace (TID 7009602) and look for errors"
            log "	 Enable Samba debug and tail the /var/log/samba/log.smbd\n"
        fi # END check rpc connection
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: kinit Administrator is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
    fi

# check rpc connection
((C++))
log "$C) Checking rpc connection using command ${BOLD}rpcclient -k ncalrpc: -c dsroledominfo${NC}"
    if test "$KINITSTATUS" = "YES"; then
        sleep .5
        /usr/bin/rpcclient -k ncalrpc: -c dsroledominfo > /dev/null 2>&1
        if [ $? -eq "0" ]; then
            log "    ${GREEN}GOOD${NC}\n"
        else
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            log "    ${RED}ERROR: rpcclient -k ncalrpc: -c dsroledominfo is NOT working${NC}"
            log "	 Take a ldap trace (TID 7009602) and look for errors"
            log "	 Enable Samba debug and tail the /var/log/samba/log.smbd\n"
        fi # END check rpc connection
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: kinit Administrator is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
    fi
fi # END [ CRON_SETTING -eq 0]

# check wbinfo status
((C++))
log "$C) Checking wbinfo status using command ${BOLD}wbinfo -p${NC}"
    sleep .5
    wbinfo -p > /dev/null 2>&1
    if [[ $? == "0" ]]; then
        log "    ${GREEN}GOOD${NC}\n"
        WBINFOPING=YES
    else
        WBINFOPING=NO
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: wbinfo -p is NOT working${NC}"
        log "    Check the status of winbind - rcwinbind status"
        log "    Check the messages log for errors -  grep winbindd /var/log/messages"
        log "    Enable Samba debug and tail the /var/log/samba/log.smbd"
        log "	 Take a ldap trace (TID 7009602) and look for errors"
        log "    The /var/lib/samba/*.tdb files might be corrupt"
        log "    Stop the DSfW services, backup the *.tdb files (tdbbackup /var/lib/samba/*.tdb, delete the *.tdb file, start the services)\n"
    fi # END check wbinfo status

# check wbinfo trust secret
((C++))
log "$C) Checking wbinfo trust secret using command ${BOLD}wbinfo -t${NC}"
# do section on if wbinfo -p is working
if [[ ${WBINFOPING} == "YES" ]]; then
    sleep .5
    wbinfo -t > /dev/null 2>&1
    if [ $? == "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        WBINFOPING=NO
        log "    ${RED}ERROR: wbinfo -t is NOT working${NC}"
        log "    Check the messages log for errors -  grep winbindd /var/log/messages"
        log "    Enable Samba debug and tail the /var/log/samba/log.smbd\n"
        log "	 Take a ldap trace (TID 7009602) and look for errors"
        log "    The /var/lib/samba/*.tdb files might be corrupt"
        log "    Stop the DSfW services, backup the *.tdb files (tdbbackup /var/lib/samba/*.tdb, delete the *.tdb file, start the services)\n"
    fi # END check wbinfo trust secret
else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: wbinfo -t is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
fi

# check name to SID conversion
((C++))
log "$C) Checking name to SID conversion using command ${BOLD}wbinfo -n administrator${NC}"
# do section on if wbinfo -p is working
if [[ ${WBINFOPING} == "YES" ]]; then
    sleep .5
    adminSID=`wbinfo -n administrator | cut -f 1 -d ' '` > /dev/null 2>&1
    if [ "$adminSID" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        WBINFOPING=NO
        log "    ${RED}ERROR: wbinfo name to SID conversion is NOT working${NC}"
        log "	 Run wbinfo -n administrator and check for errors"
        log "	 Try the wbinfo -n command with different users in the domain"
        log "	 Check the messages log for errors -  grep winbindd /var/log/messages"
        log "	 Take a ldap trace (TID 7009602) and look for errors"
        log "	 Enable Samba debug and tail the /var/log/samba/log.smbd"
        log "    The /var/lib/samba/*.tdb files might be corrupt"
        log "    Stop the DSfW services, backup the *.tdb files (tdbbackup /var/lib/samba/*.tdb, delete the *.tdb file, start the services)\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi # END check name to SID conversion
else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: wbinfo name to SID conversion is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
fi

# check SID to name conversion
((C++))
log "$C) Checking SID to name conversion using command ${BOLD}wbinfo -s $adminSID${NC}"
# do section on if wbinfo -p is working
if [[ ${WBINFOPING} == "YES" ]]; then
    sleep .5
    wbinfo -s $adminSID > /dev/null 2>&1
    if [ $? == "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        WBINFOPING=NO
        log "    ${RED}ERROR: wbinfo SID to name conversion is NOT working${NC}"
        log "	 Run wbinfo -n administrator and check for errors"
        log "	 Try the wbinfo -n command with different users in the domain"
        log "	 Check the messages log for errors -  grep winbindd /var/log/messages"
        log "	 Take a ldap trace (TID 7009602) and look for errors"
        log "	 Enable Samba debug and tail the /var/log/samba/log.smbd"
        log "    The /var/lib/samba/*.tdb files might be corrupt"
        log "    Stop the DSfW services, backup the *.tdb files (tdbbackup /var/lib/samba/*.tdb, delete the *.tdb file, start the services)\n"
    fi # END check SID to name conversion
else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: wbinfo SID to name conversion is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
fi

# check SID to uid conversion
((C++))
    log "$C) Checking SID to uid conversion using command ${BOLD}wbinfo -S $adminSID${NC}"
    # do section on if wbinfo -p is working
    if [[ ${WBINFOPING} == "YES" ]]; then
        sleep .5
        adminuid=`wbinfo -S $adminSID` > /dev/null 2>&1
        if [ "$adminuid" == "" ]; then
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            WBINFOPING=NO
            log "    ${RED}ERROR: wbinfo SID to uid conversion is NOT working${NC}"
            log "	 Run wbinfo -n administrator and check for errors"
            log "	 Try the wbinfo -n command with different users in the domain"
            log "	 Check the messages log for errors -  grep winbindd /var/log/messages"
            log "	 Take a ldap trace (TID 7009602) and look for errors"
            log "	 Enable Samba debug and tail the /var/log/samba/log.smbd\n"
        else
            log "    ${GREEN}GOOD${NC}\n"
        fi # END check SID to uid conversion
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: wbinfo SID to uid conversion is NOT working${NC}"
        log "    Can not perform this check because of previous failure, Skipping\n"
    fi # END check SID to uid conversion

# check UID to name conversion
((C++))
    log "$C) Checking UID to name conversion using command ${BOLD}wbinfo -U $adminuid | grep S-1-5-21${NC}"
    # do section on if wbinfo -p is working
    if [[ ${WBINFOPING} == "YES" ]]; then
        sleep .5
        tmp=`wbinfo -U $adminuid | grep S-1-5-21` > /dev/null 2>&1
        if [ "$tmp" == "" ]; then
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_XAD=("${ERROR_XAD[@]}" "$C")
            WBINFOPING=NO
            log "    ${RED}ERROR: wbinfo UID to name conversion is NOT working${NC} "
            log "	 Run wbinfo -n administrator and check for errors"
            log "	 Try the wbinfo -n command with different users in the domain"
            log "	 Check the messages log for errors -  grep winbindd /var/log/messages"
            log "	 Take a ldap trace (TID 7009602) and look for errors"
            log "	 Enable Samba debug and tail the /var/log/samba/log.smbd\n"
        else
            log "    ${GREEN}GOOD${NC}\n"
        fi # END check UID to name conversion
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: wbinfo UID to name conversion is NOT working${NC} "
        log "    Can not perform this check because of previous failure, Skipping\n"
    fi # END - wbinfoPing configuration

if [ $CRON_SETTING -eq 0 ]; then
/opt/novell/xad/sbin/domaincntrl --list > /dev/null 2>&1
# check smb connection
((C++))
    log "$C) Checking smb connection using command ${BOLD}smbclient -k -L $HOST.$DOMAIN${NC}"
    sleep .5
    smbclient -k -L $HOST.$DOMAIN > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: smbclient is NOT working${NC} \n"
        log "	 Take a ldap trace (TID 7009602) and look for errors"
        log "	 Enable Samba debug and tail the /var/log/samba/log.smbd\n"
	fi

# check smb connection sysvol
((C++))
log "$C) Checking smb connection using command ${BOLD}smbclient //$SERVER_NAME/sysvol -k  -I $IPADDR -c "showconnect"${NC}"
    sleep .5
	smbclient //$SERVER_NAME/sysvol -k  -I $IPADDR -c "showconnect" > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: smbclient //$SERVER_NAME/sysvol -k  -I $IPADDR -c "showconnect" is NOT working${NC}\n"
        log "	 Take a ldap trace (TID 7009602) and look for errors"
        log "	 Enable Samba debug and tail the /var/log/samba/log.smbd\n"
    fi

# check smb connection netlogon
((C++))
log "$C) Checking smb connection using command ${BOLD}smbclient //$SERVER_NAME/netlogon -k  -I $IPADDR -c "showconnect"${NC}"
    sleep .5
        smbclient //$SERVER_NAME/sysvol -k  -I $IPADDR -c "showconnect" > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: smbclient //$SERVER_NAME/sysvol -k  -I $IPADDR -c "showconnect" is NOT working${NC}\n"
        log "    Take a ldap trace (TID 7009602) and look for errors"
        log "    Enable Samba debug and tail the /var/log/samba/log.smbd\n"
    fi


fi # END CRON_SETTING

# Set Variables - ldapsearch to retrieve domain name and server name
#DCSERVER=`/usr/bin/ldapsearch -x -b "" -s base |grep serverName: |awk -F '=|,' '{ print $2 }'`
DCSERVER=`/usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "" -s base |grep serverName: |awk -F '=|,' '{ print $2 }'`

# check for domain container has uniquedomainid
((C++))
    log "$C) Checking that ${BOLD}$DEFAULTNAMINGCONTEXT${NC} has a ${BOLD}uniqueDomainID${NC}"
    sleep .5
    lsdc=$(/usr/bin/ldapsearch -Y EXTERNAL -b "$DEFAULTNAMINGCONTEXT" -s base uniquedomainid -LLL -Q |grep uniquedomainid: |cut -d : -f1)
    if [ "$lsdc" == "uniquedomainid" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: $DEFAULTNAMINGCONTEXT does not have a uniqueDomainID${NC}"
        log "    See TID 7009851\n"
        echo -ne "Do you want to add uniqueDomainID to ${BOLD}$DEFAULTNAMINGCONTEXT${NC} now? (y/N):"

        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]; then   # if REPLY is null then exit
            log "    Timeout, did not add uniqueDomainID"
        elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
            log "    Adding uniqueDomainID"
            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s base dn |grep -v ^# |sed -e'/^dn/ a\changetype: modify\nadd: uniquedomainid\nuniquedomainid: '1049076'' > /tmp/add_uniquedomainid.ldif
           echo
           cat /tmp/add_uniquedomainid.ldif
           echo
           /usr/bin/ldapmodify -Y EXTERNAL -f /tmp/add_uniquedomainid.ldif
           NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
           FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
           echo -e "uniqueDomainid has been added"
           /usr/bin/ldapsearch -Y EXTERNAL -b "$DEFAULTNAMINGCONTEXT" -s base uniquedomainid
        fi
    fi

# check that krbtgt has uniquedomainid
((C++))
    log "$C) Checking that ${BOLD}krbtgt${NC} has a ${BOLD}uniqueDomainID${NC}"
    lskrbtgt=$(/usr/bin/ldapsearch -Y EXTERNAL -b "cn=krbtgt,cn=users,$DEFAULTNAMINGCONTEXT" -s base uniquedomainid -LLL -Q |grep uniquedomainid: |cut -d : -f1)
    sleep .5
    if [ "$lskrbtgt" == "uniquedomainid" ]; then
        log "    ${GREEN}GOOD${NC}\n" 
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: krbtgt does not have a uniqueDomainID${NC}"
        log "    See TID 7009851\n"
        echo -ne "Do you want to add uniqueDomainID to ${BOLD}cn=krbtgt,cn=users,$DEFAULTNAMINGCONTEXT${NC} now? (y/N):"

        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]; then   # if REPLY is null then exit
            log "    Timeout, did not add uniqueDomainID"
        elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
            log "    Adding uniqueDomainID"
            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "cn=krbtgt,cn=users,$DEFAULTNAMINGCONTEXT" -s base dn |grep -v ^# |sed -e'/^dn/ a\changetype: modify\nadd: uniquedomainid\nuniquedomainid: '1049076'' > /tmp/add_uniquedomainid.ldif
           echo
           cat /tmp/add_uniquedomainid.ldif
           echo
           /usr/bin/ldapmodify -Y EXTERNAL -f /tmp/add_uniquedomainid.ldif
           NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
           FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
           echo -e "uniqueDomainid has been added"
           /usr/bin/ldapsearch -Y EXTERNAL -b "cn=krbtgt,cn=users,$DEFAULTNAMINGCONTEXT" -s base uniquedomainid
        fi
    fi # END check that krbtgt has uniquedomainid

# check that ou=Domain Controllers has uniquedomainid
((C++))
    log "$C) Checking that ${BOLD}ou=Domain Controllers${NC} has a ${BOLD}uniqueDomainID${NC}"
    lsdcs=$(/usr/bin/ldapsearch -Y EXTERNAL -b "ou=domain controllers,$DEFAULTNAMINGCONTEXT" -s base uniquedomainid -LLL -Q |grep uniquedomainid: |cut -d : -f1)
    sleep .5
    if [ "$lsdcs" == "uniquedomainid" ]; then
        log "    ${GREEN}GOOD${NC}\n" 
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: ou=Domain Controllers does not have a uniqueDomainID${NC}"
        log "    See TID 7009851\n"
        echo -ne "Do you want to add uniqueDomainID to ${BOLD}ou=domain controllers,$DEFAULTNAMINGCONTEXT${NC} now? (Y/n):"

        # set timelimit on REPLY 
        read -t $TIMELIMIT REPLY 

        # if REPLY is null then exit
        if [ -z "$REPLY" ]; then
            log "    Timeout, did not add uniqueDomainID"
        elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
            log "    Adding uniqueDomainID"
            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "ou=domain controllers,$DEFAULTNAMINGCONTEXT" -s base dn |grep -v ^# |sed -e'/^dn/ a\changetype: modify\nadd: uniquedomainid\nuniquedomainid: '1049076'' > /tmp/add_uniquedomainid.ldif
           echo
           cat /tmp/add_uniquedomainid.ldif
           echo
           /usr/bin/ldapmodify -Y EXTERNAL -f /tmp/add_uniquedomainid.ldif
           NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
           FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
           echo -e "uniqueDomainid has been added"
           /usr/bin/ldapsearch -Y EXTERNAL -b "ou=domain controllers,$DEFAULTNAMINGCONTEXT" -s base uniquedomainid
        fi
    fi # END check that ou=Domain Controllers has uniquedomainid

# check that domain controller server object has uniquedomainid
((C++))
    log "$C) Checking that ${BOLD}cn=$DCSERVER,ou=Domain Controllers,$DEFAULTNAMINGCONTEXT${NC} has a ${BOLD}uniqueDomainID${NC}"
    lsDCSERVER=$(/usr/bin/ldapsearch -Y EXTERNAL -b "cn=$DCSERVER,ou=domain controllers,$DEFAULTNAMINGCONTEXT" -s base uniquedomainid -LLL -Q |grep uniquedomainid: |cut -d : -f1)
    sleep .5
    if [ "$lsDCSERVER" == "uniquedomainid" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: $DCSERVER does not have a uniqueDomainID${NC}"
        log "    See TID 7009851\n"
        echo -ne "Do you want to add uniqueDomainID to ${BOLD}cn=krbtgt,cn=users,$DCSERVER${NC} now? (y/N):"
        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]; then   # if REPLY is null then exit
            log "    Timeout, did not add uniqueDomainID"
        elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
            log "    Adding uniqueDomainID"
            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "cn=$DCSERVER,ou=Domain Controllers,$DEFAULTNAMINGCONTEXT" -s base dn |grep -v ^# |sed -e'/^dn/ a\changetype: modify\nadd: uniquedomainid\nuniquedomainid: '1049076'' > /tmp/add_uniquedomainid.ldif
           echo
           cat /tmp/add_uniquedomainid.ldif
           echo
           /usr/bin/ldapmodify -Y EXTERNAL -f /tmp/add_uniquedomainid.ldif
           FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
           echo -e "uniqueDomainid has been added"
           /usr/bin/ldapsearch -Y EXTERNAL -b "cn=$DCSERVER,ou=Domain Controllers,$DEFAULTNAMINGCONTEXT" -s base uniquedomainid
        fi
    fi # END check that domain controller server object has uniquedomainid

if [ $DUP_UIDNUMBER = 1 ]; then
# Check for duplicate uidNumber
((C++))
    log "$C) Checking for ${BOLD}duplicate uidNumbers${NC} "
    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s sub "(&(objectclass=*)(uidNumber=*))" dn uidNumber|sed s[uidNumber['changetype:modify\nreplace:uidNumber\nuidNumber'[g | grep -v ^# |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' > /var/opt/novell/xad/uidNumbers_restore_`date +%F_time-%H:%M`.ldif
    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s sub "(&(objectclass=*)(uidNumber=*))" cn uidNumber |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' >/tmp/uidNumbers.log
    sleep .2
    uids=$(grep -i uidNumber: /tmp/uidNumbers.log|sort |uniq -ci |sort -n |grep -v ' 1 ' | grep -v "uidNumber: 30" | grep -v "uidNumber: 81" | grep -v "uidNumber: 82" |awk '{print $3}')
    sleep .2
    uids2=$(echo $uids | sed -e 's/ /\\|/g')
    grep -e $uids2 -B2 /tmp/uidNumbers.log >/tmp/duplicateuidNumbers.log

    if [[ -s /tmp/duplicateuidNumbers.log ]]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    \e[1;31mERROR: Duplicate uidNumbers reported${NC}"
        log "    List of Objects with duplicate uidNumbers"
        log "    Log located at ${RED}/tmp/duplicateuidNumbers.log${NC}"
        log "    $(cat /tmp/duplicateuidNumbers.log)\n"
        log "    Modify the duplicate uidNumbers"
        log "    If there is a backup of uidNumbers, consider restore the backup\n"
#        if [ ! -f ~/bin/delete_uidNumber.sh ]; then # if script does not exist then download
#                 wget -q -T 5 -P ~/bin/ http://dsfwdude.com/downloads/delete_uidNumber.sh
#                 chmod +x ~/bin/delete_uidNumber.sh
#        fi
    else
        log "    ${GREEN}GOOD${NC}\n"
        rm /tmp/duplicateuidNumbers.log
        rm /tmp/uidNumbers.log
    fi
fi # END Check for duplicate uidNumber


# Check for multiple userePrincipalName
#((C++))
#    log "$C) Checking for ${BOLD}duplicate userPrincipalNames${NC} "
#    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s sub "(&(objectclass=user)(userPrincipalName=*))" dn userPrincipalName |grep -i userPrincipalName: |sort |uniq -c |sort -n |grep -v ' 1 ' |awk '{print $3}' |grep -v wwwrun |grep -v novlx > /tmp/userPrincipalNames.log


# Check for multiple servicePrincipalName
#((C++))
#    log "$C) Checking for ${BOLD}duplicate servicePrincipalNames${NC} "
#    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s sub "(&(objectclass=computer)(servicePrincipalName=*))" dn servicePrincipalName |grep -i servicePrincipalName: |sort |uniq -c |sort -n |grep -v ' 1 ' |awk '{print $3}' > /tmp/servicePrincipalNames.log
#    sleep .2
#    sids=$(grep -i servicePrincipalName: /tmp/servicePrincipalNames.log|sort |uniq -c |sort -n |grep -v ' 1 ' |awk '{print $3}')
#    sleep .2
#    sids2=$(echo $sids | sed -e 's/ /\\|/g')
#    sleep .2
#    grep -e $sids2 -B2 /tmp/servicePrincipalNames.log  >/tmp/duplicateObjectsids.log


# Netx uidNumber
((C++))
    log "$C) Reporting the ${BOLD}Largest Assigned UID${NC}"
    AUID=$(ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" "uidNumber=*" uidNumber  2>/dev/null | grep -v dn: | sed -rn "/[0-9]{7,9}/p" | sort -n |tail -1 | sed -e "s/uidNumber: //g")
    log "    The Largest Assigned UID # is ${GREEN}$AUID${NC}\n"

# Check for duplicate objectSids
((C++))
    log "$C) Checking for ${BOLD}duplicate objectSids${NC} "
    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s sub "(&(objectclass=*)(objectSid=*))" dn objectSid|sed s[objectSid['changetype:modify\nreplace:objectSid\nobjectSid'[g | grep -v ^# |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' > /var/opt/novell/xad/objectSids_restore_`date +%F_time-%H:%M`.ldif
    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s sub "(&(objectclass=user)(!(|(cn:dn:=Builtin)(cn:dn:=Configuration)))(objectSid=*))" cn objectSid |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' >/tmp/objectSids.log
    sleep .2
    sids=$(grep -i objectSid:: /tmp/objectSids.log|sort |uniq -ci |sort -n |grep -v ' 1 ' |awk '{print $3}')
    sleep .2
    sids2=$(echo $sids | sed -e 's/ /\\|/g')
    sleep .2
    grep -e $sids2 -B2 /tmp/objectSids.log  >/tmp/duplicateObjectsids.log

    if [  -s /tmp/duplicateObjectsids.log ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: Duplicate ObjectSIDs reported${NC}"
        log "    List of Objects with duplicate objectSids${NC}"
        log "    Log located at /tmp/duplicateObjectsids.log"
        log "    \t$(cat /tmp/duplicateObjectsids.log)"
        if [ ! -f ~/bin/delete_objectSids.sh ]; then # if script does not exist then download
            if [ $UPDATE = "YES" ]; then
                 wget -q -T 5 -P ~/bin/ http://dsfwdude.com/downloads/delete_objectSids.sh
                 chmod +x ~/bin/delete_objectSids.sh
            fi
        fi
        log
        log "    Run delete_objectSids.sh to remove objectSid from listed objects"
        log "    Do not remove objectSids from system created users (Administrator, Guest, etc...)"
        log "    Check for duplicate uidNumbers, duplicate objetSids can be caused by uidNumber"
        log "    If there is a backup of objectSids, consider restoring the backup\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
        rm /tmp/duplicateObjectsids.log
    fi
    rm /tmp/objectSids.log

# Next RID
((C++))
    log "$C) Reporting the ${BOLD}Next RID${NC}"
    NEXTRID=$(ldapsearch -Y EXTERNAL -LLL -Q -b "ou=domain controllers,$DEFAULTNAMINGCONTEXT" "cn=RID Set" rIDNextRID  2>/dev/null | sed ' /^ / {; H; d; }; /^ /! {; x; s/\n //; }; ' | grep -i "rIDNextRID" |awk  '{print $2}')
    log "    The Next RID is ${GREEN}$NEXTRID${NC}\n"
    # END DISPLAY_FSMO setting

# check cldap request to netlogon
((C++))
    log "$C) Checking cldap to returns netlogon ${BOLD}ldapsearch -H cldap://localhost:389 '(&(DnsDomain=$DOMAIN)(Host=$HOST.$DOMAIN)(NtVer="\006"))' -b '' -s base netlogon | grep -i netlogon${NC}"
    lsdcnetlogon=$(ldapsearch -H cldap://localhost:389 "(&(DnsDomain=$DOMAIN)(Host=$HOST.$DOMAIN)(NtVer=\006))" -b "" -s base  netlogon 2>&1 | grep -i netlogon
)
    sleep .5
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_XAD=("${ERROR_XAD[@]}" "$C")
        log "    ${RED}ERROR: $HOST does return netlogon${NC}"
        log "    Take a ldap/nmas trace (TID 7009602) and look for errors"
        log "	 How active is the Domain Controller is?"
        log "    How many active users are there?"
        log "    If there are over 200 active users another domain controller might help\n"
    fi

# check /var/log/messages for xadsd: [NETLOGON] Workstation * failed to authenticate: 0xc0000022
((C++))
    log "$C) Checking /var/log/messages for ${BOLD}NETLOGON 0xc0000022${NC} errors"
    grep -e 'failed to authenticate: 0xc0000022' /var/log/messages|grep -e "NETLOGON" > /dev/null 2>&1
    if [ $? == "0" ]; then
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        log "    ${yellow}WARNING: xdsd: [NETLOGON] Workstation failed to authenticate: 0xc0000022 found${NC}"
        log "    Start with ${BCYAN}TID 7014322${NC}"
        log "    If new errors persist take a ldap/nmas trace (TID 7009602) and look for errors\n"
        
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi

# check for winbind: Exceeding 200 errors
((C++))
    log "$C) Checking /var/log/messages for ${BOLD}winbind: Exceeding 200${NC} errors"
    sleep .5
    grep -e "winbind: Exceeding 200" /var/log/messages
    if [ $? == "0" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_MESSAGES=("${ERROR_MESSAGES[@]}" "$C")
        log "    ${yellow}ERROR: winbind: Exceeding 200 client connections, no idle connections found${NC}"
        log "    Check the kdc.log for errors"
        log "    Check the log.smbd for errors"
        log "    Take a ldap/nmas trace (TID 7009602) and look for errors"
        log "    If there are several searches for tokenGroupsDomainLocal see ${BCYAN}TID 7011498${NC}"
        log "    The /var/lib/samba/*.tdb files might be corrupt"
        log "    Stop the DSfW services, backup the *.tdb files (tdbbackup /var/lib/samba/*.tdb, delete the *.tdb file, start the services)"
        log "    How active is the Domain Controller?"
        log "    How many active users are there?"
        log "    If there are over 200 active users another domain controller might help\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi # END check for winbind: Exceeding 200 errors

#check kdc.log for Decrypt integrity check failed
((C++))
    TMP_FILE1=`mktemp`
    TMP_FILE2=`mktemp`
    log "$C) Checking kdc.log for ${BOLD}Decrypt integrity check failed (Bad Passwords)${NC} errors"
    tput setaf 3; tput bold 
    grep -A1 -i 'Decrypt integrity check failed' /var/opt/novell/xad/log/kdc.log |grep -v 'Decrypt integrity check failed' |awk -F ')' '{print $3}' |grep -v '^$' |awk -F 'for' '{print $1}'|sed -e 's/://'|sed -e 's/PREAUTH_FAILED://' |sort -n | uniq -ci | sort -n |tail|sed -e 's/^[ \t]*//'|egrep '^[0-9]{2} '|sed -e 's/^/      /' > $TMP_FILE1
    tput sgr0
    grep -A1 -i 'Decrypt integrity check failed' /var/opt/novell/xad/log/kdc.log |grep -v 'Decrypt integrity check failed' |awk -F ')' '{print $3}' |grep -v '^$' |awk -F 'for' '{print $1}'|sed -e 's/://'|sed -e 's/PREAUTH_FAILED://' |sort -n | uniq -ci | sort -n |tail|sed -e 's/^[ \t]*//'|egrep '^[0-9]{3}'|sed -e 's/^/     /' > $TMP_FILE2
	if [ -s $TMP_FILE1 ] && [ -s $TMP_FILE2 ]; then
        log "    ${RED}Decrypt integrity check failed (Bad Passwords) errors found in the kdc.log${NC}"
        log "     Reporting 10 or more instances of Decrypt integrity check failed"
        log "     #     IP Address      User/Computer"
        tput setaf 3; #tput bold 
        cat $TMP_FILE1 |tee -a $LOG
        tput setaf 1; #tput bold 
        cat $TMP_FILE2 |tee -a $LOG
        tput sgr0
        log "     Principals with${BOLD} $ ${NC}are workstations - Example: ${BOLD}workstation"'$'"@dsfw.lan${NC}"
        log "     10 - 99 instances returned is a concern and can have an impact on performance"
        log "     100 + is a problem and is most likely causing slow logins or poor performance"
        log "     Follow the kerberos section in ${BCYAN}TID 7010462${NC}\n"
    elif [ -s $TMP_FILE1 ]; then
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        log "    ${yellow}WARNING: Decrypt integrity check failed (Bad Passwords) errors found in the kdc.log${NC}"
        log "     Reporting 10 - 99 instances of Decrypt integrity check failed"
        log "     #     IP Address      User/Computer"
        tput setaf 3; #tput bold 
        cat $TMP_FILE1 |tee -a $LOG
        tput sgr0
        log "     Principals with${BOLD} $ ${NC}are workstations - Example: ${BOLD}workstation"'$'"@dsfw.lan${NC}"
        log "     10 - 99 instances returned is a concern and can have an impact on performance"
        log "     Follow the kerberos section in ${BCYAN}TID 7010462${NC}\n"
    elif [ -s $TMP_FILE2 ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: Decrypt integrity check failed (Bad Passwords) errors found in the kdc.log${NC}"
        log "     Reporting 100 or more instances of Decrypt integrity check failed"
        log "     #     IP Address      User/Computer"
        tput setaf 1; #tput bold 
        cat $TMP_FILE2 |tee -a $LOG
        tput sgr0
        log "     Principals with${BOLD} $ ${NC}are workstations - Example: ${BOLD}workstation"'$'"@dsfw.lan${NC}"
        log "     100 + is a problem and is most likely causing slow logins or poor performance"
        log "     Follow the kerberos section in ${BCYAN}TID 7010462${NC}\n"
    else 
        log "    ${GREEN}GOOD${NC}\n"
    fi # END check kdc.log for Decrypt integrity check failed
    rm $TMP_FILE1 # Clean up temp files
    rm $TMP_FILE2

#check kdc.log for client not found
((C++))
    TMP_FILE3=`mktemp`
    TMP_FILE4=`mktemp`
    log "$C) Checking kdc.log for ${BOLD}CLIENT_NOT_FOUND (Account Does not Exist)${NC} errors"
    grep -i 'client not found' /var/opt/novell/xad/log/kdc.log |cut -d ')' -f3 |awk -F 'for' '{print $1}' |sed -e 's/://'|sed -e 's/CLIENT_NOT_FOUND://'|sort -n | uniq -ci |sort -n |tail|sed -e 's/^[ \t]*//'|egrep '^[0-9]{2} '|sed -e 's/^/      /' > $TMP_FILE3
    grep -i 'client not found' /var/opt/novell/xad/log/kdc.log |cut -d ')' -f3 |awk -F 'for' '{print $1}' |sed -e 's/://'|sed -e 's/CLIENT_NOT_FOUND://'|sort -n | uniq -ci |sort -n |tail|sed -e 's/^[ \t]*//'|egrep '^[0-9]{3}'|sed -e 's/^/     /' > $TMP_FILE4
    if [ -s $TMP_FILE3 ] && [ -s $TMP_FILE4 ]; then
        log "    ${RED}CLIENT_NOT_FOUND errors found in the kdc.log${NC}"
        log "     Reporting 10 or more instances of CLIENT_NOT_FOUND"
        log "     #     IP Address      User/Computer"
        tput setaf 3; #tput bold 
        cat $TMP_FILE3 |tee -a $LOG
        tput setaf 1; #tput bold 
        cat $TMP_FILE4 |tee -a $LOG
        tput sgr0
        log "     Principals with${BOLD} $ ${NC}are workstations - Example: ${BOLD}workstation"'$'"@dsfw.lan${NC}"
        log "     10 - 99 instances returned is a concern and can have an impact on performance"
        log "     100 + is a problem and is most likely causing slow logins or poor performance"
        log "     Follow the kerberos section in ${BCYAN}TID 7010462${NC}\n"
    elif [ -s $TMP_FILE3 ]; then
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        log "    ${yellow}WARNING: CLIENT_NOT_FOUND errors found in the kdc.log${NC}"
        log "     Reporting 10 - 99 instances of CLIENT_NOT_FOUND"
        log "     #     IP Address      User/Computer"
        tput setaf 3; #tput bold 
        cat $TMP_FILE3 |tee -a $LOG
        tput sgr0
        log "     Principals with${BOLD} $ ${NC}are workstations - Example: ${BOLD}workstation"'$'"@dsfw.lan${NC}"
        log "     10 - 99 instances returned is a concern and can have an impact on performance"
        log "     Follow the kerberos section in ${BCYAN}TID 7010462${NC}\n"
    elif [ -s $TMP_FILE4 ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_KDC=("${ERROR_KDC[@]}" "$C")
        log "    ${RED}ERROR: CLIENT_NOT_FOUND errors found in the kdc.log${NC}"
        log "     Reporting 100 or more instances of CLIENT_NOT_FOUND"
        log "     #     IP Address      User/Computer"
        tput setaf 1; #tput bold 
        cat $TMP_FILE4 |tee -a $LOG
        tput sgr0
        log "     Principals with${BOLD} $ ${NC}are workstations - Example: ${BOLD}workstation"'$'"@dsfw.lan${NC}"
        log "     100 + is a problem and is most likely causing slow logins or the server to hang"
        log "     Follow the kerberos section in ${BCYAN}TID 7010462${NC}\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi # END check kdc.log for client not found
    rm $TMP_FILE3
    rm $TMP_FILE4


# check UPN Setting
DNSDOMAIN=`/usr/bin/ldapsearch -x -b "" -s base dnsDomain | grep -i 'dnsDomain: ' | awk '{print $2}'`
((C++))
    log "$C) Checking ${BOLD}upn setting${NC} for ${BOLD}dnsDomainName = $DEFAULTNAMINGCONTEXT${NC}"
    sleep .5
    DNSDOMAINSETTING=$(/usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" "(&(admindescription=*))" adminDescription |grep -i 'adminDescription: ' | awk '{print $2}') 2> /dev/null
    if [[ ${DNSDOMAINSETTING} = "dnsDomainName=${DNSDOMAIN}" ]]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        log "    ${yellow}WARNING: UPN is not configured${NC}"
        log "    Current setting is ${DNSDOMAINSETTING}"
        log "    If UPN is not used this can be ignored"
        log "    Otherwise add ${BOLD}dnsDomainName=${DNSDOMAIN}${NC} to adminDiscription on the name mapped container"
        if [ ! -f ~/bin/delete_ObjectSid_User.sh ]; then # if script does not exist then download
            if [[ ${UPDATE} == "YES" ]]; then
                wget -q -T 5 -P ~/bin/ http://www.dsfwdude.com/downloads/userprincipalname.sh
                chmod +x ~/bin/userprincipalname.sh
            fi
        fi
        log "    See ${BCYAN}TID 7004782${NC} for more information\n"
        echo -ne "Do you want to add ${BOLD}dnsDomainName=${DNSDOMAIN}${NC} to ${BOLD}$DEFAULTNAMINGCONTEXT${NC} now? (y/N):"
        TIMELIMIT=20
        read -t $TIMELIMIT REPLY # set timelimit on REPLY
        if [ -z "$REPLY" ]; then   # if REPLY is null then exit
            log "    Timeout, did not add dnsDomainName=${DNSDOMAIN}\n"
            echo
        elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then Add
            log "    Adding dnsDomainName=${DNSDOMAIN}\n"
            if [[ -n ${DNSDOMAINSETTING} ]]; then # String is non-zero then delete
                /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s base dn |grep -v ^# |sed -e'/^dn/ a\changetype: modify\ndelete: adminDescription' > /tmp/add_dnsDomain.ldif
                /usr/bin/ldapmodify -Y EXTERNAL -Q -f /tmp/add_dnsDomain.ldif
                sleep 2
            fi

            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s base dn |grep -v ^# |sed -e'/^dn/ a\changetype: modify\nadd: adminDescription' |grep -v '^$' > /tmp/add_dnsDomain.ldif
            echo -e "adminDescription: dnsDomainName=${DNSDOMAIN}" >> /tmp/add_dnsDomain.ldif
            echo
            cat /tmp/add_dnsDomain.ldif
            echo
            /usr/bin/ldapmodify -Y EXTERNAL -Q -f /tmp/add_dnsDomain.ldif
            NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
            FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
            echo -e "dnsDomainName=${DNSDOMAIN} has been added"
            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s base adminDescription
            
        fi
    fi # END check UPN Setting
    echo

if [ $DISPLAY_FSMO -eq 1 ]; then  # Display FSMO Roles
# check RID Manager
((C++))
    log "$C) Reporting the ${BOLD}FSMO Roles${NC}"
    RIDSERVER=$(ldapsearch -Y EXTERNAL -LLL -Q -b "CN=RID Manager$,CN=System,$DEFAULTNAMINGCONTEXT" fSMORoleOwner 2>/dev/null | sed ' /^ / {; H; d; }; /^ /! {; x; s/\n //; }; ' | grep -i "fSMORoleOwner: " | awk -F ": " '{print $2}' | awk -F "," '{print $2}' | awk -F "cn=" '{print $2}' | tr "[:upper:]" "[:lower:]")
    log "    The RID Manager server is ${GREEN}$RIDSERVER${NC}"

    # check PDC Emulator
    PDCSERVER=$(ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" fSMORoleOwner -s base 2>/dev/null | sed ' /^ / {; H; d; }; /^ /! {; x; s/\n //; }; ' | grep -i "fSMORoleOwner: " | awk -F ": " '{print $2}' | awk -F "," '{print $2}' | awk -F "cn=" '{print $2}' | tr "[:upper:]" "[:lower:]")
    log "    The PDC Emulator server is ${GREEN}$PDCSERVER${NC}"

    # check Infrastructure Manager
    InfrastructurSERVER=$(ldapsearch -Y EXTERNAL -LLL -Q -b "CN=Infrastructure,$DEFAULTNAMINGCONTEXT" fSMORoleOwner 2>/dev/null | sed ' /^ / {; H; d; }; /^ /! {; x; s/\n //; }; ' | grep -i "fSMORoleOwner: " | awk -F ": " '{print $2}' | awk -F "," '{print $2}' | awk -F "cn=" '{print $2}' | tr "[:upper:]" "[:lower:]")
    log "    The Infrastructure server is ${GREEN}$InfrastructurSERVER${NC}"

    # check Schema Manager
    SCHEMASERVER=$(ldapsearch -Y EXTERNAL -LLL -Q -b "cn=Schema,cn=Configuration,$DEFAULTNAMINGCONTEXT" fSMORoleOwner 2>/dev/null | sed ' /^ / {; H; d; }; /^ /! {; x; s/\n //; }; ' | grep -i "fSMORoleOwner: " | awk -F ": " '{print $2}' | awk -F "," '{print $2}' | awk -F "cn=" '{print $2}' | tr "[:upper:]" "[:lower:]")
    log "    The Schema Manager server is ${GREEN}$SCHEMASERVER${NC}"

    # check Domain Naming Manager
    PARTITIONSSERVER=$(ldapsearch -Y EXTERNAL -LLL -Q -b "cn=Partitions,cn=Configuration,$DEFAULTNAMINGCONTEXT" fSMORoleOwner 2>/dev/null | sed ' /^ / {; H; d; }; /^ /! {; x; s/\n //; }; ' | grep -i "fSMORoleOwner: " | awk -F ": " '{print $2}' | awk -F "," '{print $2}' | awk -F "cn=" '{print $2}' | tr "[:upper:]" "[:lower:]")
    log "    The Domain Naming Master server is ${GREEN}$PARTITIONSSERVER${NC}\n"

# Validate sysvolsync
((C++))
    log "$C) Validate sysvolsync - ${BOLD}sysvolsync ${NC}"
    /opt/novell/xad/sbin/sysvolsync > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_SYSVOL=("${ERROR_SYSVOL[@]}" "$C")
        log "    ${RED}ERROR: sysvolsync failed ${NC}\n"
        log "    This error can be seen if another DC is down or can not be contacted"
        log "    Check the status of the other domain controllers"
        log "    Verify rsync is running on all DCs"
        log "    Run ${BOLD}sysvolsync -v${NC} and look for errors"
        log "    Look in the /var/opt/novell/xad/log/sysvolsync.log for error"
        log "    Follow ${BCYAN}TID 7013046${NC} to troubleshoot\n"
    fi # END Validate sysvolsync

# Validate gposync
((C++))
    log "$C) Validate gposysnc - ${BOLD}gposync.sh${NC}"
    /opt/novell/xad/sbin/gposync.sh > /dev/null 2>&1
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_GPO=("${ERROR_GPO[@]}" "$C")
        log "    ${RED}ERROR: gposync failed ${NC}\n"
        log "    run gposync and look for errors\n"
    fi # END Validate gposync

# Validate GPOs
((C++))
    log "$C) Validate ${BOLD}GPOs in the sysvol are also in the cn=policies,cn=system,$DEFAULTNAMINGCONTEXT ${NC}"
    /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "cn=policies,cn=system,$DEFAULTNAMINGCONTEXT" -s one 2>&1 | grep dn: |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' | awk -F"," '{print $1}' | awk -F"=" '{print $2}' | sort > /tmp/gpos.txt
    ls  /var/opt/novell/xad/sysvol/domain/Policies/ |awk -F/ '{print $1}' | sort > /tmp/sysvol_gpos.txt
    cmp /tmp/sysvol_gpos.txt /tmp/gpos.txt
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
        # Clean up
        rm /tmp/gpos.txt
        rm /tmp/sysvol_gpos.txt
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_GPO=("${ERROR_GPO[@]}" "$C")
        log "    ${RED}ERROR: GPOs listed in the sysvol and directory do not match ${NC}\n"
        log "    run ${BOLD}vimdiff /tmp/sysvol_gpos.txt /tmp/gpos.txt${NC} to find differences between the files"
        diff /tmp/sysvol_gpos.txt /tmp/gpos.txt 
        diff /tmp/sysvol_gpos.txt /tmp/gpos.txt >> $LOG
        log "    the 1st line, /tmp/sysvol_gpos.txt, reports the GPOs listed on the file system"
        log "    the 2nd line, /tmp/gpos.txt, reports the GPOs listed in the directory under cn=policies,cn=system,$DEFAULTNAMINGCONTEXT"
        log "    run gposync and look for errors\n"
    fi # END Validate GPOs

#Validate Domain has GPO linked
((C++))
    shopt -s nocasematch
    log "$C) Validate ${BOLD}GPO is linked $DEFAULTNAMINGCONTEXT (gPLink attribute)${NC}"
    /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "$DEFAULTNAMINGCONTEXT" -s base '(!(objectclass=rbsModule2))' gPLink 2>&1 |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' | awk -F"[" '{print $2,"\n",$3,"\n",$4,$5,"\n",$6,"\n",$7}' |tr -d ] | sed -e 's/^[ \t]*//' | sed '/^$/d' | sort |grep LDAP 2>&1 >/dev/null
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_GPO=("${ERROR_GPO[@]}" "$C")
        ls  /var/opt/novell/xad/sysvol/domain/Policies/ |awk -F/ '{print $1}' | sort > /tmp/sysvol_gpo.txt
        log "    ${RED}ERROR: There are no GPOs linked to $DEFAULTNAMINGCONTEXT ${NC}"
        log "    The gPLink attribute should return a value similiar to this:"
        log "    [LDAP://CN={31B2F340-016D-11D2-945F-00C04FB984F9},CN=Policies,CN=System,$DEFAULTNAMINGCONTEXT;0]"
        log "    The GPOs listed in the sysvol are:"
        cat /tmp/sysvol_gpo.txt
        cat /tmp/sysvol_gpo.txt >> $LOG
        log ""
        log "    Please use iManager and add a valid GPO (gPLink attribute)"
        log "    Example of what should be in the gPLink attribute:"
        log "    [LDAP://CN={31B2F340-016D-11D2-945F-00C04FB984F9},CN=Policies,CN=System,$DEFAULTNAMINGCONTEXT;0]\n"
    fi
    shopt -u nocasematch
# END Validate Domain has GPO linked

#Validate Domain has GPO linked is valid
((C++))
    GPLINKEDERR=NO
    GPOLINKED=`mktemp`
log "$C) Validate ${BOLD}GPO(s) assigned in $DEFAULTNAMINGCONTEXT exist in sysvol (gPLink attribute)${NC}"
    /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "$DEFAULTNAMINGCONTEXT" -s sub '(!(objectclass=rbsModule2))' gPLink 2>&1 |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' | grep -v 'cn=Role Based Service 2' | awk -F"[" '{print $2,"\n",$3,"\n",$4,"\n",$5,"\n",$6,"\n",$7,"\n",$8,"\n",$9}' |tr -d ] | sed -e 's/^[ \t]*//' | sed '/^$/d' | awk -F"=" '{print $2}' | cut -d, -f1 |sort -u | grep -v {6AC1786C-016F-11D2-945F-00C04fB984F9} > $GPOLINKED

    ls  /var/opt/novell/xad/sysvol/domain/Policies/ |awk -F/ '{print $1}' | sort > /tmp/sysvol_gpo.txt
    ctr0=0;while read i ; do echo $i;gpolist[$ctr0]="${i}"; let ctr0=ctr0+1; done < ${GPOLINKED} > /dev/null
    for i in `seq 0 "${#gpolist[@]}"`; do gpoa="${gpolist[$i]}"; if [[ -n ${gpoa} ]]; then currentGplink="${gpoa}"; else break; fi;
    log "    $currentGplink"
    sleep .1
    grep $currentGplink /tmp/sysvol_gpo.txt > /dev/null
    if [ $? -eq "1" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_GPO=("${ERROR_GPO[@]}" "$C")
        GPLINKEDERR=YES
        log "    ${RED}ERROR: The GPO linked is not valid${NC}\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    done
    if [[ $GPLINKEDERR = "YES" ]]; then
        log "    Do the following ldapsearch to see the GPOs and the containers they are linked to"
        log "    /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "$DEFAULTNAMINGCONTEXT" -s sub "gPLink=*" gPLink"
        /usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "$DEFAULTNAMINGCONTEXT" -s sub "gPLink=*" gPLink | sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' >>$LOG
        log "    Examine the output and look for the GPO receiving the error"
        log "    Please use GPMC to unlink the invalid GPO or use iManager to remove the invalid GPO from the gPLink attribute\n"
        log "    The GPO(s) listed in the sysvol are:"
        cat /tmp/sysvol_gpo.txt  
        cat /tmp/sysvol_gpo.txt >> $LOG
        log ""
        log "    The GPO(s) found linked in the domain (gPLink attribute) are:"
        cat $GPOLINKED 
        cat $GPOLINKED >> $LOG
        log ""
    fi
    # Clean up
    rm /tmp/sysvol_gpo.txt
    rm $GPOLINKED
# END Validate Domain has GPO linked valid

((C++))
log "$C) Checking for ${BOLD}Role Based Services containers in the domain${NC}"
    LDAPSEARCHRES=0
    RBS=`/usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "$DEFAULTNAMCONTEXT" -s sub '(&(objectclass=rbscollection2))' dn`
    sleep .2
    if [[ -z $RBS ]]; then
        log "    ${GREEN}GOOD${NC}\n"
    else
	WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        log "    ${YELLOW}WARNING: A RBS container is located within the domain${NC}"
        log "    The RBS container is ${BOLD}$RBS ${NC}"
        log "    It is recommended to partition off the RBS container or move to a container outside of the domain\n"
    fi

#Validate Domain has GPO linked to domain controllers
#((C++))
#shopt -s nocasematch
#log "$C) Validate ${BOLD}GPO is linked to domain controllers (gPLink attribute)${NC}"
#    GPODC=`/usr/bin/ldapsearch -LLLQ -Y EXTERNAL -b "ou=Domain controllers,$DEFAULTNAMINGCONTEXT" -s base gPLink 2>&1 |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' | awk -F"[" '{print $2,"\n",$3,"\n",$4,$5,"\n",$6,"\n",$7}' |tr -d ] | sed -e 's/^[ \t]*//' | sed '/^$/d' | sort`
#test "$GPODC" == "LDAP://CN={6AC1786C-016F-11D2-945F-00C04fB984F9},CN=Policies,CN=System,$DEFAULTNAMINGCONTEXT;0 "
#    if [ "$?" -eq "0" ]; then
#        log "    ${GREEN}GOOD${NC}\n"
#    else
#        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
#        ERROR_GPO=("${ERROR_GPO[@]}" "$C")
#        log "    ${RED}ERROR: There gPLink attribute is incorrect onou=Domain controllers,$DEFAULTNAMINGCONTEXT${NC}"
#        log "    The gPLink attribute should return a value similiar to this:"
#        log "    [LDAP://CN={6AC1786C-016F-11D2-945F-00C04fB984F9},CN=Policies,CN=System,$DEFAULTNAMINGCONTEXT;0]"
#        log "    The GPO assigned is:"
#        cat $GPOLINKED 
#        cat $GPOLINKED >> $LOG
#        log "    Please use iManager and add [LDAP://CN={6AC1786C-016F-11D2-945F-00C04fB984F9},CN=Policies,CN=System,$DEFAULTNAMINGCONTEXT;0]\n"
#    fi
#shopt -u nocasematch
# END Validate Domain has GPO linked valid


# Validate sysvol acls
((C++))
    #check if SLES 11 or higher.  SLES 10 does not support -p 
    log "$C) Validate ${BOLD}Sysvol ACLs${NC}"
    if [ "$adminSID" != "" ]; then #wbinfo returned administrator sid
        if [[ `cat /etc/SuSE-release |grep VERSION |awk '{print $3}'` = "11" ]]; then #check if SLES 11 or higher.  SLES 10 does not support -p and 11.2 added group:group\040policy\040creator\040owners:rwx
            if [[ `cat /etc/novell-release |grep VERSION |awk '{print $3}'` > "11.1" ]]; then #check if SLES 11 or higher.  SLES 10 does not support -p and 11.2 added group:group\040policy\040creator\040owners:rwx
                /usr/bin/getfacl -p /var/opt/novell/xad/sysvol | tee /tmp/sysvol_acl.txt > /dev/null
                cat > /tmp/sysvol_default.txt << 'EOL'
# file: /var/opt/novell/xad/sysvol
# owner: administrator
# group: domain\040admins
user::rwx
group::r-x
group:domain\040admins:rwx
group:domain\040users:r-x
group:domain\040computers:r-x
group:group\040policy\040creator\040owners:rwx
mask::rwx
other::---
default:user::rwx
default:group::r-x
default:group:domain\040admins:rwx
default:group:domain\040users:r-x
default:group:domain\040computers:r-x
default:group:group\040policy\040creator\040owners:rwx
default:mask::rwx
default:other::---

EOL
            else #[[ `cat /etc/novell-release |grep VERSION |awk '{print $3}'` > "10" ]]; then #check if SLES 11 or higher.  SLES 10 does not support -p 
                /usr/bin/getfacl -p /var/opt/novell/xad/sysvol | tee /tmp/sysvol_acl.txt > /dev/null
                cat > /tmp/sysvol_default.txt << 'EOL'
# file: /var/opt/novell/xad/sysvol
# owner: administrator
# group: domain\040admins
user::rwx
group::r-x
group:domain\040admins:rwx
group:domain\040users:r-x
group:domain\040computers:r-x
mask::rwx
other::---
default:user::rwx
default:group::r-x
default:group:domain\040admins:rwx
default:group:domain\040users:r-x
default:group:domain\040computers:r-x
default:group:group\040policy\040creator\040owners:rwx
default:mask::rwx
default:other::---

EOL
            fi #END SLES 11 getting sysvol ACLs
        else #SLES 10 does not support -p, last resort is SLES 10
        /usr/bin/getfacl  /var/opt/novell/xad/sysvol | tee /tmp/sysvol_acl.txt > /dev/null
        cat > /tmp/sysvol_default.txt << 'EOL'
# file: var/opt/novell/xad/sysvol
# owner: administrator
# group: domain\040admins
user::rwx
group::r-x
group:domain\040admins:rwx
group:domain\040users:r-x
group:domain\040computers:r-x
mask::rwx
other::---
default:user::rwx
default:group::r-x
default:group:domain\040admins:rwx
default:group:domain\040users:r-x
default:group:domain\040computers:r-x
default:group:group\040policy\040creator\040owners:rwx
default:mask::rwx
default:other::---

EOL
    fi
    # END getting the ACLs - 

    diff /tmp/sysvol_acl.txt /tmp/sysvol_default.txt #> /dev/null
    if [ $? -eq "0" ]; then
        log "    ${GREEN}GOOD${NC}\n"
    # Clean up
        rm /tmp/sysvol_acl.txt
        rm /tmp/sysvol_default.txt
    else
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_SYSVOL=("${ERROR_SYSVOL[@]}" "$C")
        log "    ${RED}ERROR: sysvol permissions are incorrect ${NC}"
        # if script does not exist then download
        if [ ! -f ~/bin/delete_ObjectSid_User.sh ]; then
            if [ $UPDATE = "YES" ]; then
                wget -q -T 5 -P ~/bin/ http://www.dsfwdude.com/downloads/fix_sysvol_acls.sh
               chmod +x ~/bin/fix_sysvol_acls.sh
            fi
        fi
        log "    Run fix_sysvol_acls.sh to set the proper ACLs on sysvol."
        log "    Run ${BOLD}vimdiff /tmp/sysvol_acl.txt /tmp/sysvol_default.txt${NC} to find differences between the files."
        log "    See ${BCYAN}TID 7009748${NC} on now to set the correct acls for sysvol.\n"
    fi
else
        log "    ${yellow}WARNING: Since wbinfo failed, skipped ACL check${NC}\n"
        ((NUMBER_WARNINGS++))
        ERROR_WARNINGS=("${ERROR_NUMBER[@]}" "$C")
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
fi
    # END checking the sysvol ACLs and comparing

if [ $CRON_SETTING -eq 0 ]; then
((C++))
    log "$C) Display the Partition List ${BOLD}/opt/novell/xad/sbin/domaincntrl --list${NC}"
    TMP_FILE=`mktemp`
    trap 'rm $TMP_FILE; ' EXIT
    /opt/novell/xad/sbin/domaincntrl --list > $TMP_FILE
    if [ $? -eq "0" ]; then
        grep -v '^$\|\t' $TMP_FILE | sed -e 's/^[[:space:]]*//g' | sed -e 's/^/    /' |tee -a $LOG
        log "    ${GREEN}GOOD${NC}\n"
    else
        WARNING_NUMBER=("${WARNING_NUMBER[@]}" "$C")
        ERROR_DOMAINCNTRL=("${ERROR_DOMAINCNTRL[@]}" "$C")
        log "    Command not successful"
        log "    Please issue a new kerberos ticket and run domaincntrl --list again\n"
    fi
    rm $TMP_FILE
fi

# Validate Partition list
((C++))
    log "$C) Validate the ${BOLD}Partition List${NC} (Partition in the Domain Boundary)"
    PARTITIONS_IN_DOMAIN=`mktemp`
    REMOVE_PARTITIONS_LDIF=`mktemp`
    TIMELIMIT=20
    /usr/bin/ldapsearch -Y EXTERNAL -b "cn=Partitions,cn=Configuration,$DEFAULTNAMINGCONTEXT" -s one domainpartitionlist -LLL -Q |grep domainpartitionlist: |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' |cut -d: -f2 > $PARTITIONS_IN_DOMAIN
 
    base=$(/usr/bin/ldapsearch -Y EXTERNAL -b cn=Partitions,cn=Configuration,$DEFAULTNAMINGCONTEXT domainpartitionlist=* -LLL -Q dn |cut -d: -f2)
    #list=( `cat $PARTITIONS_IN_DOMAIN` )
    # change context from all in line to carage return
    ctr0=0;while read i ; do echo $i;list[$ctr0]="${i}"; let ctr0=ctr0+1; done < ${PARTITIONS_IN_DOMAIN} > /dev/null

    # Array to check the partitions 
    # define array as new line
    for i in `seq 0 "${#list[@]}"`; do svr="${list[$i]}"; if [[ -n ${svr} ]]; then currentContext="${svr}"; else break; fi;
    #for currentContext in "${list[@]}"; do
    log "    $currentContext"
    sleep .1
    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$currentContext" -s base '(&(objectclass=partition))' dn|cut -d: -f2 |grep -v ^$ |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' >/dev/null
    if [ $? -eq "1" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_DOMAINCNTRL=("${ERROR_DOMAINCNTRL[@]}" "$C")
        log "    ${RED}ERROR: A container is no longer a partition${NC}"
        echo -ne "    Do you want to remove $currentContext from the list of partitions in the domain? (y/N): " #yes not to continue

        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]; then   # if REPLY is null then exit
            log "    Timeout, $currentContext not removed\n"
        elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
            log "    Removing from list"
            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$base" -s base dn |sed -e'/^dn/ a\changetype: modify\ndelete: domainpartitionlist\ndomainpartitionlist: $currentContext' > $REMOVE_PARTITIONS_LDIF
            
            ldapmodify -Y EXTERNAL -Q -f $REMOVE_PARTITIONS_LDIF
            NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
            FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
            log "    Finished removing from list\n"
        else
            log "    $currentContext is still listed in the domain"
            log "    Either add a create a partition at $currentContext"
            log "    or run domaincntrl --remove select $currentContext"
            log "    and select $currentContext to remove"
        fi
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    if [ -z $PARTITIONS_IN_DOMAIN ]; then 
        log "    ${GREEN}GOOD${NC}\n"
    fi
    done
    # Clean upa
    rm $REMOVE_PARTITIONS_LDIF

fi

# Check that partitions in domain have a passwordpolicy
((C++))
    log "$C) Validate ${BOLD}Partitions${NC} have a ${BOLD}Password Policy${NC}"
    # remove leading white space
    sed -i -e 's/^[ \t]*//g' $PARTITIONS_IN_DOMAIN > /dev/null
    ctr0=0;while read i ; do echo $i;list[$ctr0]="${i}"; let ctr0=ctr0+1; done < ${PARTITIONS_IN_DOMAIN} > /dev/null
    # Array to check the partitions
    for i in `seq 0 "${#list[@]}"`; do svr="${list[$i]}"; if [[ -n ${svr} ]]; then currentPartition="${svr}"; else break; fi;
    #for currentPartition in "${list[@]}"
    #    do
    log "    $currentPartition"
    sleep .1
    # Search for nspmPasswordPolicyDN on container and if nothing is returned, return error 1 (grep -v ^$)
    /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$currentContext" -s base '(&(nspmPasswordPolicyDN=*))' dn |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' |cut -d: -f2 |grep -v ^$ >/dev/null
    if [ $? -eq "1" ]
    then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_PASS=("${ERROR_PASS[@]}" "$C")
        log "    ${RED}ERROR: A container does not have a password policy assigned${NC}"
        echo -ne "    Do you want to assign Domain Password Policy to  $currentPartition? (y/N): " #yes not to continue
        read -t $TIMELIMIT REPLY # set timelimit on REPLY 
        if [ -z "$REPLY" ]   # if REPLY is null then exit
        then
            log "    Timeout, $currentPartition does not have a password policy"
            log "    Since `grep -i "XADRETAINPOLICIES = YES" /etc/opt/novell/xad/xad.ini`"
            if [ $? -eq "0" ]; then
                log "    Since `grep -i "XADRETAINPOLICIES = YES" /etc/opt/novell/xad/xad.ini`"
                log "    Use iManager to assign a password policy to $currentPartition\n"
            else
                log "    Use GPO Management Tool to assign a GPO to $currentPartition\n"
            fi
        elif [[ $REPLY =~ ^[Yy]$ ]] # if yes then remove
        then
            ADD_PASSWDPOLICY_LDIF=`mktemp`
            log "    Adding Domain Password Policy from list"
            /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$currentPartition" -s base dn |sed -e'/^dn/ a\changetype: modify\nadd: nspmPasswordPolicyDN\nnspmPasswordPolicyDN: cn=Domain Password Policy,cn=Password Policies,cn=System,'$DEFAULTNAMINGCONTEXT'' > $ADD_PASSWDPOLICY_LDIF

            ldapmodify -Y EXTERNAL -Q -f $ADD_PASSWDPOLICY_LDIF
            NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
            FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
            log "    Finished Adding Domain Password Policy to $currentPartition\n"
            # Clean up
            rm $ADD_PASSWDPOLICY_LDIF
        else
            log "    $currentPartition is missing a password policy assignment "
            log "    Since `grep -i "XADRETAINPOLICIES = YES" /etc/opt/novell/xad/xad.ini`"
            if [ $? -eq "0" ]; then
                log "    Use iManager to assign a password policy to $currentPartition\n"
            else
                log "    Use GPO Management Tool to assign a GPO to $currentPartition\n"
            fi
        fi
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    if [ -z $PARTITIONS_IN_DOMAIN ]; then 
        log "    ${GREEN}GOOD${NC}\n"
    fi
    done
    # Clean up
    rm $PARTITIONS_IN_DOMAIN

    # END Check that partitions in domain have a passwordpolicy


# Validate Partition list
((C++))
    log "$C) Validate ${BOLD}Containers with Computers${NC} have a ${BOLD}Password Policy${NC}"
    COMPUTER_CONTAINERS_IN_DOMAIN=`mktemp`
    ADD_PASSWDPOLICY_LDIF=`mktemp`
    /usr/bin/ldapsearch -Y EXTERNAL -b "$DEFAULTNAMINGCONTEXT" -s sub -LLL -Q '(&(objectclass=computer)(1.2.840.113556.1.4.221=*)(1.2.840.113556.1.4.782=*))' dn |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' | cut -d: -f2 | cut -d, -f2-12 | sort -u | grep -iv ^dc= |grep -v ^// > ${COMPUTER_CONTAINERS_IN_DOMAIN} 
    sed -i -e '/^$/d' $COMPUTER_CONTAINERS_IN_DOMAIN > /dev/null
    #list=( `cat $COMPUTER_CONTAINERS_IN_DOMAIN` )
    ctr0=""
    list=""
    ctr0=0;while read i ; do echo $i;list[$ctr0]="${i}"; let ctr0=ctr0+1; done < ${COMPUTER_CONTAINERS_IN_DOMAIN} > /dev/null
#    echo

   # Array to check the partitions 
    svr=""
    for i in `seq 0 "${#list[@]}"`; do svr="${list[$i]}"; if [[ -n ${svr} ]]; then currentContext="${svr}"; else break; fi;
    #for currentContext in "${list[@]}"
        log "    $currentContext"  #Display the context that will be the base in the ldapsearch
        sleep .1
        # the ldapsearch using the currentContext as the base looking for nspmPasswordPolicyDN
        /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$currentContext" -s base '(&(nspmPasswordPolicyDN=*))' dn |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' |cut -d: -f2 |grep -v ^$ >/dev/null
        if [ $? -eq "1" ]; then
            ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
            ERROR_PASS=("${ERROR_PASS[@]}" "$C")
            log "    ${RED}ERROR: A container does not have a Password Policy assigned${NC}"
            echo -ne "    Do you want to add a password policy to $currentContext (y/N): " #yes not to continue

            read -t $TIMELIMIT REPLY # set timelimit on REPLY 
            if [ -z "$REPLY" ]; then   # if REPLY is null then exit
                log "    Timeout, $currentContext has computer objects and does not have a password policy"
                log "    Computer object change their password by default every 30 days."
                log "    Not having a Password policy designed for computers will result in computer in computers attempting to change their password and their new password not conforming to the password policy assigned to the domain, usually the policy at the Domain level."
                log "    This can cause Computer object to not authenticate and GPOs to not update the computer."
                log "    Please add the cn=Default Password Policy,cn=Password Policies,cn=System,'$DEFAULTNAMINGCONTEXT'"
                log "    Use iManager to assign a password policy to $currentContext\n"
            elif [[ $REPLY =~ ^[Yy]$ ]]; then # if yes then remove
                ADD_PASSWDPOLICY_LDIF=`mktemp`
                log "    Adding Domain Password Policy from list"
                /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$currentContext" -s base dn |sed -e'/^dn/ a\changetype: modify\nadd: nspmPasswordPolicyDN\nnspmPasswordPolicyDN: cn=Default Password Policy,cn=Password Policies,cn=System,'$DEFAULTNAMINGCONTEXT'' > $ADD_PASSWDPOLICY_LDIF

               ldapmodify -Y EXTERNAL -Q -f $ADD_PASSWDPOLICY_LDIF
               NUMBER_FIXED=`expr $NUMBER_FIXED + 1`
               FIXED_NUMBER=("${FIXED_NUMBER[@]}" "$C")
               log "    Finished Adding Domain Password Policy to $currentContext\n"
            else
                log "    $currentContext has computer objects and does not have a password policy"
                log "    Computer object change their password by default every 30 days."
                log "    Not having a Password policy designed for computers will result in computer in computers attempting to change their password and their new password not conforming to the password policy assigned to the domain, usually the policy at the Domain level."
                log "    This can cause Computer object to not authenticate and GPOs to not update the computer."
                log "    Please add the cn=Default Password Policy,cn=Password Policies,cn=System,'$DEFAULTNAMINGCONTEXT'"
                log "    Use iManager to assign a password policy to $currentContext\n"
            fi
        else
            log "    ${GREEN}GOOD${NC}\n"
        fi
        done
    # Clean up
    rm $ADD_PASSWDPOLICY_LDIF
    rm $COMPUTER_CONTAINERS_IN_DOMAIN


fi # END DSfW/XAD Specific Section



if [ $REPAIR_LOCAL_DB -eq 1 ]; then
# Run Local repair
((C++))
    log "$C) Run Local Database Repair using command ${BOLD}ndsrepair -R${NC}"
    localrepair=$(ndsrepair -R | grep -i "Total errors: 0")
    if [ "$localrepair" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
	ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: Local Repair errors${NC}"
        log "    Last Error in ndsrepair.log"
        log "   $(cat /var/opt/novell/eDirectory/log/ndsrepair.log |grep ERROR: | tail -n1)${NC}"
        log "    Run ndsrepair -R again"
        log "    Look up the error(s) reported in the ndsrepair.log at http://novell.com/support\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    sleep 1
fi # END Run Local repair

if [ $DISPLAY_PARTITIONS -eq 1 ]; then
# check that the servers ip address is listed in the /etc/hosts.conf
((C++))
    log "$C) Reporting Partitions using command ${BOLD}ndsrepair -P${NC}"
    TMP_FILE_PART=`mktemp`
    trap 'rm $TMP_FILE_PART; ' EXIT
    displaypartitions > $TMP_FILE_PART
    sed -i '/Press ENTER/d' $TMP_FILE_PART
    sed -i '/^Enter/d' $TMP_FILE_PART
    partitionreport=$(grep -i "Total errors: 0" $TMP_FILE_PART)
    if [ "$partitionreport" == "" ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: checking partitions${NC}"
        log "    $(cat /var/opt/novell/eDirectory/log/ndsrepair.log |grep Total errors: | tail -n1)${NC}"
        log "    Check the ndsrepair -P for errors"
        log "    Look up the error(s) reported in the ndsrepair.log at http://novell.com/support\n"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
        grep -A100 "^Total number of replicas*" $TMP_FILE_PART |tee -a $LOG
        # Clean up
        rm $TMP_FILE_PART
        log
fi # END Display Partitions

[ $DISPLAY_UNKNOWN_OBJECTS -eq 1 ] && [ $ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS -eq 1 ]
if [ $DISPLAY_UNKNOWN_OBJECTS -eq 1 ]; then
# check that the servers ip address is listed in the /etc/hosts.conf
((C++))
    log "$C) Root DSE Search for unknown objects${BOLD}${NC}"
    TMP_FILE_UNKNOWN=`mktemp`
    trap 'rm $TMP_FILE_UNKNOWN; ' EXIT
    if [ $XADINST -eq 1 ]; then
        /usr/bin/ldapsearch -Y EXTERNAL -LLL -Q -b "$DEFAULTNAMINGCONTEXT" -s sub "(&(objectclass=unknown))" dn |grep -v '^#' |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' |grep -v '^$'> $TMP_FILE_UNKNOWN 
    elif [ $ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS -eq 1 ] && [ $XADINST -eq 0 ]; then
        /usr/bin/ldapsearch -x -LLL -H ldaps://`getip` -b "$BASE" -s sub '(&(objectclass=unknown))' dn |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' > $TMP_FILE_UNKNOWN
    else
        /usr/bin/ldapsearch -x -LLL -H ldaps://`getip` -D $ADMUSER -w $ADMPASSWD -b "$BASE" -s sub '(&(objectclass=unknown))' dn |sed -e :a -e '$!N;s/\n //;ta' -e 'P;D' > $TMP_FILE_UNKNOWN
    fi
    if [  -s $TMP_FILE_UNKNOWN ]; then
        ERROR_NUMBER=("${ERROR_NUMBER[@]}" "$C")
        ERROR_NDS=("${ERROR_NDS[@]}" "$C")
        log "    ${RED}ERROR: Unknown objects reported${NC}"
        log "    List of Unknown Objects${NC}"
        log "    $(cat $TMP_FILE_UNKNOWN)"
    else
        log "    ${GREEN}GOOD${NC}\n"
    fi
    # Clean up
    #rm $TMP_FILE_UNKNOWN
    log
fi
fi # END $BACKUP_NDSD -eq 0 

# BACKUP SECTION
 if [ $BACKUP_NDSD -eq 1 ] && [ $BACKUP_NDS_NDSBACKUP -eq 1 ]; then
# Backup eDirectory ndsbackup
((C++))
    log "$C)  Begin to backup eDirectory using ${BOLD}ndsbackup cvf /var/opt/novell/eDirectory/backup/`date -I`_ndsbackup.bak${NC}"
    # Make backup directory
    if [ -d $BACKUP_DIR_NDSD ]; then
        &> /dev/null
    else
        /bin/mkdir -p $BACKUP_DIR_NDSD
    fi
    # Run ndsbackup - first check that a passstore file has been created
    ndstrace -u > /dev/null 2>&1
    if [ -a /var/opt/novell/nici/0/edirsec.cfg ]; then
        /opt/novell/eDirectory/bin/ndsbackup cvf /var/opt/novell/eDirectory/backup/`date -I`_ndsbackup.bak -a $ADMNUSER -p passstore
        # Remove old backups
        log "Deleting backups older than $BACKUP_KEPT days"
        find $BACKUP_DIR_NDSD/*ndsbackup.bak -mtime +$BACKUP_KEPT >> /tmp/ndsback_del
        bklist=( `cat /tmp/ndsback_del` )
        for i in "${bklist[@]}"
            do
                log "    $i"
                # Clean up
                rm ${i}
             done
        if [ ! -s /tmp/ndsback_del ]; then echo "No backups older than $BACKUP_KEPT days found"; fi
        rm /tmp/ndsback_del
    else
        log ""
        log "$ADMNUSER user's password has not been stored in ndspassstore"
        log "Please enter ${BOLD}$ADMNUSER${NC} and the password at the prompt"
        log "If${BOLD} $ADMNUSER ${NC}is not the admin user, please edit the ${BOLD}ADMNUSER=${NC}"
        log "In the ${BOLD}Backup dib and nici${NC} of the configuration section at the top of this script"
        log ""
        /opt/novell/eDirectory/bin/ndspassstore
        log "The credentials are set, run${BOLD} $(basename $0) bk_ndsbackup${NC} to perform the backup"
        log "Correct the ADMNUSER=$ADMNUSER if necessary"
        exit 0
    fi
    echo
 fi # END Backup eDirectory ndsbackup

 if [ $BACKUP_NDSD -eq 1 ] && [ $BACKUP_NDS_DSBK -eq 1 ]; then
# Backup eDirectory dsbk
DSBK_LOG=$BACKUP_DIR_NDSD/`date -I`_dsbk-restore.log
((C++))
    log "$C)  Begin to backup eDirectory using ${BOLD}dsbk backup -b -f $BACKUP_DIR_NDSD/`date -I`_dsbk.bak -l $DSBK_LOG -e $NICIPASSWD -t -w${NC}"
    # Make backup directory
    if [ -d $BACKUP_DIR_NDSD ]; then
        &> /dev/null
    else
        /bin/mkdir -p $BACKUP_DIR_NDSD
    fi

    # Make dsbk.conf file if does not exist
    if [ -e /etc/dsbk.conf ]; then
        echo "dsbk.conf is located in /etc... "
    else
        echo "Creating dsbk.conf file..."
        touch /tmp/dsbk.tmp
        echo "/tmp/dsbk.tmp" > /etc/dsbk.conf
        # Clean up
        rm /tmp/dsbk.tmp
        /opt/novell/eDirectory/bin/dsbk setconfig -L -T #>1 /dev/null
    fi
    /opt/novell/eDirectory/bin/dsbk getconfig #>1 /dev/null
    sleep 1

# run dsbk
    DSBK_LOG=$BACKUP_DIR_NDSD/`date -I`_dsbk-restore.log
        /opt/novell/eDirectory/bin/dsbk backup -b -f $BACKUP_DIR_NDSD/`date -I`_dsbk.bak -l $DSBK_LOG -e novell -t -w 
        sleep 3
        echo "Viewing end of ndsd.log"
        echo 
        tail 22 $NDSD_LOG
        echo

        # Remove old backups
        log "Deleting backups older than $BACKUP_KEPT days"
        find $BACKUP_DIR_NDSD/*dsbk* -mtime +$BACKUP_KEPT >> /tmp/dsbk_del
        bklist=( `cat /tmp/dsbk_del` )
        for i in "${bklist[@]}"
            do
                log "    $i"
                # Clean up
                rm ${i}
            done
        if [ ! -s /tmp/dsbk_del ]; then echo "No backups older than $BACKUP_KEPT days found"; fi
        rm /tmp/dsbk_del
 
     fi # END Backup eDirectory dsbk


 if [ $BACKUP_NDSD -eq 1 ] && [ $BACKUP_NDS_DIB -eq 1 ]; then
# Backup eDirectory copying dib
((C++))
    log "$C)  Begin to backup eDirectory by ${BOLD}copying dib${NC}"
    dibBk
 fi # END Backup eDirectory copying dib


#if test $BACKUP_NDSD -eq 0; then ndstrace -u > /dev/null 2>&1; fi
#rm $TMP_FILE_TRACE
if test $BACKUP_NDSD -eq 0; then ndstrace -u > /dev/null 2>&1; fi
if test "${#ERROR_NUMBER[@]}" == "0"; then log "Total number of errors: ${BOLD}${#ERROR_NUMBER[@]}${NC}"; fi
if test "${#WARNING_NUMBER[@]}" != "0"; then log "Total number of warnings: ${yellow}${#WARNING_NUMBER[@]}${NC}"; fi
if test "${#WARNING_NUMBER[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#WARNING_NUMBER[@]}" != "0"; then log "Warnings reported on $TASKS: ${yellow}${WARNING_NUMBER[@]}${NC}"; fi
if test "${#ERROR_NUMBER[@]}" != "0"; then log "Total number of errors: ${RED}${#ERROR_NUMBER[@]}${NC}"; fi
if test "${#ERROR_NUMBER[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_NUMBER[@]}" != "0"; then log "Errors reported on $TASKS: ${RED}${ERROR_NUMBER[@]}${NC}"; fi
if test "${#FIXED_NUMBER[@]}" != "0"; then log "Total number of errors fixed: ${GREEN}${#FIXED_NUMBER[@]}${NC}"; fi
if test "${#FIXED_NUMBER[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#FIXED_NUMBER[@]}" != "0"; then log "Fixes reported on $TASKS: ${GREEN}${FIXED_NUMBER[@]}${NC}"; fi
log "---------------------------------------------------------------------------"
if test "${#ERROR_NDS[@]}" != "0"; then log "Total number of NDS errors: ${yellow}${#ERROR_NDS[@]}${NC}"; fi
if test "${#ERROR_NDS[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_NDS[@]}" != "0"; then log "NDS Errors reported on $TASKS: ${yellow}${ERROR_NDS[@]}${NC}"; fi
if test "${#ERROR_XAD[@]}" != "0"; then log "Total number of XAD errors: ${yellow}${#ERROR_XAD[@]}${NC}"; fi
if test "${#ERROR_XAD[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_XAD[@]}" != "0"; then log "XAD Errors reported on $TASKS: ${yellow}${ERROR_XAD[@]}${NC}"; fi
if test "${#ERROR_KDC[@]}" != "0"; then log "Total number of KDC errors: ${yellow}${#ERROR_KDC[@]}${NC}"; fi
if test "${#ERROR_KDC[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_KDC[@]}" != "0"; then log "KDC Errors reported on $TASKS: ${yellow}${ERROR_KDC[@]}${NC}"; fi
if test "${#ERROR_SMB[@]}" != "0"; then log "Total number of SMB errors: ${yellow}${#ERROR_SMB[@]}${NC}"; fi
if test "${#ERROR_SMB[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_SMB[@]}" != "0"; then log "SMB Errors reported on $TASKS: ${yellow}${ERROR_SMB[@]}${NC}"; fi
if test "${#ERROR_SYSVOL[@]}" != "0"; then log "Total number of SYSVOL errors: ${yellow}${#ERROR_SYSVOL[@]}${NC}"; fi
if test "${#ERROR_SYSVOL[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_SYSVOL[@]}" != "0"; then log "SYSVOL Errors reported on $TASKS: ${yellow}${ERROR_SYSVOL[@]}${NC}"; fi
if test "${#ERROR_GPO[@]}" != "0"; then log "Total number of GPO errors: ${yellow}${#ERROR_GPO[@]}${NC}"; fi
if test "${#ERROR_GPO[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_GPO[@]}" != "0"; then log "GPO Errors reported on $TASKS: ${yellow}${ERROR_GPO[@]}${NC}"; fi
if test "${#ERROR_DOMAINCNTRL[@]}" != "0"; then log "Total number of domaincntrl errors: ${yellow}${#ERROR_DOMAINCNTRL[@]}${NC}"; fi
if test "${#ERROR_DOMAINCNTRL[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_DOMAINCNTRL[@]}" != "0"; then log "domaincntrl Total number of errors: ${yellow}${#ERROR_DOMAINCNTRL[@]}${NC}"; fi
if test "${#ERROR_PASS[@]}" != "0"; then log "Total number of Password Policy errors: ${yellow}${#ERROR_PASS[@]}${NC}"; fi
if test "${#ERROR_PASS[@]}" -gt "1"; then TASKS=tasks; else TASKS=task; fi
if test "${#ERROR_PASS[@]}" != "0"; then log "Password Policy Errors reported on $TASKS: ${yellow}${ERROR_PASS[@]}${NC}"; fi
if test "${#ERROR_NUMBER[@]}" -gt "0"; then
log "---------------------------------------------------------------------------"
fi

echo Log file is: $LOG
log "End of script: $(basename $0)"
log "---------------------------------------------------------------------------"
}

# Gather DSfW logs
dsfwLogs(){

if [ -f /etc/init.d/xadsd ]; then 
    if [ ! -d /tmp/dsfw-logs-`date -I` ]; then
        mkdir /tmp/dsfw-logs-`date -I`
    fi
    domainname=`dnsdomainname`
    servername=`hostname`

    cd /tmp/dsfw-logs-`date -I`
    [ /etc/opt/novell/xad ] && cp -r /etc/opt/novell/xad etc-opt-novell-xad
    [ /etc/opt/novell/eDirectory  ] &&  cp -r /etc/opt/novell/eDirectory etc-opt-novell-eDirectory
    [ /etc/opt/novell/ncp ] &&  cp -r /etc/opt/novell/ncp etc-opt-novell-ncp
    [ /etc/opt/novell/named ] &&  cp -r /etc/opt/novell/named etc-opt-novell-named
    [ /etc/samba ] &&  cp -r /etc/samba etc-samba
    [ /etc/sysconfig/novell ] &&  cp -r /etc/sysconfig/novell/ etc-sysconfig-novell
    [ /opt/novell/oes-install ] && cp -r /opt/novell/oes-install opt-novell-oesinstall
    [ /var/log/samba ] && rsync -a --delete --exclude="*.bz2" /var/log/samba/ var-log-samba
    [ /var/opt/novell/xad/log ] && rsync -a --delete --exclude="*.bz2" /var/opt/novell/xad/log/ var-opt-novell-xad-log
    [ /var/opt/novell/eDirectory/log ] && rsync -a --delete --exclude="*.bz2" /var/opt/novell/eDirectory/log/ var-opt-novell-eDirectory-log
    [ /var/opt/novell/log ] && rsync -a --delete --exclude="*.bz2" /var/opt/novell/log/ var-opt-novell-log
    [ /etc/krb5.conf ] && cp /etc/krb5.conf etc-krb5.conf
    [ /etc/opt/novell/ncpserv.conf ] && cp /etc/opt/novell/ncpserv.conf etc-opt-novell-ncpserv.conf
    [ /etc/opt/novell/nici64.cfg ] && cp /etc/opt/novell/nici64.cfg etc-opt-novell-nici64.cfg
    [ /var/log/messages ] && cp /var/log/messages var-log-messages
    [ /var/log/slpd.log ] && cp /var/log/slpd.log var-log-slpd.log
    [ /var/log/YaST2/y2log ] && cp /var/log/YaST2/y2log y2log
    [ /etc/hosts ] && cp /etc/hosts hosts
    [ /etc/resolv.conf ] && cp /etc/resolv.conf resolv.conf
    [ /etc/opt/novell/xad/xad.ini ] && cp /etc/opt/novell/xad/xad.ini xad.ini
    [ /etc/openldap/ldap.conf ] && cp /etc/openldap/ldap.conf etc-openldap-ldap.conf
    if [ -f /tmp/dsfw-logs-`date -I` ]; then
        rm /tmp/dsfw-logs-`date -I`
    else
        tar -czvf /tmp/$servername-$domainname-logs-`date -I`.tgz /tmp/dsfw-logs-`date -I` 2>&1 | grep -v "Removing leading"
    fi

    echo
    echo "DSfW Logs tarball can be found at: /tmp/$servername-$domainname-logs-`date -I`.tgz"
#    rm -r /tmp/dsfw-logs-`date -I`

else

    if [ -f /etc/novell-release ]; then
    if [ ! -d /tmp/edir-logs-`date -I` ]; then
        mkdir /tmp/edir-logs-`date -I`
    fi
    domainname=`dnsdomainname`
    servername=`hostname`

    cd /tmp/edir-logs-`date -I`
    [ /etc/opt/novell/eDirectory  ] &&  cp -r /etc/opt/novell/eDirectory etc-opt-novell-eDirectory
    [ /etc/opt/novell/ncp ] &&  cp -r /etc/opt/novell/ncp etc-opt-novell-ncp
    [ /etc/sysconfig/novell ] &&  cp -r /etc/sysconfig/novell/ etc-sysconfig-novell
    [ /opt/novell/oes-install ] && rsync -a --delete --exclude="*.bz2" /opt/novell/oes-install opt-novell-oesinstall
    [ /var/opt/novell/eDirectory/log ] && rsync -a --delete --exclude="*.bz2" /var/opt/novell/eDirectory/log/ var-opt-novell-eDirectory-log
    [ /var/opt/novell/log ] && rsync -a --delete --exclude="*.bz2" /var/opt/novell/log/ var-opt-novell-log
    [ /etc/opt/novell/ncpserv.conf ] && cp /etc/opt/novell/ncpserv.conf etc-opt-novell-ncpserv.conf
    [ /etc/opt/novell/nici64.cfg ] && cp /etc/opt/novell/nici64.cfg etc-opt-novell-nici64.cfg
    [ /var/log/messages ] && cp /var/log/messages var-log-messages
    [ /var/log/slpd.log ] && cp /var/log/slpd.log var-log-slpd.log
    [ /var/log/YaST2/y2log ] && cp /var/log/YaST2/y2log y2log
    [ /etc/hosts ] && cp /etc/hosts hosts
    [ /etc/resolv.conf ] && cp /etc/resolv.conf resolv.conf
    [ /etc/openldap/ldap.conf ] && cp /etc/openldap/ldap.conf etc-openldap-ldap.conf
    if [ -f /tmp/dsfw-logs-`date -I` ]; then
        rm /tmp/dsfw-logs-`date -I`
    else
        tar -czvf /tmp/$servername-$domainname-logs-`date -I`.tgz /tmp/edir-logs-`date -I` 2>&1 | grep -v "Removing leading"
    fi
        echo
        echo "DSfW Logs tarball can be found at: /tmp/$servername-$domainname-logs-`date -I`.tgz"
#	rm -r /tmp/edir-logs-`date -I`
    else
        echo "Only works for OES Installs at this time"
    fi

fi
}

# Main - The main section of the script, this is what the script will do
main(){
#    getAdministratorCasa
    if [ ${AUTO_UPDATE} -eq 1 ]; then
        autoUpdate
    fi
    dsfwCredentials
    setLogsToGather	
    [ $EMAIL_ON_ERROR -eq 1 ] && RESET_LOG=1
    [ $RESET_LOG -eq 1 ] && echo > $LOG
    [ $DISPLAY_UNKNOWN_OBJECTS -eq 1 ] && [ $ANONYMOUS_DISPLAY_UNKNOWN_OBJECTS -eq 0 ] && dscredentials
    serverInfo
    healthCheck
    #send messamge to syslog that health check completed if set to 1
    [ $LOGTOSYSLOG -eq 1  ] && $LOGGER "ndsd dsfw health check complete $(basename $0)"
    #send email if set to 1
    [ $EMAIL_SETTING -eq 1 ] && sendEmail
    #send email if ERROR: is found in log and emilaonerror set to 1
    if [ -n "$(grep "ERROR: " $LOG)" ] && [ $EMAIL_SETTING -eq 0 ]; then [ $EMAIL_ON_ERROR -eq 1 ] && sendEmail; fi
    # check for dib backup
    if [ $CHECK_NDS_DIB = 1 ]; then
        find $BACKUP_DIR_NDSD/*_dib.tgz -mtime -$BACKUP_KEPT > /tmp/bkdib_list 2>/dev/null
        if [ ! -s "/tmp/bkdib_list" ]; then
            log "${yellow}WARNING NO BACKUP OF DIB FILES LOCATED"
            log "${RED}It is important to have eDirectory backups"
            log "It appears there are no backups of the dib${NC}"
            if [ $XADINST -eq 1 ]; then 
                log "\n${yellow}WARNING THIS IS A DSfW SERVER"
                log "${RED}If eDirectory is removed or corrupted on a DSfW server"
                log "DSfW will have to be re-installed"
                log "If this is the only DSfW server then the domain will be lost"
                log "All workstations will have to be rejoined to the domain"
                log "All Users SIDs will be modified and passwords will have to be reset"
                log "It is EXTREMELY IMPORTANT to have DIB backups on a DSfW server${NC}"
            fi
            log "---------------------------------------------------------------------------"
            dibBk
        fi
        rm /tmp/bkdib_list
    fi
    rm 0
}

#######################################################################################
# Script Options
#while getopts "add:c:ndsd:addr:scma:repair:all:-h:h:help:--help" optname; do

    case "$1" in
        -ac | add)
        addToCron
        ;;
        -ab | add_bk)
        addToCronBk
        ;;
        -a | all)
        REPAIR_NETWORK_ADDR=1
        SCHEMA_SYNC=1
        DISPLAY_FSMO=1
        REPAIR_LOCAL_DB=1
        DISPLAY_PARTITIONS=1
        DISPLAY_UNKNOWN_OBJECTS=1
        ;;
        -na | na | cron)
        CRON_SETTING=1
        ;;
        na_all)
        CRON_SETTING=1
        REPAIR_NETWORK_ADDR=1
        SCHEMA_SYNC=1
        DISPLAY_FSMO=1
        REPAIR_LOCAL_DB=1
        DISPLAY_PARTITIONS=1
        DISPLAY_UNKNOWN_OBJECTS=1
        ;;
        -n | ndsd)
        XADINST=0
        ;;
        addr)
        REPAIR_NETWORK_ADDR=1
        ;;
        scma)
        SCHEMA_SYNC=1
        ;;
        repair)
        REPAIR_LOCAL_DB=1
        ;;
        -b)
        backupScript
        exit 0
        ;; 
        -d | -D)
        sed -i "s/^CHECK_NDS_DIB=1/CHECK_NDS_DIB=0/g" ${THIS_FILE}
        echo -e "\nCheck for DIB backup ${RED}disabled${NC}\n"
        exit
        ;;
        -e | -E)
        sed -i "s/^CHECK_NDS_DIB=0/CHECK_NDS_DIB=1/g" ${THIS_FILE}
        echo -e "\nCheck for DIB backup ${GREEN}enabled${NC}\n"
        exit
        ;;
        -s)
        setAdministratorCasa
        ADM_CASA=1
        ;;
        -bk | bk_dib | --bk_dib)
        BACKUP_NDSD=1
        BACKUP_NDS_DIB=1
        BACKUP_NDS_DSBK=0
        BACKUP_NDS_NDSBACKUP=0
        ;;
        -bd | bk_dsbk | --bk_dsbk)
        BACKUP_NDSD=1
        BACKUP_NDS_DIB=0
        BACKUP_NDS_DSBK=1
        BACKUP_NDS_NDSBACKUP=0
        ;;
        -bn | bk_nds | --bk_nds)
        BACKUP_NDSD=1
        BACKUP_NDS_DIB=0
        BACKUP_NDS_DSBK=0
        BACKUP_NDS_NDSBACKUP=1
        ;;
        -ba | bk_all | --bk_all)
        BACKUP_NDSD=1
        BACKUP_NDS_DIB=1
        BACKUP_NDS_DSBK=1
        BACKUP_NDS_NDSBACKUP=1
        ;;
        up | -up | --up | --update)
        backupScript
        getUpdate
        copySettings
        #executeUpdate
        replaceCurrentFileWithUpdate
        exit 0
        ;;
        logs | -logs | --logs)
        dsfwLogs
        exit 0
        ;;
        l | -l | list | -list | --list)
        listOptions
        RES=$?
        exit $RES        
        ;;
        -h | h | --help | help)
        echo -e "Usage: $(basename $0) {add|add_bk|na|ndsd|all|bk_all|bk_dib|bk_dsbk|bk_nds|up} "
        echo
        echo -e "   Healtcheck Options"
        echo -e "          all    runs all options except backup options"
        echo -e "         ndsd    runs only eDirectory specific checks"
        echo -e "           na    runs script with out requiring authentication"
        echo -e "       na_all    runs script with no authentication and all options that do not require auth"
        echo -e "       no auth is for DSfW Servers, not required for eDir server"
        echo
        echo -e "    Backup Options"
        echo -e "       bk_all    backup using all backup options"
        echo -e "       bk_dib    backup eDirectory files"
        echo -e "       bk_nds    backup eDirectory using ndsbackup"
        echo -e "      bk_dsbk    backup eDirectory using dsbk"
        echo -e "                 note: rollforward logs are disabled"
        echo
        echo -e "    Restore Options"
        echo -e "           -r    restore eDirectory using dsbk"
        echo -e "                 note: rollforward logs are disabled"
        echo
        echo -e "    Cron Job Options"
        echo -e "          add    adds ${ADD_JOB} to crontab "
        echo -e "       add_bk    adds ${ADD_BACKUP_JOB} to crontab "
        echo
        echo -e "    Gather Logs"
        echo -e "          logs   gathers dsfw logs into a tarball"
        echo
        echo -e "    Update Script"
        echo -e "           up    update to the latest health check script"
        echo
        RES=$?
        exit $RES
        ;;
        -n|-N|n|N)
        addBackupJob
        listOptions
        RES=$?
        exit $RES;;
        -r|-R|r|R|restore|--restore)
        restoredsbk
        ;;

        *)
        ;;
    esac
#done
#######################################################################################
#                                MAIN 
#######################################################################################
# Main - run the main function
main

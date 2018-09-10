#!/bin/bash
HOSTNAME=`hostname 2> /dev/null`
SCRIPT_VER=1.9
DATETIME=$(date +"%Y-%m-%d %H:%M:%S")

CONFIG_FILE=SERVICE.cfg
#SERVICENAME="for hardcoding service name"
if [ -f $CONFIG_FILE ]
then 
	read SERVICENAME < $CONFIG_FILE
	if [ "$SERVICENAME" = "service_name" ]
	then
		echo "ERROR: service name is not configured... please configure service name on $CONFIG_FILE"
		exit
	fi
else
	echo "ERROR: no CONFIG file... please configure service name on CONFIG file"
	exit
fi

#OS_DETECTION
. ./osdetection
OS_TYPE="${OS}"
OS_VERSION="$OS_FULLNAME"

#OS_VERSION="Amazon Linux AMI release 2014.09"

USER_START="1000"
if [[ "$OS_VERSION" == *"Amazon"* ]]; then
    USER_START="500"
fi

IPV4_ADDRESS="none"
FIND=`ifconfig -a | awk '{ if ($1=="inet") print $2 }' | cut -d ':' -f2`
for I in ${FIND}; do
if [ "$IPV4_ADDRESS" = "none" ]; then
    IPV4_ADDRESS="${I}"
else
    break
fi
done

MAC_ADDRESS="none"
#general linux
FIND=`ifconfig -a | grep "HWaddr" | awk '{ if ($4=="HWaddr") print $5 }' | sort | uniq`
for I in ${FIND}; do
if [ "$MAC_ADDRESS" = "none" ] && [ "${I}" != "00:00:00:00:00:00" ]; then
    MAC_ADDRESS="${I}"
fi
done
#some centOS case
FIND=`ifconfig -a | grep "ether" |awk '{ if ($1=="ether") print $2 }' | sort | uniq`
for I in ${FIND}; do
if [ "$MAC_ADDRESS" = "none" ] && [ "${I}" != "00:00:00:00:00:00" ]; then
    MAC_ADDRESS="${I}"
fi
done

#IPV6_ADDRESS=`ifconfig -a | awk '{ if ($1=="inet6" && $2=="addr:") { print $3 } else { if ($1=="inet6" && $3=="prefixlen") { print $2 } } }'`

REPORTTIME=$(date +"%Y%m%d-%H%M%S%3N")
ELK_RAW_FILE="$REPORTTIME"_ELK_"$SERVICENAME"_`hostname`_"$IPV4_ADDRESS".csv
REPORT_FILE="$REPORTTIME"_REPORT_"$SERVICENAME"_`hostname`_"$IPV4_ADDRESS".txt
OK="pass"
FAIL="fail"

DEBUG="false"
DEBUG_OUT_FILE="$REPORTTIME"_DEBUG_"$SERVICENAME"_`hostname`_"$IPV4_ADDRESS".txt


echo "##############################################################" 
echo "##########         Linux Hardening Checker $SCRIPT_VER      ##########" 
echo "##########                VD Security               ##########" 
echo "##############################################################"
echo "@ Start time : $DATETIME"
echo "@ Service name : $SERVICENAME"
echo "@ Host name : $HOSTNAME"
echo "@ IPv4 Address : $IPV4_ADDRESS"

init()
{
	OK_CNT=0
	FAIL_CNT=0
	AUTHN_OK_CNT=0
	AUTHN_FAIL_CNT=0
	AUTHZ_OK_CNT=0
	AUTHZ_FAIL_CNT=0
	SERVICE_OK_CNT=0
	SERVICE_FAIL_CNT=0
	LOG_OK_CNT=0
	LOG_FAIL_CNT=0
	FAIL_CODES=""
	echo "init ... done"
}
init

count()
{
	if [ "$RESULT" = "$OK" ]
	then
		OK_CNT=$(expr $OK_CNT + 1)
	else
		FAIL_CNT=$(expr $FAIL_CNT + 1)
		NEW_LINE="$3, $4"
    FAIL_CODES="$FAIL_CODES$NEW_LINE\n"
	fi

	if [ "$1" = "AUTHN" ]
	then
		if [ "$2" = "$OK" ]
		then
			AUTHN_OK_CNT=$(expr $AUTHN_OK_CNT + 1)
		else
			AUTHN_FAIL_CNT=$(expr $AUTHN_FAIL_CNT + 1)
		fi
	elif [ "$1" = "AUTHZ" ]
	then
		if [ "$2" = "$OK" ]
		then
			AUTHZ_OK_CNT=$(expr $AUTHZ_OK_CNT + 1)
		else
			AUTHZ_FAIL_CNT=$(expr $AUTHZ_FAIL_CNT + 1)
		fi
	elif [ "$1" = "SERVICE" ]
	then
		if [ "$2" = "$OK" ]
		then
			SERVICE_OK_CNT=$(expr $SERVICE_OK_CNT + 1)
		else
			SERVICE_FAIL_CNT=$(expr $SERVICE_FAIL_CNT + 1)
		fi
	elif [ "$1" = "LOG" ]
	then
		if [ "$2" = "$OK" ]
		then
			LOG_OK_CNT=$(expr $LOG_OK_CNT + 1)
		else
			LOG_FAIL_CNT=$(expr $LOG_FAIL_CNT + 1)
		fi
	else
		echo "category_count() wrong parameter:$1 $2"
	fi
}

#ELK
echo "id,report_datetime_start,service_name,os_type,os_version,hostname,network_ipv4_address,mac_address,script_version,test_id,test_type,test_category,test_result,test_description,detail_result" >> $ELK_RAW_FILE 2>&1

ELK_print()
{
	echo "\"\",\"$DATETIME\",\"$SERVICENAME\",\"$OS_TYPE\",\"$OS_VERSION\",\"$HOSTNAME\",\"$IPV4_ADDRESS\",\"$MAC_ADDRESS\",\"$SCRIPT_VER\",\"$1\",\"auto\",\"$2\",\"$3\",\"$4\",\"$5\"" >> $ELK_RAW_FILE 2>&1
	count $2 $3 $1 "$5"
	echo "Checking $1 ... $3"
}

print_debug()
{
if [ "$DEBUG" = "true" ]
then
echo "=====================================================================" >> $DEBUG_OUT_FILE
echo "[$1]" >> $DEBUG_OUT_FILE
$1 >> $DEBUG_OUT_FILE 2>> $DEBUG_OUT_FILE
echo " " >> $DEBUG_OUT_FILE
fi
}



make_report()
{
	echo "##############################################################" >> $REPORT_FILE 2>&1
	echo "##########          Linux Hardening Report          ##########" >> $REPORT_FILE 2>&1
	echo "##########               Security(VD)               ##########" >> $REPORT_FILE 2>&1
	echo "##########               version $SCRIPT_VER                ##########" >> $REPORT_FILE 2>&1
	echo "##########       written by vdcert@samsung.com      ##########" >> $REPORT_FILE 2>&1
	echo "##############################################################" >> $REPORT_FILE 2>&1
	echo " "                                                               >> $REPORT_FILE 2>&1
	echo "@ Service name : $SERVICENAME" >> $REPORT_FILE 2>&1
	echo "@ Host name : $HOSTNAME" >> $REPORT_FILE 2>&1
	echo "@ Server version : $OS_VERSION" >> $REPORT_FILE 2>&1
	echo "@ IPv4 Address : $IPV4_ADDRESS" >> $REPORT_FILE 2>&1
	echo "@ Hardening Script version : $SCRIPT_VER" >> $REPORT_FILE 2>&1
	echo "@ Report date time : $DATETIME" >> $REPORT_FILE 2>&1
	
	echo " " >> $REPORT_FILE 2>&1
	echo "###############################################################" >> $REPORT_FILE 2>&1
	echo "##################       Check Result      ####################" >> $REPORT_FILE 2>&1
	echo "###############################################################" >> $REPORT_FILE 2>&1
	echo "@ Total $(expr $OK_CNT + $FAIL_CNT) items " >> $REPORT_FILE 2>&1
	echo "----------------------------------------" >> $REPORT_FILE 2>&1
	echo "       CATEGORY       | PASS    | FAIL    |" >> $REPORT_FILE 2>&1
	echo "----------------------------------------" >> $REPORT_FILE 2>&1
	echo "     Authentication   | $AUTHN_OK_CNT    | $AUTHN_FAIL_CNT    |"  >> $REPORT_FILE 2>&1
	echo "     Authorization    | $AUTHZ_OK_CNT    | $AUTHZ_FAIL_CNT    |" >> $REPORT_FILE 2>&1
	echo "     Service          | $SERVICE_OK_CNT    | $SERVICE_FAIL_CNT    |" >> $REPORT_FILE 2>&1
	echo "----------------------------------------" >> $REPORT_FILE 2>&1
	echo "       TOTAL          | $OK_CNT    | $FAIL_CNT    |" >> $REPORT_FILE 2>&1
	echo "----------------------------------------" >> $REPORT_FILE 2>&1
	
	echo " " >> $REPORT_FILE 2>&1
	echo " " >> $REPORT_FILE 2>&1
	echo "###############################################################" >> $REPORT_FILE 2>&1
	echo "######################   Failure Items  #######################" >> $REPORT_FILE 2>&1
	echo "###############################################################" >> $REPORT_FILE 2>&1

	#FAIL_CODES = `cat ELK_RAW_FILE | awk -F"," '{if ($10 = "fail") print $7}'`
	printf "$FAIL_CODES" >> $REPORT_FILE 2>&1
	
	echo " " >> $REPORT_FILE 2>&1
	echo " " >> $REPORT_FILE 2>&1
	echo "######################   End of report  #######################" >> $REPORT_FILE 2>&1
}

################################################################################################
# AUTHN-L01C  
################################################################################################

RESULT=$OK
DETAIL_RESULT="OK"
if [ `awk -F: '($3 == "0") {print}' /etc/passwd | grep -v "root" | wc -l` -eq 0  ]
	then
	RESULT=$OK
	DETAIL_RESULT="OK"
else
	RESULT=$FAIL
	DETAIL_RESULT="account that is not the root account and has 0 as UID exists"
fi

ELK_print "AUTHN-L01C" "AUTHN" $RESULT "only root account have UID 0" "$DETAIL_RESULT"

################################################################################################
# AUTHZ-L01A  
################################################################################################

if [ `ls -alL /etc/passwd | awk '{print $1}' | grep "...-.--.--" | wc -l` -eq 1 ]
then
	if [ `ls -alL /etc/passwd | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
	then
		RESULT=$OK
		DETAIL_RESULT="OK"
	else
		DETAIL_RESULT="wrong owner(/etc/passwd)"   		
		RESULT=$FAIL
	fi
else
		DETAIL_RESULT="wrong permission(/etc/passwd)"
		RESULT=$FAIL
fi

if [ "$RESULT" = "$OK" ]
then
	if [ `ls -alL /etc/group| awk '{print $1}' | grep "...-.--.--" | wc -l` -eq 1 ]
	then
		if [ `ls -alL /etc/group | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK"
		else
			DETAIL_RESULT="wrong owner(/etc/group)"
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/group)"
			RESULT=$FAIL
	fi                                                                        
fi

ELK_print "AUTHZ-L01A" "AUTHZ" $RESULT "check permissions of /etc/passwd /etc/group" "$DETAIL_RESULT"

print_debug "ls -alL /etc/passwd /etc/group"

################################################################################################
# AUTHZ-L01B 
################################################################################################ 

if [ -f /etc/shadow ]
then  
	if [ `ls -alL /etc/shadow | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
	then
		if [ `ls -alL /etc/shadow | awk '{print $1}' | grep "...-------" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK" 
		#ubuntu default flavor
		elif [ `ls -alL /etc/shadow | awk '{print $1}' | grep "...-.-----" | wc -l` -eq 1 ]
		then
			if [ `ls -alL /etc/shadow | awk '{print $4}' | grep "shadow" | wc -l` -eq 1 ]
			then
				RESULT=$OK
				DETAIL_RESULT="OK" 
			else
				DETAIL_RESULT="wrong group(/etc/shadow)"
				RESULT=$FAIL
			fi
		else
			DETAIL_RESULT="wrong permission(/etc/shadow)" 
			RESULT=$FAIL
		fi 
	else
		DETAIL_RESULT="wrong owner(/etc/shadow)"
		RESULT=$FAIL
	fi
else
	DETAIL_RESULT="file is not found(/etc/shadow)" 
	RESULT=$FAIL                                                        
fi

ELK_print "AUTHZ-L01B" "AUTHZ" $RESULT "check permissions of /etc/shadow" "$DETAIL_RESULT"

print_debug "ls -al /etc/shadow"

################################################################################################
# AUTHZ-L01C
################################################################################################

HOSTFILE=/etc/hosts
if [ -f $HOSTFILE ]
then  
	if [ `ls -alL $HOSTFILE | awk '{print $1}' | grep "...-.--.--" | wc -l` -eq 1 ]
	then
		if [ `ls -alL $HOSTFILE | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK" 
		else
			DETAIL_RESULT="wrong owner(/etc/hosts)" 
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/hosts)" 
			RESULT=$FAIL
	fi                                                                        
else
			DETAIL_RESULT="file is not found(/etc/hosts)" 
			RESULT=$FAIL                                                        
fi

ELK_print "AUTHZ-L01C" "AUTHZ" $RESULT "check permissions of /etc/hosts" "$DETAIL_RESULT"

print_debug "ls -al /etc/hosts"

################################################################################################
# AUTHZ-L01D   
################################################################################################

SERVICEFILE=/etc/services
if [ -f $SERVICEFILE ]
then  
	if [ `ls -alL $SERVICEFILE | awk '{print $1}' | grep "...-.--.--" | wc -l` -eq 1 ]
	then
		if [ `ls -alL $SERVICEFILE | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK" 
		else
			DETAIL_RESULT="wrong owner(/etc/services)" 
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/services)" 
			RESULT=$FAIL
	fi                                                                        
else
			DETAIL_RESULT="file is not found(/etc/services)" 
			RESULT=$FAIL                                                        
fi

ELK_print "AUTHZ-L01D" "AUTHZ" $RESULT "check permissions of /etc/services" "$DETAIL_RESULT"

print_debug "ls -al /etc/services"

################################################################################################
# AUTHZ-L01E   
################################################################################################

PROFILEFILE=/etc/profile
if [ -f $PROFILEFILE ]
then  
	if [ `ls -alL $PROFILEFILE | awk '{print $1}' | grep ".rw..-..-." | wc -l` -eq 1 ]
	then
		if [ `ls -alL $PROFILEFILE | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK"
		else
			DETAIL_RESULT="wrong owner(/etc/profile)" 
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/profile)" 
			RESULT=$FAIL
	fi                                                                        
else
			DETAIL_RESULT="file is not found(/etc/profile)" 
			RESULT=$FAIL                                                        
fi

if [ "$RESULT" = "$OK" ]
then
	if [ `cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.profile"}' | wc -l` -eq 0 ]
	then
		DETAIL_RESULT="OK"
		RESULT=$OK
	elif [ `cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.profile"}' | xargs ls -alL 2> /dev/null | grep ".....w..w." | wc -l` -eq 0  ]
	then
		DETAIL_RESULT="OK"
		RESULT=$OK
	else
		DETAIL_RESULT="wrong permission(.profile)" 
		RESULT=$FAIL
	fi
fi

ELK_print "AUTHZ-L01E" "AUTHZ" $RESULT "check permissions of profile" "$DETAIL_RESULT"

print_debug "ls -al /etc/profile"
print_debug "cat /etc/passwd"

################################################################################################
# AUTHZ-L01F    
################################################################################################

XINETDFILE=/etc/xinetd.conf
if [ -f $XINETDFILE ]
then  
	if [ `ls -alL $XINETDFILE | awk '{print $1}' | grep "...-------" | wc -l` -eq 1 ]
	then
		if [ `ls -alL $XINETDFILE | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK" 
		else
			DETAIL_RESULT="wrong owner(/etc/xinetd.conf)" 
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/xinetd.conf)" 
			RESULT=$FAIL
	fi                                                                        
else
			RESULT=$OK      
			DETAIL_RESULT="OK"                                                   
fi

ELK_print "AUTHZ-L01F" "AUTHZ" $RESULT "check permissions of xinetd.conf" "$DETAIL_RESULT"
print_debug "ls -al  /etc/xinetd.conf"

################################################################################################
# AUTHZ-L01G
################################################################################################

EXPORTSFILE=/etc/exports
if [ -f $EXPORTSFILE ]
then  
	if [ `ls -alL $EXPORTSFILE | awk '{print $1}' | grep "...-.--.--" | wc -l` -eq 1 ]
	then
		if [ `ls -alL $EXPORTSFILE | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK" 
		else
			DETAIL_RESULT="wrong owner(/etc/exports)" 
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/exports)"
			RESULT=$FAIL
	fi                                                                        
else
			RESULT=$OK
			DETAIL_RESULT="OK"                                                         
fi

ELK_print "AUTHZ-L01G" "AUTHZ" $RESULT "check permissions of /etc/exports" "$DETAIL_RESULT"
print_debug "ls -al /etc/exports"

################################################################################################
# AUTHZ-L01H
################################################################################################

if [ -f /etc/cron.allow ]
then  
	if [ `ls -alL /etc/cron.allow | awk '{print $1}' | grep ".....-..-." | wc -l` -eq 1 ]
	then
		if [ `ls -alL /etc/cron.allow | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK"
		elif [ `ls -alL /etc/cron.allow | awk '{print $3}' | grep "bin" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK"
		else
			DETAIL_RESULT="wrong owner(/etc/cron.allow)"
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/cron.allow)"
			RESULT=$FAIL
	fi                                                                        
else
			RESULT=$OK
			DETAIL_RESULT="OK"                                                    
fi

if [ "$RESULT" = "$OK" ]
then
	if [ -f /etc/cron.deny ]
	then  
		if [ `ls -alL /etc/cron.deny | awk '{print $1}' | grep ".....-..-." | wc -l` -eq 1 ]
		then
			if [ `ls -alL /etc/cron.deny | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
			then
				RESULT=$OK
				DETAIL_RESULT="OK"
			elif [ `ls -alL /etc/cron.deny | awk '{print $3}' | grep "bin" | wc -l` -eq 1 ]
			then
				RESULT=$OK
				DETAIL_RESULT="OK"
			else
				DETAIL_RESULT="wrong owner(/etc/cron.deny)" 
				RESULT=$FAIL
			fi
		else
				DETAIL_RESULT="wrong permission(/etc/cron.deny)"
				RESULT=$FAIL
		fi                                                                        
	else
				RESULT=$OK
				DETAIL_RESULT="OK"             
	fi
fi

ELK_print "AUTHZ-L01H" "AUTHZ" $RESULT "check permissions of cron files" "$DETAIL_RESULT"

print_debug "ls -al /etc/cron.allow /etc/cron.deny"

################################################################################################
# AUTHZ-L01I 
################################################################################################

INETDFILE=/etc/inetd.conf
if [ -f $INETDFILE ]
then  
	if [ `ls -alL $INETDFILE | awk '{print $1}' | grep "...-------" | wc -l` -eq 1 ]
	then
		if [ `ls -alL $INETDFILE | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
		then
			RESULT=$OK
			DETAIL_RESULT="OK" 
		else
			DETAIL_RESULT="wrong owner(/etc/inetd.conf)"
			RESULT=$FAIL
		fi
	else
			DETAIL_RESULT="wrong permission(/etc/inetd.conf)"
			RESULT=$FAIL
	fi                                                                        
else
			RESULT=$OK
			DETAIL_RESULT="OK"                                                         
fi

ELK_print "AUTHZ-L01I" "AUTHZ" $RESULT "check permissions of /etc/inetd.conf" "$DETAIL_RESULT"

print_debug "ls -al /etc/cron.allow /etc/cron.deny"

################################################################################################
# AUTHZ-L02A
################################################################################################

if [ `umask | grep -v "^#" | egrep "022|027" | wc -l` -eq 1 ]
then
	RESULT=$OK
	DETAIL_RESULT="OK"
elif [ `cat /etc/profile 2> /dev/null | grep -v "^#" | grep -i umask | egrep "022|027" | wc -l` -eq 1]
then
	RESULT=$OK
elif [ `cat /etc/login.defs 2> /dev/null | grep -v "^#" | grep -i umask | egrep "022|027" | wc -l` -eq 1]
then
	RESULT=$OK
else
	RESULT=$FAIL
	DETAIL_RESULT="wrong mask(root)"
fi

ELK_print "AUTHZ-L02A" "AUTHZ" $RESULT "check umask of root" "$DETAIL_RESULT"

print_debug "umask"

################################################################################################
# AUTHZ-L02B
################################################################################################

if [ "$RESULT" = "$OK" ]
then
	if [ `cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.profile"}' | xargs cat 2> /dev/null | grep -v "^#" |grep 'umask [0-9][0-9][0-9]' | wc -l` -eq 0  ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK" 
	elif [ `cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.profile"}' | xargs cat 2> /dev/null | grep 'umask'| grep -v "^#" |grep -v 'umask 022'| grep -v 'umask 027' | wc -l` -eq 0  ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK" 
	else
		RESULT=$FAIL
		DETAIL_RESULT="wrong mask(.profie)"
	fi
fi
ELK_print "AUTHZ-L02B" "AUTHZ" $RESULT "check umask of all users" "$DETAIL_RESULT"

if [ "$DEBUG" = "true" ]
then
echo "================================================================" >> $DEBUG_OUT_FILE
echo "#[cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.profile"}' | xargs cat | grep -v "^#" |grep 'umask [0-9][0-9][0-9]']" >> $DEBUG_OUT_FILE
cat /etc/passwd | awk -F":" '($3 -gt 1000) && ($3 != 65534) {print $6"/.profile"}' | xargs cat 2>> $DEBUG_OUT_FILE | grep -v "^#" |grep 'umask [0-9][0-9][0-9]' >> $DEBUG_OUT_FILE
echo " " >> $DEBUG_OUT_FILE
fi

################################################################################################
# AUTHZ-L03A
################################################################################################

if [ `cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.rhosts"}' | wc -l` -eq 0  ]
then
	RESULT=$OK
	DETAIL_RESULT="OK"
	echo "111111111"
elif [ `cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.rhosts"}' | xargs ls -al 2> /dev/null | grep -v "...-------" |wc -l` -eq 0  ]
then
	RESULT=$OK
	DETAIL_RESULT="OK"
else
	RESULT=$FAIL
	DETAIL_RESULT="wrong permission(.rhosts)"
fi

if [ "$DEBUG" = "true" ]
then
echo "================================================================" >> $DEBUG_OUT_FILE
echo "#[cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.rhosts"}' | xargs ls -al]" >> $DEBUG_OUT_FILE
cat /etc/passwd | awk -F":" '($3 -gt $USER_START) && ($3 != 65534) {print $6"/.rhosts"}' | xargs ls -al >> $DEBUG_OUT_FILE 2>> $DEBUG_OUT_FILE
echo " " >> $DEBUG_OUT_FILE
fi

if [ "$RESULT" = "$OK" ]
then
	if [ -f /etc/hosts.equiv ]
	then  
		if [ `ls -alL /etc/hosts.equiv | awk '{print $1}' | grep ".---------" | wc -l` -eq 1 ]
		then
			if [ `ls -alL /etc/hosts.equiv | awk '{print $3}' | grep "root" | wc -l` -eq 1 ]
			then
				RESULT=$OK
				DETAIL_RESULT="OK"  
			else
				RESULT=$FAIL
				DETAIL_RESULT="wrong owner(/etc/hosts.equiv)"
			fi
		else
				RESULT=$FAIL
				DETAIL_RESULT="wrong permission(/etc/hosts.equiv)"
		fi                                                                        
	else
				RESULT=$OK
				DETAIL_RESULT="OK"                                                       
	fi
fi

print_debug "ls -alL /etc/hosts.equiv"

ELK_print "AUTHZ-L03A" "AUTHZ" $RESULT "check permission of system file" "$DETAIL_RESULT"

################################################################################################
# SVC-L03A
################################################################################################

RESULT=$OK
DETAIL_RESULT="OK"
if [ -f /etc/snmpd.conf ]
then  
	FIND=`cat /etc/snmpd.conf | grep "^com2sec" | awk '{ print $4 }'`
	for I in ${FIND}; do
	    if [ "${I}" = "public" -o "${I}" = "private" ]; then
				RESULT=$FAIL
				DETAIL_RESULT="community vaule is default value"  
	    fi
	done
else
  RESULT=$OK                                                          
fi

ELK_print "SVC-L03A" "SERVICE" $RESULT "check snmpd conf" "$DETAIL_RESULT"

print_debug "cat /etc/snmpd.conf"

################################################################################################
# SVC-L03B
################################################################################################

if [ `cat /etc/passwd | egrep "ftp|anonymous" | wc -l` -eq 0  ]
	then
	if [ `cat /etc/shadow | egrep "ftp|anonymous" | wc -l` -eq 0  ]
		then
		if [ -f /etc/vsftpd.conf  ]
			then
			if [ `cat /etc/vsftpd.conf | grep -i "anonymous_enable=NO" | wc -l` -eq 1  ]
				then
				RESULT=$OK
				DETAIL_RESULT="OK" 
			else
				RESULT=$FAIL
				DETAIL_RESULT="wrong anonymous_enable value"  
			fi
		elif [ -f /etc/vsftpd/vsftpd.conf ]
			then
			if [ `cat /etc/vsftpd/vsftpd.conf | grep -i "anonymous_enable=NO" | wc -l` -eq 1  ]
				then
				RESULT=$OK
				DETAIL_RESULT="OK" 
			else
				RESULT=$FAIL
				DETAIL_RESULT="wrong anonymous_enable value"  
			fi
		else
			RESULT=$OK
			DETAIL_RESULT="OK" 
		fi
	else
		RESULT=$FAIL
		DETAIL_RESULT="ftp or anonymous account exist"  
	fi
else
	RESULT=$FAIL
	DETAIL_RESULT="ftp or anonymous account exist"  
fi

ELK_print "SVC-L03B" "SERVICE" $RESULT "check anonymous account of ftp" "$DETAIL_RESULT"

################################################################################################
# SVC-L03C
################################################################################################

RESULT=$OK
DETAIL_RESULT="OK"
if [[ "$OS_VERSION" == *"Amazon"* || "$OS_VERSION" == *"Red Hat"* ]]
	then
	if [ `rpm -qa | grep vsftpd 2>/dev/null | wc -l` -eq 0  ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK"
	else
		if [ -f /etc/vsftpd/vsftpd.conf ]
			then
			if [ `cat /etc/vsftpd/vsftpd.conf | egrep -i "^SSL_ENABLE" 2>/dev/null | wc -l` -ge 1 ]
				then
				if [ `egrep -r -i "^ssl_enable=no" /etc/vsftpd/vsftpd.conf 2>/dev/null | wc -l` -eq 0 ]
					then
					RESULT=$OK
					DETAIL_RESULT="OK"
				else
					RESULT=$FAIL
					DETAIL_RESULT="ftp data is not encrypted"
				fi
			else
				RESULT=$FAIL
				DETAIL_RESULT="ftp data is not encrypted"
			fi
		fi
	fi
elif [[ "$OS_VERSION" == *"Ubuntu"* ]]
	then
	if [ `dpkg -l vsftpd 2>/dev/null | egrep "^ii" | wc -l` -eq 0  ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK"
	else
		if [ -f /etc/vsftpd.conf ]
			then
			if [ `cat /etc/vsftpd.conf | egrep -i "^SSL_ENABLE" 2>/dev/null | wc -l` -ge 1 ]
				then
				if [ `egrep -r -i "^ssl_enable=no" /etc/vsftpd.conf 2>/dev/null | wc -l` -eq 0 ]
					then
					RESULT=$OK
					DETAIL_RESULT="OK"
				else
					RESULT=$FAIL
					DETAIL_RESULT="ftp data is not encrypted"
				fi
			else
				RESULT=$FAIL
				DETAIL_RESULT="ftp data is not encrypted"
			fi
		fi
	fi
else
	# If failure to detect OS.
    RESULT=$OK      
	DETAIL_RESULT="OK"         
fi

ELK_print "SVC-L03C" "SERVICE" $RESULT "if must use ftp, apply SSL/TLS." "$DETAIL_RESULT"

################################################################################################
# SVC-L03E
################################################################################################

RESULT=$OK
DETAIL_RESULT="OK"
if [ -f /etc/ssh/sshd_config ]
	then
	if [ `egrep -r -i "^permitrootlogin yes" /etc/ssh/sshd_config | wc -l` -eq 0 ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK"
	else
		RESULT=$FAIL
		DETAIL_RESULT="password login of the root account is allowed (ssh)"
	fi
fi

ELK_print "SVC-L03E" "SERVICE" $RESULT "reject password login of root account." "$DETAIL_RESULT"

################################################################################################
# SVC-L03F
################################################################################################

RESULT=$OK
DETAIL_RESULT="OK"
if [ -f /etc/ssh/sshd_config ]
	then
	if [ `egrep -r -i "^protocol" /etc/ssh/sshd_config | grep 1 2>/dev/null | wc -l` -eq 0 ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK"
	else
		RESULT=$FAIL
		DETAIL_RESULT="weak version of the protocol is provided (ssh)"
	fi
fi

ELK_print "SVC-L03F" "SERVICE" $RESULT "only protocol version 2 should be supported." "$DETAIL_RESULT"

################################################################################################
# SVC-L03G
################################################################################################

RESULT=$OK
DETAIL_RESULT="OK"
if [[ "$OS_VERSION" == *"Amazon"* || "$OS_VERSION" == *"Red Hat"* ]]
	then
	if [ `rpm -qa | grep telnet-server 2>/dev/null | wc -l` -eq 0  ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK"
	else
		RESULT=$FAIL
		DETAIL_RESULT="telnetd package is installed"
	fi
elif [[ "$OS_VERSION" == *"Ubuntu"* ]]
	then
	if [ `dpkg -l telnetd 2> /dev/null | egrep "^ii" | wc -l` -eq 0  ]
		then
		RESULT=$OK
		DETAIL_RESULT="OK"
	else
		RESULT=$FAIL
		DETAIL_RESULT="telnetd package is installed"
	fi
else
	# If filure to detect OS.
    RESULT=$OK      
	DETAIL_RESULT="OK"         
fi

ELK_print "SVC-L03G" "SERVICE" $RESULT "remove telnetd package" "$DETAIL_RESULT"

################################################################################################
# SVC-L04A   
################################################################################################

PATH_WC=`cat /etc/profile 2> /dev/null | grep "PATH" | grep -v "^#" |grep "[^a-zA-Z0-9]\.[^a-zA-Z0-9]" | wc -l`
if [ $PATH_WC -eq 0 ]
then
 RESULT="$OK"
 DETAIL_RESULT="OK" 
else
 DETAIL_RESULT="PATH include ."  
 RESULT="$FAIL"
fi

ELK_print "SVC-L04A" "SERVICE" $RESULT "check PATH include ." "$DETAIL_RESULT"
print_debug "grep PATH /etc/profile"
################################################################################################
make_report   
################################################################################################

ENDTIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "@End time: $ENDTIME"
echo "Finished..."
echo ""
echo ""

CURRENT_PATH=$(pwd)
echo "Result files written at"
echo "-Report file:$CURRENT_PATH/$REPORT_FILE"
echo "-ELK result file:$CURRENT_PATH/$ELK_RAW_FILE"
if [ "$DEBUG" = "true" ]
then
echo "-Debug file:$CURRENT_PATH/$DEBUG_OUT_FILE"
fi


#!/bin/sh
#*****************************************************************************
#* 
#*  @file          ntp-query.sh
#*
#*  Run NTP timeserver query as background process. 
#*  The ntpdate utility can run for several minutes until it has gotten
#*  a valid time in particular on a slow network connection (GPRS), a
#*  large timeout (-t option) and if many NTP-hosts are specified.
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Guido Classen <br>
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*    2007-12-03 gc: initial version
#*  
#*****************************************************************************

NTPDATE=/usr/bin/ntpdate
HWCLOCK=/sbin/hwclock

# synchronize systime from NTP-Server
test -f $NTPDATE || exit 0
test -f /etc/default/ntpdate || exit 0

. /etc/default/ntpdate

test -n "$NTPSERVERS" || exit 0

logger -t $0 "Running ntpdate to synchronize clock"
$NTPDATE $NTPOPTIONS $NTPSERVERS && $HWCLOCK -w
logger -t $0 "ntpdate finished with: `date`"
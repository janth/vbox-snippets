#!/bin/bash

# install as /etc/init.d/vbox-customize
# then run
# chkconfig --add vbox-customize

# vbox-customize          Add ip to /etc/issue and sets guestproperty LogonCompleted
#
# chkconfig: 3 99 99
# description: Use the source, Luke!
#

### BEGIN INIT INFO
# Provides: vbox-customize
# Required-Start:  sshd
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Add ip to /etc/issue and sets guestproperty LogonCompleted
# Description:       Virtualbox customization, /usr/local/bin/ip2etc_issue.sh, guestproperty LogonCompleted
### END INIT INFO



[ -x /usr/local/bin/ip2etc_issue.sh ] && /usr/local/bin/ip2etc_issue.sh

[ -x /usr/bin/VBoxControl ] && /usr/bin/VBoxControl guestproperty set LogonCompleted true --flags TRANSIENT,TRANSRESET

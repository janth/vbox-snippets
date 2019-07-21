cat /usr/local/bin/ip2issue.sh
#!/bin/bash

cat > /etc/issue << X

\S
Kernel \r on an \m

$( /sbin/ip --oneline -4 address | /usr/bin/awk '$2 !~ /^lo$/ {print $2 " " $4}' )

X


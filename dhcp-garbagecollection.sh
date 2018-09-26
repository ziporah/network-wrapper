#!/bin/bash
#
# garbage collector for DHCP client vs. Docker containers
# 
# https://github.com/zenvdeluca/network-wrapper
#

diff(){
  awk 'BEGIN{RS=ORS=" "}
       {NR==FNR?a[$0]++:a[$0]--}
       END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
}


DHCP=($(ps ax |grep dhclient[-]docker | cut -d. -f2))
DOCKER=($(docker ps -q -f network=none ))

ZOMBIE=($(diff DHCP[@] DOCKER[@]))
if [ ! -z $ZOMBIE ] ; then 
echo "Orphan IDs ${ZOMBIE[@]}"
for i in ${ZOMBIE[@]} ; do
  if [ ! -z $(docker ps -q | grep $i) ]; then
    echo "stopping orphan container"
    docker stop $i
  fi
  PIDFILE=$(ls -a /var/run/dhclient-docker.*$i*.pid)
  if [ ! -z $PIDFILE ]; then
    KPID=$(cat $PIDFILE)
    kill -9 $KPID 2>/dev/null
  fi
  echo rm -f $PIDFILE 2>/dev/null
  CFGFILE=$(ls -a /var/run/dhclient-docker.*$i*.conf)
  rm -f $CFGFILE 2>/dev/null
  echo -n .
done
fi

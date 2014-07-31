#!/bin/bash
# description: create spice html5 websocket server by port relaying

# example:
# websockify-daemon.sh 127.0.0.1:1-3
# relaying port from 1,2,3 of 127.0.0.1 to new_port

new_port=5950

for var in "$@"
do
  IFS=':' read -ra ADDR <<< "$var"
  ip=${ADDR[0]}
  IFS='-' read -ra ADDR <<< "${ADDR[1]}"
  port_st=${ADDR[0]}
  port_end=${ADDR[1]}

  for (( i=$port_st; i<=$port_end; i++ ))
  do
    ps -ef | grep "$ip:$i -D" | awk '{print $2}' | xargs kill > /dev/null 2>&1& # kill old server
    tmp=`lsof -i :$new_port`
    while [ ! -z "$tmp" -a "$tmp" != " " ] # check if port is already in use
    do
      (( new_port++ ))
      tmp=`lsof -i :$new_port`
    done
    ./scripts/websockify/websockify.py $new_port $ip:$i -D # run in daemon, very light process
    echo "$ip:$i to port $new_port: DONE!"
    (( new_port++ ))
  done
done

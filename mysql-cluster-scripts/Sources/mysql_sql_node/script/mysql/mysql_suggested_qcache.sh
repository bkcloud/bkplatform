#!/bin/bash

available_memory=$(echo $(free -b | grep Mem | awk '{print $2}')*0.9-256*1024|bc)
a=$(echo $available_memory/10|bc)
b=$(echo 8*1024*2024|bc)
echo $(($a<$b?$b:$a))

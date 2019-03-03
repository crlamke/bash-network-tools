#!/bin/bash
ipFirstThreeOctets="192.168.1"
lastIPOctetLow=1
lastIPOctetHigh=64
dateTime=`date '+%Y_%m_%d__%H_%M_%S'`;
responseFileName="live-hosts-${dateTime}.txt"

 # Trap ctrl + c 
trap ctrl_c INT
function ctrl_c() 
{
  echo "ctrl-c received. Exiting"
  exit
}

printf "\nPing scanning IP range from %s.%d" ${ipFirstThreeOctets} $lastIPOctetLow
printf " to %s.%d\n" ${ipFirstThreeOctets} $lastIPOctetHigh
printf "\nResponding hosts will be recorded in %s\n" $responseFileName
touch ./${responseFileName} &> /dev/null
printf "\nStarting"

for ((p=$lastIPOctetLow;p<=$lastIPOctetHigh;p++)) do
  printf "."
  pingAddress="${ipFirstThreeOctets}.${p}"
  #echo "Scanning ${pingAddress}"
  ping -c 1 -W 3 ${pingAddress} &> /dev/null
  if [ $? == 0 ]; then
    echo ${pingAddress} >> $responseFileName
  fi
done

printf "complete\n"

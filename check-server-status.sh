#!/bin/bash

#set -x

RED="\033[0;31m"
GREEN="\033[0;32m"
NOCOLOR="\033[0m"

verbose=0
count=0
serverCount=0
serverConfigPath=""
declare -a ipAddress
declare -a hostname
declare -a hostDescription
declare -a pingReachable
declare -a sshAvailable


function usage()
{
  echo "Usage: $0 path-of-server-cfg-file"
  echo ""
  echo "\twhere cfg-file is the path to the server config file you want to process"
  echo ""
}

# Name: checkParameters
# Parameters: none
# Description: This function will validate the command line parameters
function checkParameters()
{
  printf "\nChecking parameters ...\n"
  if [ $1 != "" ]; then
    serverConfigPath=$1 
    if [ -f $serverConfigPath ]; then
      printf "Using $serverConfigPath as server config file.\n"
    else
      printf "$serverConfigPath not found\n"
      printUsage
      exit 1
    fi
  else
    printUsage
    exit 1
  fi
}


# Name: readServerConfig
# Parameters: none
# Description: This function will read in a CSV file and store it in arrays
#              for later processing.
function readServerConfig()
{
  printf "\nReading server config file ...\n"
  counter=0
  while IFS=, read -r ipAddress[$counter] hostname[$counter] hostDescription[$counter]
  do
    echo "Read: ${ipAddress[$counter]} | ${hostname[$counter]} | ${hostDescription[$counter]}"
    let counter=$counter+1 
    let serverCount=$serverCount+1 
  done < $serverConfigPath

  printf "Finished reading server config file ...\n"
}


# Name: checkServerPing
# Parameters: none
# Description: This function will check ping reachability for all servers
#              in the server array loaded from a file.
function checkServerPing()
{
  printf "\nChecking servers' ping reachability ...\n"
  counter=0
  while [ $counter -lt $serverCount ]; do
    
    ping -c 1 -W 3 ${ipAddress[$counter]} &> /dev/null
    if [ $? == 0 ]; then
      pingReachable[$counter]=0
    else
      pingReachable[$counter]=1
    fi
    let counter=$counter+1 
  done

  printf "Finished checking servers' ping reachability ...\n"
}


# Name: checkSSHAvailability
# Parameters: none
# Description: This function will check SSH availability for all servers
#              in the server array loaded from a file.
function checkSSHAvailability()
{
  printf "\nChecking servers' ssh availability ...\n"
  counter=0
  while [ $counter -lt $serverCount ]; do
    # Not using ssh-keyscan as it's unreliable on my test network. I may have syntax wrong    
    # ssh-keyscan ${ipAddress[$counter]} 2>&1 | grep -v "^$" > /dev/null
    # We're going to use netcat for now because it at least tells us reliably
    # whether there's a service at port 22.
    nc -w 3 -z ${ipAddress[$counter]} 22 > /dev/null
    
    if [ $? == 0 ]; then
      sshAvailable[$counter]=0
    else
      sshAvailable[$counter]=1
    fi
    let counter=$counter+1 
  done

  printf "Finished checking servers' ssh availability ...\n"
}

# Name: reportResults
# Parameters: none
# Description: This function reports the results of the servers checks.
function reportResults()
{
  printf "\nReporting results ...\n"
  counter=0
  while [ $counter -lt $serverCount ]; do
    reportResultsString=""
    reportError=0
    reportHostString="${hostname[$counter]} | ${ipAddress[$counter]} : "
    if [ ${sshAvailable[$counter]} -eq 0 ]; then
      reportResultsString="SSH available"
    else
      reportError=1
      reportResultsString="SSH NOT available"
    fi

    if [ ${pingReachable[$counter]} -eq 0 ]; then
      reportResultsString="$reportResultsString | Ping Response"
    else
      reportError=1
      reportResultsString="$reportResultsString | NO Ping Response"
    fi

    if [ $reportError -eq 1 ]; then
    reportHostString="${hostname[$counter]} | ${ipAddress[$counter]} : "
      printf "%b%-12s : %-15s : %s%b\n" "${RED}" "${hostname[$counter]}" "${ipAddress[$counter]}" "${reportResultsString}" "${NOCOLOR}"
    else
      printf "%b%-12s : %-15s : %s%b\n" "${GREEN}" "${hostname[$counter]}" "${ipAddress[$counter]}" "${reportResultsString}" "${NOCOLOR}"
    fi

    let counter=$counter+1 
  done

}

checkParameters "$@"

readServerConfig

checkServerPing

checkSSHAvailability

reportResults


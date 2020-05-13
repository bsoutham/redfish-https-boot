#!/bin/bash

ILO_IP=192.168.5.129
ILO_USER=
ILO_PASSWORD=
OUTPUT=log.log

function power {
  STATE=$1
  echo Powering $STATE server ....
  if [ $STATE == "Off" ]; then
    STATE="ForceOff"
  fi
  if [ $STATE == "Reboot" ]; then
    STATE="ForceRestart"
  fi
  curl -k -s "https://$ILO_IP/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/" \
    -X POST \
    -d "{\"ResetType\": \"$STATE\"}" \
    -H "X-Auth-Token: $AUTH_TOKEN" \
    -H "Content-Type: application/json" &>> $OUTPUT
  sleep 10
}

function login {
  AUTH_TOKEN="$(curl -k -sD - -o /dev/null  "https://$ILO_IP/redfish/v1/SessionService/Sessions/" \
    -X POST -d "{\"UserName\":\"$ILO_USER\", \"Password\": \"$ILO_PASSWORD\"}" \
    -H "Content-Type: application/json"  | awk '/X-Auth-Token/ {print $2}')"
}

#erase log contents
echo &> $OUTPUT

echo Attempting Login to $ILO_IP
login

echo Ensuring the server is powered off
power Off

echo Removing Boot URL
curl -s -k "https://$ILO_IP/redfish/v1/systems/1/bios/settings/" -X PATCH -d '{"Attributes":{"UrlBootFile":""}}' -H "Content-Type: application/json" -H "X-Auth-Token: $AUTH_TOKEN" &>> $OUTPUT



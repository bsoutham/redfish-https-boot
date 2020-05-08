#!/bin/bash

ILO_IP=192.168.5.129
BOOT_URL=http://192.168.3.17:8000/bootx64.efi
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
  AUTH_TOKEN="$(curl -k -sD - -o /dev/null  "https://192.168.5.129/redfish/v1/SessionService/Sessions/" \
    -X POST -d '{"UserName":"quake", "Password": "Quattro8337"}' \
    -H "Content-Type: application/json"  | awk '/X-Auth-Token/ {print $2}')"
}


echo Attempting Login to $ILO_IP
login

echo Ensuring the server is powered off
power Off

echo Programming Boot URL to $BOOT_URL
curl -s -k "https://192.168.5.129/redfish/v1/systems/1/bios/settings/" -X PATCH -d '{"Attributes":{"UrlBootFile":""}}' -H "Content-Type: application/json" -H "X-Auth-Token: $AUTH_TOKEN" &> $OUTPUT



#!/bin/bash

ILO_IP=16.124.128.51
ILO_USER=
ILO_PASSWORD=
BOOT_URL=http://16.114.218.252:8000/bootx64.efi
OUTPUT=/dev/null

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


echo Attempting Login to $ILO_IP
login

echo Ensuring the server is powered off
power Off

echo Programming Boot URL to $BOOT_URL
curl -s -k "https://$ILO_IP/redfish/v1/systems/1/bios/settings/" -X PATCH -d "{\"Attributes\":{\"UrlBootFile\":\"$BOOT_URL\"}}" -H "Content-Type: application/json" -H "X-Auth-Token: $AUTH_TOKEN" &> $OUTPUT


power On

while true; do
  CONTENT="$( curl -k -s "https://$ILO_IP/redfish/v1/Systems/1/"  \
	  -H "X-Auth-Token: $AUTH_TOKEN" | jq '.Boot."UefiTargetBootSourceOverride@Redfish.AllowableValues"')"
  if [[ $CONTENT == *"$BOOT_URL"* ]]; then
    echo Found $BOOT_URL as available target.
    break
  fi

  echo Waiting for $BOOT_URL to be valid target.....
  echo $CONTENT >> $OUTPUT
  sleep 10
done

power Off

echo Programming UefiTarget and BootSourceOverrideTarget
curl -k -s "https://$ILO_IP/redfish/v1/Systems/1/" \
  -X PATCH \
  -d "{\"Boot\": {\"BootSourceOverrideEnabled\":\"Once\", \"BootSourceOverrideTarget\":\"UefiTarget\", \"UefiTargetBootSourceOverride\":\"IPv4(0.0.0.0)/Uri("$BOOT_URL")\"}}" \
  -H "X-Auth-Token: $AUTH_TOKEN" \
  -H "Content-Type: application/json" &>> $OUTPUT

power On


#!/bin/bash

AUTH_TOKEN="efad143ab468e2d11d4a31674cbb082a"
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
  sleep 15
}

echo Ensuring the server is powered off
power Off

echo Programming Boot URL to $BOOT_URL
curl -k -s "https://$ILO_IP/redfish/v1/systems/1/bios/boot/settings/" \
  -X PATCH \
  -d "{\"Attributes\":{\"UrlBootFile\":\"$BOOT_URL\"}}" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $AUTH_TOKEN" &> $OUTPUT


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

# just wait 10 seconds
sleep 10
echo Programming UefiTarget and BootSourceOverrideTarget
curl -k -s "https://$ILO_IP/redfish/v1/Systems/1/" \
  -X PATCH \
  -d "{\"Boot\": {\"BootSourceOverrideEnabled\":\"Once\", \"BootSourceOverrideTarget\":\"UefiTarget\", \"UefiTargetBootSourceOverride\":\"IPv4(0.0.0.0)/Uri("$BOOT_URL")\"}}" \
  -H "X-Auth-Token: $AUTH_TOKEN" \
  -H "Content-Type: application/json" &>> $OUTPUT

power On


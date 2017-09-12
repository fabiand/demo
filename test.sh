#!/usr/bin/bash

bold() { echo -e "\e[1m$@\e[0m" ; }
red() { echo -e "\e[31m$@\e[0m" ; }
green() { echo -e "\e[32m$@\e[0m" ; }

ok() { green OK ; }
fail() { red "ERR\nFAIL" ; exit 2 ; }

check() { echo -n "$1 ... "; eval "$2" && ok || fail ; }


check_websocket() {
  local IP=$(minikube ip) ;
  curl -s -i -N -H "Connection: Upgrade" \
  http://$IP:8184/apis/kubevirt.io/v1alpha1/namespaces/default/vms/testvm/console | grep -q "Sec-Websocket-Version: 13" 
}


check "VM API is present" "kubectl api-versions | grep -q kubevirt.io"
check "VM is running" "( kubectl get -o json vms testvm | jq .status.phase ) | grep -q Running"
check "VM serial console works" "check_websocket"


green PASS

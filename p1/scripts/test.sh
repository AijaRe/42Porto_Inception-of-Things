#!/usr/bin/env bash
# Checks Part 1 against the subject from the host. Run after "vagrant up".
cd "$(dirname "$0")/.." || exit 1

PASS=0
FAIL=0
check() { # check "description" <command...>
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"; PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc"; FAIL=$((FAIL + 1))
  fi
}
on() { vagrant ssh "$1" -c "$2" 2>/dev/null | tr -d '\r'; } # on VM "command"

echo "===> VMs"
status=$(vagrant status --machine-readable 2>/dev/null)
check "gamado-xS is running"  grep -q "gamado-xS,state,running" <<<"$status"
check "gamado-xSW is running" grep -q "gamado-xSW,state,running" <<<"$status"

for vm in gamado-xS gamado-xSW; do
  [ "$vm" = gamado-xS ] && ip=192.168.56.110 || ip=192.168.56.111
  echo "===> $vm"
  facts=$(on "$vm" 'hostname; nproc; free -m | awk "/Mem:/{print \$2}"; ip -4 -o addr show eth1 | awk "{print \$4}"')
  check "hostname is $vm"           test "$(sed -n 1p <<<"$facts")" = "$vm"
  check "1 CPU"                     test "$(sed -n 2p <<<"$facts")" = 1
  mem=$(sed -n 3p <<<"$facts")
  check "about 1 GB RAM (${mem:-?} MiB)" test "${mem:-0}" -ge 900 -a "${mem:-0}" -le 1024
  check "eth1 is $ip"               test "$(sed -n 4p <<<"$facts")" = "$ip/24"
done

echo "===> K3s"
check "k3s server running on gamado-xS"      test "$(on gamado-xS 'systemctl is-active k3s')" = active
check "k3s agent running on gamado-xSW"      test "$(on gamado-xSW 'systemctl is-active k3s-agent')" = active
check "kubectl has no access on the worker" bash -c "! vagrant ssh gamado-xSW -c 'kubectl get nodes' >/dev/null 2>&1"

nodes=$(on gamado-xS 'kubectl get nodes -o wide --no-headers')
check "gamado-xs Ready, control-plane, 192.168.56.110" grep -Eq "^gamado-xs +Ready +control-plane .*192\.168\.56\.110" <<<"$nodes"
check "gamado-xsw Ready, 192.168.56.111"              grep -Eq "^gamado-xsw +Ready .*192\.168\.56\.111" <<<"$nodes"

echo "===> Workload on the worker (may take a minute to pull the image)"
on gamado-xS 'kubectl delete pod p1-test --ignore-not-found >/dev/null; kubectl run p1-test --image=busybox --restart=Never --overrides="{\"spec\":{\"nodeName\":\"gamado-xsw\"}}" -- sleep 60 >/dev/null' >/dev/null
check "a Pod pinned to gamado-xsw reaches Running" \
  bash -c "vagrant ssh gamado-xS -c 'kubectl wait --for=jsonpath={.status.phase}=Running pod/p1-test --timeout=180s' >/dev/null 2>&1"
on gamado-xS 'kubectl delete pod p1-test --ignore-not-found --wait=false' >/dev/null

echo "===> $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

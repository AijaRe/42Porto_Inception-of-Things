#!/usr/bin/env bash
# Checks Part 2 against the subject from the host. Run after "vagrant up".
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
on() { vagrant ssh arepsaS -c "$1" 2>/dev/null | tr -d '\r'; }
hello() { curl -s -m 5 "$@" 192.168.56.110 | grep -o "Hello from app[0-9]" | head -1; }

echo "===> VM"
check "arepsaS is running" bash -c "vagrant status --machine-readable | grep -q 'arepsaS,state,running'"
check "hostname is arepsaS" test "$(on hostname)" = arepsaS
check "eth1 is 192.168.56.110" test "$(on 'ip -4 -o addr show eth1 | awk "{print \$4}"')" = 192.168.56.110/24

echo "===> Routing from the host (Host header)"
check "app1.com answers app1"          test "$(hello -H 'Host: app1.com')" = "Hello from app1"
check "app2.com answers app2"          test "$(hello -H 'Host: app2.com')" = "Hello from app2"
check "bare IP answers app3 (default)" test "$(hello)" = "Hello from app3"
check "other.com answers app3 (default)" test "$(hello -H 'Host: other.com')" = "Hello from app3"

pods=$(for i in $(seq 1 12); do curl -s -m 5 -H "Host: app2.com" 192.168.56.110 | grep -o "app2-deploy-[a-z0-9-]*" | head -1; done | sort -u | wc -l)
check "app2 is answered by 3 different Pods ($pods seen)" test "$pods" -eq 3

echo "===> Cluster"
check "one node, Ready, 192.168.56.110" bash -c "[ \"\$(vagrant ssh -c 'kubectl get nodes -o wide --no-headers' 2>/dev/null | grep -Ec 'Ready .*192\.168\.56\.110')\" = 1 ]"
deploys=$(on "kubectl get deploy -o jsonpath='{range .items[*]}{.metadata.name}={.status.readyReplicas}{\"\\n\"}{end}'")
check "app1-deploy has 1 ready replica"  grep -qx "app1-deploy=1" <<<"$deploys"
check "app2-deploy has 3 ready replicas" grep -qx "app2-deploy=3" <<<"$deploys"
check "app3-deploy has 1 ready replica"  grep -qx "app3-deploy=1" <<<"$deploys"
check "Ingress apps-ingress exists" test -n "$(on 'kubectl get ingress apps-ingress -o name')"
check "Traefik exposed as LoadBalancer on 192.168.56.110" \
  grep -q "LoadBalancer.*192.168.56.110" <<<"$(on 'kubectl get svc -n kube-system traefik --no-headers')"

echo "===> $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

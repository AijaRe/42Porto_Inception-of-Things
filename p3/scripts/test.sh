#!/usr/bin/env bash
# Checks Part 3 against the subject from the host. Run after "make setup".

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

echo "===> Tools"
check "docker is installed and running" docker info
check "k3d is installed"                k3d version
check "kubectl is installed"            kubectl version --client

echo "===> Cluster"
check "k3d cluster argonauts exists" bash -c "k3d cluster list | grep -q '^argonauts '"
check "node is Ready"                bash -c "kubectl get nodes --no-headers | grep -q ' Ready '"
check "namespace argocd exists"      kubectl get namespace argocd
check "namespace dev exists"         kubectl get namespace dev

echo "===> Argo CD"
check "all Argo CD Deployments are available" kubectl -n argocd wait --for=condition=Available deployment --all --timeout=10s
check "Application wil-playground is Synced" \
  test "$(kubectl -n argocd get application wil-playground -o jsonpath='{.status.sync.status}')" = Synced
check "Application wil-playground is Healthy" \
  test "$(kubectl -n argocd get application wil-playground -o jsonpath='{.status.health.status}')" = Healthy
check "it watches a public GitHub repository" \
  bash -c "curl -sf -o /dev/null \"\$(kubectl -n argocd get application wil-playground -o jsonpath='{.spec.source.repoURL}' | sed 's/\.git$//')\""

echo "===> Application in dev"
image=$(kubectl -n dev get deployment wil-playground -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
check "wil-playground Pod is Running (${image:-no image})" \
  kubectl -n dev wait --for=condition=Ready pod -l app=wil-playground --timeout=10s
kubectl -n dev port-forward svc/wil-playground 8888:8888 >/dev/null 2>&1 &
pf=$!
sleep 3
answer=$(curl -s -m 5 http://localhost:8888/)
kill "$pf" 2>/dev/null
check "app answers on port 8888: ${answer:-nothing}" grep -q '"status":"ok"' <<<"$answer"
check "app version matches the image tag (${image##*:})" grep -q "\"${image##*:}\"" <<<"$answer"

echo "===> $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

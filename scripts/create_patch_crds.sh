#!/bin/bash

set -euo pipefail

# === ISTIO CONFIG ===
ISTIO_VERSION=1.25.2
ISTIO_DIR="istio-$ISTIO_VERSION"
ISTIO_NS="istio-system"
ISTIO_RELEASE_NAME="istio-base"

# === ARGO CD CONFIG ===
ARGO_VERSION="v3.0.0"
ARGO_NS="argocd"
ARGO_RELEASE_NAME="argocd"

echo "📥 Downloading Istio $ISTIO_VERSION..."
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

echo "📄 Applying Istio CRDs..."
kubectl apply -f "$ISTIO_DIR/manifests/charts/base/files/crd-all.gen.yaml"

echo "🔧 Patching Istio CRDs for Helm ownership..."
for crd in $(kubectl get crds -o name | grep '\.istio\.io'); do
  echo "🔧 Patching $crd..."
  kubectl patch $crd --type=merge -p "{
    \"metadata\": {
      \"labels\": {
        \"app.kubernetes.io/managed-by\": \"Helm\"
      },
      \"annotations\": {
        \"meta.helm.sh/release-name\": \"$ISTIO_RELEASE_NAME\",
        \"meta.helm.sh/release-namespace\": \"$ISTIO_NS\"
      }
    }
  }"
done
echo "✅ Istio CRDs patched."

# === ARGO CD CRDs INSTALLATION ===
echo "📄 Applying Argo CD v$ARGO_VERSION CRDs..."
kubectl apply -f "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGO_VERSION/manifests/crds/application-crd.yaml"
kubectl apply -f "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGO_VERSION/manifests/crds/applicationset-crd.yaml"
kubectl apply -f "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGO_VERSION/manifests/crds/appproject-crd.yaml"

echo "🔧 Patching Argo CD CRDs for Helm ownership..."
for crd in applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io; do
  echo "🔧 Patching $crd..."
  kubectl label crd $crd app.kubernetes.io/managed-by=Helm --overwrite
  kubectl annotate crd $crd meta.helm.sh/release-name=$ARGO_RELEASE_NAME --overwrite
  kubectl annotate crd $crd meta.helm.sh/release-namespace=$ARGO_NS --overwrite
done
echo "✅ Argo CD CRDs patched."

echo "🎉 All CRDs installed and Helm metadata applied successfully."

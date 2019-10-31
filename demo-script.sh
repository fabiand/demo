set -ex

# https://github.com/kubernetes-sigs/kind#installation-and-usage
[[ -f kind ]] || curl -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-linux-amd64
# https://kubernetes.io/docs/tasks/tools/install-kubectl/
[[ -f kubectl ]] || curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl
[[ -f virtctl ]] || curl -Lo virtctl https://github.com/kubevirt/kubevirt/releases/download/v0.22.0/virtctl-v0.22.0-linux-amd64

chmod +x kind kubectl virtctl

# https://kind.sigs.k8s.io/docs/user/quick-start#multi-node-clusters
[[ $(./kind get clusters) == kind ]] || ./kind create cluster --config cluster.yaml
export KUBECONFIG="$(./kind get kubeconfig-path --name="kind")"

export VER=v0.22.0
./kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$VER/kubevirt-operator.yaml ;
./kubectl create configmap -n kubevirt kubevirt-config --from-literal feature-gates="LiveMigration" || :
./kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$VER/kubevirt-cr.yaml ;

./kubectl wait --for=condition=Available -n kubevirt kubevirt kubevirt

sed -i "s/bridge/masquerade/" manifests/vm.yaml
./kubectl apply -f manifests/vm.yaml

./virtctl start testvm
# https://github.com/kubevirt/kubevirt/issues/2864
./kubectl wait --for=condition=Ready vmi testvm

./virtctl vnc testvm

./kubectl describe vmi testvm | grep "Node Name"
./virtctl migrate testvm
# oops
bash fix-product-uuid.sh
./virtctl stop testvm
./virtctl start testvm


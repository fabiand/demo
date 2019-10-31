
for WORKER in kind-worker kind-worker2; do
  docker exec $WORKER sh -c 'cat /proc/sys/kernel/random/uuid > /kind/product_uuid'
done

# sed -i -e "s/,PodPreset//" -e "/runtime-config/ d" /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec kind-control-plane sh -c 'sed -i \
  -e "s/NodeRestriction/NodeRestriction,PodPreset/" \
  -e "/NodeRestriction,PodPreset/ a\    - --runtime-config=settings.k8s.io/v1alpha1=true" \
  /etc/kubernetes/manifests/kube-apiserver.yaml'

kubectl apply -f -<<EOY
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: fix-node-uuid
spec:
  selector:
    matchLabels:
      kubevirt.io: virt-launcher
  volumeMounts:
    - mountPath: /sys/class/dmi/id/product_uuid
      name: fake-product-uuid
  volumes:
    - name: fake-product-uuid
      hostPath:
        path: /kind/product_uuid
        type: File
EOY

echo "Enabled workaround for non-unqiue product uuid. Please restart all VMs."


echo "Adding NVIDIA Runtime"
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/1.0.0-beta4/nvidia-device-plugin.yml
kubectl patch daemonset nvidia-device-plugin-daemonset --namespace kube-system \
  -p '{ "spec": { "template": { "spec": { "tolerations": [ { "operator": "Exists" } ] } } } }'

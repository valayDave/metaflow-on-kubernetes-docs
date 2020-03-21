# Will contain code to add GPU Nodes as an instance group to KOPS cluster

export AWS_PROFILE=metaflow_admin
# Keeping k8s.local as domain root ensure private DNS and No need for Public DNS. 
export DOMAIN_ROOT=k8s.local
export CLUSTER_NAME=metaflow.$DOMAIN_ROOT
export KOPS_BUCKET=$CLUSTER_NAME-test-store
export KOPS_STATE_STORE=s3://$KOPS_BUCKET

kops create -f gpu_setup/gpu_instance.yml
echo "Updating Cluster With GPU Nodes"
kops update cluster $CLUSTER_NAME --yes

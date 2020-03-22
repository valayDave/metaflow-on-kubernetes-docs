# $ Setup Kubecluster
export AWS_PROFILE=metaflow_admin
# Keeping k8s.local as domain root ensure private DNS and No need for Public DNS. 
export DOMAIN_ROOT=k8s.local
export CLUSTER_NAME=metaflow.$DOMAIN_ROOT
export KOPS_BUCKET=$CLUSTER_NAME-test-store
export KOPS_STATE_STORE=s3://$KOPS_BUCKET

kops delete secret --name $CLUSTER_NAME sshpublickey admin
kops create secret --name $CLUSTER_NAME sshpublickey admin -i ~/.ssh/id_rsa.pub
kops update cluster --yes # to reconfigure the auto-scaling groups
kops rolling-update cluster --name $CLUSTER_NAME --yes # to immediately roll all the machines so they have the new key (optional)
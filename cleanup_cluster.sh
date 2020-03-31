# This will run the Deleter scripts to download the data From DB and then run the delete cluster. 
export AWS_PROFILE=metaflow_admin
# Keeping k8s.local as domain root ensure private DNS and No need for Public DNS. 
export DOMAIN_ROOT=k8s.local
export CLUSTER_NAME=metaflow.$DOMAIN_ROOT
export KOPS_BUCKET=$CLUSTER_NAME-test-store
export KOPS_STATE_STORE=s3://$KOPS_BUCKET

sh Metaflow_service/deleter.sh
kubectl delete namespace metaflow-services
kubectl delete namespace metaflow-deployments
kops delete cluster $CLUSTER_NAME --yes
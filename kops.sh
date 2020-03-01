# $ Setup Kubecluster
export AWS_PROFILE=default
# Keeping k8s.local as domain root ensure private DNS and No need for Public DNS. 
export DOMAIN_ROOT=k8s.local
export CLUSTER_NAME=dev.$DOMAIN_ROOT
export KOPS_BUCKET=$CLUSTER_NAME-test-store
export KOPS_STATE_STORE=s3://$KOPS_BUCKET

aws s3api create-bucket \
    --bucket $KOPS_BUCKET \
    --region us-east-1

aws s3api put-bucket-versioning --bucket $KOPS_BUCKET  --versioning-configuration Status=Enabled

kops create cluster --zones=us-east-1c --dns private --master-size t2.micro --master-count 3 --node-size c4.xlarge --node-count 3 $CLUSTER_NAME

kops validate cluster $CLUSTER_NAME # Runs and CHecks the state of the Cluster. 

# $ DELETE CLUSTER COMPLETELY 
# kops delete cluster dev.k8s.local --yes

# $ Kubernetes Dashboard
kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.8.3.yaml 

kubectl create serviceaccount dashboard -n default

kubectl create clusterrolebinding dashboard-admin -n default \
--clusterrole=cluster-admin \
--serviceaccount=default:dashboard

# Gets u passworkl 
kops get secrets kube --type secret -oplaintext

# Get Dashboard URL
kubectl cluster-info | grep master # Provides info on where the Dashboard is . 

# Get the Loging token here which will be useful in the dashboard
kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/node?namespace=default


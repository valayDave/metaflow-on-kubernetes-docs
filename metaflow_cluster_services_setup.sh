# This script sets up the metaflow required services and permissions among namespaces on Clusters. 
export CLUSTER_NAME=metaflow.k8s.local # Your clustername comes here. 

# $ create the core namespaces. Two namespaces. One to hold main services around metaflow. One to do the deployments. 
kubectl apply -f metaflow-cluster-core-namespaces.yml

# $ Create configuration around each namespace.  
kubectl config set-context metaflow-deployments --namespace=metaflow-deployments --cluster=$CLUSTER_NAME --user=$CLUSTER_NAME
kubectl config set-context metaflow-services --namespace=metaflow-services --cluster=$CLUSTER_NAME --user=$CLUSTER_NAME

# $ Create the services inside the `metaflow-services` namespace. This is done so that we can easily bifuracte the jobs between namespaces. 
kubectl config use-context metaflow-services
sh Metaflow_service/runner.sh

# $ Add a cluster role to allow orchestration of containers within the cluster for metaflow. This role is applied to `metaflow-deployments` namespace. 
kubectl apply -f metaflow-native-cluster-role.yml
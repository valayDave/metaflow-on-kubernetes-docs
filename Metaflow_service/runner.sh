SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
kubectl create -f $SCRIPTPATH/postgres-secret.yaml

# $ Create the PG Db in the Kube Cluster. 
kubectl apply -f $SCRIPTPATH/database/postgres-db-pv.yaml
kubectl apply -f $SCRIPTPATH/database/postgres-db-pvc.yaml
kubectl apply -f $SCRIPTPATH/database/postgres-db-deployment.yaml
kubectl apply -f $SCRIPTPATH/database/postgres-db-service.yaml

# Restore Database from previously stored backup so that vital information is not lost
sh $SCRIPTPATH/postgres-restore.sh

# $ Create the service once the app is created. 
kubectl apply -f $SCRIPTPATH/service_app/metaflow-metadata-service-deployment.yaml
kubectl apply -f $SCRIPTPATH/service_app/metaflow-metadata-service.yaml
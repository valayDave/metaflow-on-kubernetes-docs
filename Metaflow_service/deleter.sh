# SCRIPT=`realpath $0`
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

echo "Backing Up Postgre Database From Server"
sh $SCRIPTPATH/postgres-backup.sh
kubectl delete -f $SCRIPTPATH/postgres-secret.yaml

# $ Create the PG Db in the Kube Cluster. 
kubectl delete -f $SCRIPTPATH/database/postgres-db-deployment.yaml
kubectl delete -f $SCRIPTPATH/database/postgres-db-service.yaml
kubectl delete -f $SCRIPTPATH/database/postgres-db-pvc.yaml
kubectl delete -f $SCRIPTPATH/database/postgres-db-pv.yaml

# $ Create the service once the app is created. 
kubectl delete -f $SCRIPTPATH/service_app/metaflow-metadata-service-deployment.yaml
kubectl delete -f $SCRIPTPATH/service_app/metaflow-metadata-service.yaml
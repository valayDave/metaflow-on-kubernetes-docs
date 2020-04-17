# User and Database are currently set according to the Metaflow_service/postgres-secret.yaml
echo "Trying To Restore Latest Database"
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DATABASE_USER=metaflow_service
DATABASE=metaflow
DATBASE_LOCAL_PATH=$SCRIPTPATH/Local_imports/pg_dump_backup.sqlc

if [ ! -f "$DATBASE_LOCAL_PATH" ]; then
    echo "$DATBASE_LOCAL_PATH does not exist"
    exit
fi
FINAL_POD_PATH=/tmp/pg_dump_backup.sqlc
kubectl config use-context metaflow-services
DATABASE_POD=$(kubectl get pod -l app=metaflow-database -o jsonpath="{.items[0].metadata.name}")
echo "Copying Database To Pod"
kubectl cp $DATBASE_LOCAL_PATH $DATABASE_POD:$FINAL_POD_PATH

echo "Uploading Database From Local"
kubectl exec $DATABASE_POD -- bash -c "psql -U $DATABASE_USER template1 -c 'drop database $DATABASE;'"
kubectl exec $DATABASE_POD -- bash -c  "psql -U $DATABASE_USER template1 -c 'create database $DATABASE;'"
kubectl exec $DATABASE_POD -- bash -c "pg_restore -C --clean --no-acl --no-owner -U $DATABASE_USER -d $DATABASE < $FINAL_POD_PATH"
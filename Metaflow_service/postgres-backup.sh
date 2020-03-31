# User and Database are currently set according to the Metaflow_service/postgres-secret.yaml
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DATABASE_USER=metaflow_service
DATABASE=metaflow
kubectl config use-context metaflow-services 
DATABASE_POD=$(kubectl get pod -l app=metaflow-database -o jsonpath="{.items[0].metadata.name}")

echo "Backing Up Database on Pod"
kubectl exec $DATABASE_POD -- bash -c "pg_dump -U $DATABASE_USER --format=c --file=pg_dump_backup.sqlc $DATABASE"
echo "Downloading Database to Local"
IMPORT_TIMESTAMP=$(date '+%d-%m-%Y-%H%M%S')
echo "Downloaded Latest Backup On $IMPORT_TIMESTAMP" > $SCRIPTPATH/Local_imports/backup_info.txt
kubectl cp $DATABASE_POD:pg_dump_backup.sqlc $SCRIPTPATH/Local_imports/pg_dump_backup_$IMPORT_TIMESTAMP.sqlc
mv $SCRIPTPATH/Local_imports/pg_dump_backup_$IMPORT_TIMESTAMP.sqlc $SCRIPTPATH/Local_imports/pg_dump_backup.sqlc
kubectl delete -f postgres-secret.yaml

# $ Create the PG Db in the Kube Cluster. 
kubectl delete -f database/postgres-db-pv.yaml
kubectl delete -f database/postgres-db-pvc.yaml
kubectl delete -f database/postgres-db-deployment.yaml
kubectl delete -f database/postgres-db-service.yaml

# $ Create the service once the app is created. 
kubectl delete -f service_app/metaflow-metadata-service-deployment.yaml
kubectl delete -f service_app/metaflow-metadata-service.yaml
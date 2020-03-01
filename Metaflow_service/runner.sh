kubectl create -f postgres-secret.yaml

# $ Create the PG Db in the Kube Cluster. 
kubectl apply -f database/postgres-db-pv.yaml
kubectl apply -f database/postgres-db-pvc.yaml
kubectl apply -f database/postgres-db-deployment.yaml
kubectl apply -f database/postgres-db-service.yaml

# $ Create the service once the app is created. 
kubectl apply -f service_app/metaflow-metadata-service-deployment.yaml
kubectl apply -f service_app/metaflow-metadata-service.yaml
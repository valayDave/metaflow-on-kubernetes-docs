# Metaflow Service

- Creates the Pods and Services for the Metaflow metadata service. 
- Setups: 
    - Postgres : Service, Deployment, Persistant Volume and Persistant Volume Claim
    - Metaflow_Service : Deployment,service 
- `runner.sh` will create the neccesary Pods/Services on kubernetes for Metaflow Service and its Postgres DB
- To change secrets, Change the `postgres-secret.yml`
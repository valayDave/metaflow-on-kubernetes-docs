# Metaflow on Kubernetes

This Repository will contain the basic scripts and files needed to setup Kubernetes cluster for running and working with Metaflow. 
It contains Kops setup and Kubernetes templates to deploy necessary services on kubernetes. 

# Kops Guide. 

## Admin Guide 
This Involves the steps the admin needs to take to Setup cluster and some useful commands that will help maintain things around the cluster. 

- Setup Cluster 
    ```sh
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
    # Ensure private DNS so that this can be done quickly with too much route53 setup. 
    # This will only setup cluster spec. To actually Launch it the command needs to run with ``--yes``
    kops create cluster --zones=us-east-1c --dns private --master-size t2.micro --master-count 3 --node-size c4.xlarge --node-count 3 $CLUSTER_NAME
    ```
- Wait for cluster initialisation to finish. Check via ``kops validate cluster $CLUSTER_NAME``

- To update the Number of instance in the worker nodes run : ``kops edit ig nodes``. This will show the configuration for Instance Group named `nodes`. We can create different instance groups that will be essential for the different purposes. This is how an instance group configuration looks like.
    ```yml
    apiVersion: kops.k8s.io/v1alpha2
    kind: InstanceGroup
    metadata:
    creationTimestamp: "2020-02-28T09:47:43Z"
    generation: 1
    labels:
        kops.k8s.io/cluster: dev.k8s.local
    name: nodes
    spec:
    image: kope.io/k8s-1.15-debian-stretch-amd64-hvm-ebs-2020-01-17
    machineType: c4.xlarge
    maxSize: 4 # change here to deploy more instances
    minSize: 4 # change here to deploy more instances
    nodeLabels:
        kops.k8s.io/instancegroup: nodes
    role: Node
    subnets:
    - us-east-1c
    ```
- run : ``kops update cluster $CLUSTER_NAME --yes``

## User Guide

This involves using AWS Creds to set environment variables that give access to a bucket from which the `kubecfg` can be retrieved.

- Steps:
    1. install kops, kubectl on your CI server.
    2. config the AWS access credential on your CI server (either via IAM Role or simply env vars), make sure it has access to your s3 state store path.
    3. set env var for kops to access your cluster:
    ```sh
    export NAME=${YOUR_CLUSTER_NAME}
    export KOPS_STATE_STORE=s3://${YOUR_CLUSTER_KOPS_STATE_STORE}
    ```
    4. Use kops export command to get the kubecfg needed for running kubectl
    ``kops export kubecfg ${YOUR_CLUSTER_NAME}``
        - see https://github.com/kubernetes/kops/blob/master/docs/cli/kops_export.md

    5. Now the ~/.kube/config file on your CI server should contain all the information kubectl needs to access your cluster.


# `Metaflow_service` 

- This contains the neccessary kube configurations to setup the metaflow environment. 
- `runner.sh` will create the neccesary Pods/Services on kubernetes for Metaflow Service and its Postgres DB
- To change secrets, Change the `postgres-secret.yml`

# Deploying Metaflow Job into Kubernetes

- Requirements:
    - Create a Dockerfile which will build your metaflow Flow into an image
        ```dockerfile
        # this is an example Docker file of how to create and image of the Metaflow Run and Put it on Kubernetes. 
        FROM python:3.7

        RUN pip install https://github.com/valayDave/metaflow/archive/kube_cpu_stable.zip
        RUN pip install numpy

        WORKDIR /app

        COPY ./data /app/data
        COPY ./multi_step_mnist.py /app/multi_step_mnist.py

        ENTRYPOINT [ "python",'/app/multi_step_mnist.py']
        ``` 
    - Build image of the repo : `docker build -t "<dockerhubid>/<image_name>:<tag>" .`
    - Push to docker Hub : `docker push <dockerhubid>/<image_name>:<tag>`     

- ``kubectl create -f metaflow-native-cluster-role.yml`` : this will allocate the a cluster role to allow deployments from within a cluster. 
- Sample Deployment file : 
    ```yml
    apiVersion: batch/v1
    kind: Job
    metadata:
    name: metaflow-native-runtime-job-test
    spec:
    template:
        spec:
        containers:
            - name: metaflow-native-runtime
            image: valaygaurang/metaflow:multi_step_mnist_example-in-cluster # Image of the Metaflow Run. 
            args:
                [
                "--with",
                "kube:cpu=2,memory=2000,image=tensorflow/tensorflow:latest-py3",
                "run",
                "--num_training_examples",
                "40000",
                ]
            env:
                - name: AWS_ACCESS_KEY_ID
                value: <ACCESS_TOKEN_COMES_HERE>
                - name: AWS_SECRET_ACCESS_KEY
                value: <SECRET_VALUE_COMES_HERE>
                - name: AWS_DEFAULT_REGION
                value: <AWS_REGION_COMES_HERE>
                - name: METAFLOW_SERVICE_URL
                value: http://metaflow-metadata-service.default.svc.cluster.local/ # $ This is what is set in the Metaflow_service/service_app/metaflow-metadata-service-deployment.yaml
                - name: METAFLOW_DEFAULT_METADATA
                value: service
                - name: METAFLOW_DATASTORE_SYSROOT_S3
                value: s3://<S3_ROOT>
                - name: METAFLOW_DATATOOLS_SYSROOT_S3
                value: s3://<S3_ROOT>data
                - name: METAFLOW_DEFAULT_DATASTORE
                value: s3
                - name: USERNAME
                value: <USERNAME> 
                - name: METAFLOW_RUNTIME_IN_CLUSTER # Important Environment variable to make it run with a Kube Cluster. 
                value: 'yes'
        restartPolicy: Never
    backoffLimit: 4
    ```
- Deploy the job using : ``kubectl create -f metaflow-job-runner.yml``
- Once Done Executing : 
    - Once the``kubectl port-forward deployment/metaflow-metadata-service 8080:8080`` to port forward metatdata service for accesss on localmachine. Please note that because this is directly port forwarding to the pod were are taking the 8080 port for the service. 

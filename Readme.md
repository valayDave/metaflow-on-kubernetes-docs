# Metaflow on Kubernetes

This Repository will contain the basic scripts and files needed to setup Kubernetes cluster for running and working with Metaflow. 
It contains Kops setup and Kubernetes templates to deploy necessary services on kubernetes. 

# Metaflow Kubernetes Plugin

## Installing Plugin Metaflow Repo
- ``pip install https://github.com/valayDave/metaflow/archive/kube_cpu_stable.zip``


## Using The Plugin 
- Usage is very similar to `@batch` decorator. 
- on top of any `@step` add the `@kube` decorator or use `--with kube:cpu=2,memory=4000,image=python:3.7` in the CLI args. 
- To directly deploy the entire runtime into Kubernetes as a job, using the `kube-deploy run` command: 
    -  ``python multi_step_mnist.py --with kube:cpu=3.2,memory=4000,image=tensorflow/tensorflow:latest-py3 kube-deploy run --num_training_examples 1000 --dont-exit``
    - ``--dont-exit`` will follow log trail from the job. Otherwise the workflow will be deployed as a job on Kubernetes which will destroy itself once it ends. 
    - ***Directly deploy to kubernetes only works with Service based Metaprovider***
    - Good practice before directly moving to `kube-deploy` would be: 
        - Local tests : ``python multi_step_mnist.py run --num_training_examples 1000`` : With or without Conda. 
        - Dry run with ``python multi_step_mnist.py --with kube:cpu=3.2,memory=4000,image=tensorflow/tensorflow:latest-py3 run --num_training_examples 1000``
        - On successful dry run : ``python multi_step_mnist.py --with kube:cpu=3.2,memory=4000,image=tensorflow/tensorflow:latest-py3 kube-deploy run --num_training_examples 50000`` : Run Larger Dataset. 

### Running with Conda 
- To run with Conda it will need `'python-kubernetes':'10.0.1'` in the libraries argument to `@conda_base` step decorator
- Use `image=python:3.6` when running with Conda in `--with kube:`. Ideally that should be the python version used/mentioned in conda.  
- Direct deploy to kubernetes with Conda environment is supported 
    - ``python multi_step_mnist.py --with kube:cpu=3.2,memory=4000,image=python:3.6 --environment=conda kube-deploy run --num_training_examples 1000 --dont-exit``
    - Ensure to use `image=python:<conda_python_version>`

### Small Example Flow 
```python
from metaflow import FlowSpec, step,kube
class HelloKubeFlow(FlowSpec):
    
    @step
    def start(self):
        print("running Next Step on Kube")
        self.next(self.kube_step)
    
    @kube(cpu=1,memory=2000)
    @step
    def kube_step(self):
        print("Hello I am Running within a container")
        self.next(self.end)
    
    @step
    def end(self):
        print("Done Computation")

if __name__== '__main__':
    HelloKubeFlow()
```
- Try it with Minikube.  

## CLI Operations Available with Kube: 
- ``python multi_step_mnist.py kube list`` : Show the currently running jobs of flow. 
- ``python multi_step_mnist.py kube kill`` : Kills all jobs on Kube. Any Metaflow Runtime accessing those jobs will be gracefully exited. 
- ``python multi_step_mnist.py kube-deploy run`` : Will run the Metaflow Runtime inside a container on kubernetes cluster. Needs metadata service to work.  
- ``python multi_step_mnist.py kube-deploy list`` : It will list any running deployment of the current flow on Kubernetes. 


# Kops Guide For Cluster Setup / Connection

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
    # Ensure private DNS so that this can be done quickly without too much route53 setup. 
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

- Setup Services Around Metaflow Using : `sh metaflow_cluster_services_setup.sh`. It set's up : 
    - `metaflow-services` : Namespace where metaflow related services like DB and Metadataprovider are deployed. 
    - `metaflow-deployments`: Namespace where containers pertaining to metaflow steps/flows will be deployed. Has a cluster has a role set via `metaflow-native-cluster-role.yml` which allow containers to orchestrate other containers within the cluster. 
    - Seperate namespaces ensure efficient clearing of pods/jobs/services within deployments without affecting metaflow-services

### GPU Support 
- GPU Support Documentation Available [Here](gpu.md)
- GPU Cluster Constraints : 
    - Cuda Libraries v9.1 on Individual Machines
    - Docker 18.x on Machine
    - Kubernetes Version 1.15.x, 1.16.x 

## User Guide

This involves using AWS Creds to set environment variables that give access to a bucket from which the `kubecfg` can be retrieved.

Steps:
1. install kops, kubectl on your machine.
2. 2. Configure the AWS access credentials on your machine using awscli. `aws configure` will give a cli to add AWS creds.
3. Set env var for Kops to access your cluster: 
```sh
export DOMAIN_ROOT=k8s.local
export CLUSTER_NAME=dev.$DOMAIN_ROOT
export KOPS_BUCKET=$CLUSTER_NAME-test-store
export KOPS_STATE_STORE=s3://$KOPS_BUCKET
export NAME=${CLUSTER_NAME}
export KOPS_STATE_STORE=s3://${YOUR_CLUSTER_KOPS_STATE_STORE}
```
4. Use kops export command to get the kubecfg needed for running kubectl
``kops export kubecfg ${YOUR_CLUSTER_NAME}``
    - see https://github.com/kubernetes/kops/blob/master/docs/cli/kops_export.md

5. Now the ~/.kube/config file on your machine should contain all the information kubectl needs to access your cluster.



# Deploying Metaflow Job into Kubernetes

- ``kubectl create -f metaflow-native-cluster-role.yml`` : this will allocate the a cluster role to allow deployments from within a cluster. 

- Example Metaflow Config for using `kube-deloy run` with cluster and services created from above steps. The url in examples is derived from [service deployment](Metaflow_service/service_app/metaflow-metadata-service.yaml)
    ```json
    {
        "METAFLOW_BATCH_CONTAINER_IMAGE":"python:x.y",
        "METAFLOW_DATASTORE_SYSROOT_S3": "s3://<S3_BUCKET_URL>",
        "METAFLOW_DATATOOLS_SYSROOT_S3": "s3://<S3_BUCKET_URL>/data",
        "METAFLOW_DEFAULT_DATASTORE": "s3",
        "METAFLOW_DEFAULT_METADATA": "service",
        "METAFLOW_SERVICE_URL" : "http://metaflow-metadata-service.metaflow-services.svc.cluster.local/",
        "METAFLOW_KUBE_NAMESPACE":"metaflow-deployments",
        "METAFLOW_KUBE_SERVICE_ACCOUNT": "metaflow-deployment-service-account",
        "AWS_ACCESS_KEY_ID": "<YOUR_KEY_COMES_HERE>",
        "AWS_SECRET_ACCESS_KEY":"<YOUR_SECRET_KEY_COMES_HERE>",
        "AWS_DEFAULT_REGION" :"us-west-2"
    }
    ```
- To import this config and use it will your deployment run `metaflow configure import new_config.json`
- The plugin supports deploying a Metaflow-runtime into kubernetes using the `kube-deploy run` command. Check usage example [here](https://github.com/valayDave/metaflow-kube-demo).

- Once Done Executing : 
    - Once the ``kubectl port-forward deployment/metaflow-metadata-service 8080:8080`` to port forward metatdata service for accesss on localmachine. Please note that because this is directly port forwarding to the pod were are taking the 8080 port for the service. 


# TODO 

- [ ] Integrate Minio Helm chart to this. 
- 
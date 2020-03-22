# GPU Supporting Cluster of Kubernetes with KOPS for Metaflow

## Setting Up the GPU Cluster Nodes
- Running ``sh kops_gpu_setup.sh`` will add GPU Instances to the Cluster. 
- Wait for Nodes to become part of cluster.
- Running ``sh gpu_setup/nvidia_one_time_setup.sh`` will add the NVIDIA Deamonset as a part of Kube Systems. 
- Validate GPUS are Working : ``kubectl create -f gpu_setup/tf_pod.yml``
- You need to wait for sometime. The Plugin takes time to load and start scheduling. 
```python
# Check that nodes are detected to have GPUs
kubectl describe nodes|grep -E 'gpu:\s.*[1-9]'

# Check the logs of the Tensorflow Container to ensure that it ran
kubectl logs tf-gpu

# Show GPU info from within the pod
#   Only works in DevicePlugin mode
kubectl exec -it tf-gpu nvidia-smi

# Show Tensorflow detects GPUs from within the pod.
#   Only works in DevicePlugin mode
kubectl exec -it tf-gpu -- \
  python -c 'from tensorflow.python.client import device_lib; print(device_lib.list_local_devices())'
```

## Specs
- Kops using the [gpu_setup/gpu_instance.yml](gpu_setup/gpu_instance.yml) file to Configure the GPU Instances on AWS joininig the Cluster.
    - Constraints : 
        - Cuda Libraries v9.1
        - Docker 18.x on Machine
        - Kubernetes Version 1.15.x, 1.16.x

- NO CUDA 10.2 Support :  
  - KOPS Currently Only Support Kubernetes v1.16
    - K8s v1.16  which uses Docker v18.03. 
  - K8s v1.17 Support Docker 19.03. 
    - [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker#quickstart) Requires Docker 19.03 and supports CUDA 10.2.
    - The Older version of this was [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(version-2.0)) which supported Docker 18.03 and 19.03 
  - KOPS Supports NVIDIA-Device-Plugin deployments with [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(version-2.0)) and hence currently has ongoing issues on support for New CUDA Versions. 
  - KOPS Needs to move to v1.17 of kubernetes to start quick deployments Kubernetes versions which can support Docker 19.03 which inturn will support Latest Nvidia CUDA Toolkit. 

## Cleanup Tasks

### Delete GPU Instance 
```sh
kops delete ig gpu-nodes
```


## TODO 
- [ ] Test the Base AMI for KOPS deployment with NVIDIA Provided AMI. 
    - [ ] Test Cuda Support for v9.1 , v9.2

## References 
- https://docs.nvidia.com/datacenter/kubernetes/kubernetes-upstream/index.html
- https://github.com/NVIDIA/deepops/blob/master/docs/kubernetes-cluster.md
- https://docs.nvidia.com/ngc/ngc-ami-release-notes/index.html
- https://medium.com/@RouYunPan/how-to-use-tensorflow-gpu-with-docker-2b72f784fdf3
- https://github.com/kubernetes/kops/tree/master/hooks/nvidia-device-plugin
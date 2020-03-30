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
    - Tested ON : 
      - Kubernetes Version 1.15.x, 1.16.x
        
- Cuda Libraries v10.2. [Credits](https://github.com/elevate/nvidia-device-plugin)

- To use Cuda 9.1 change the below in [gpu_setup/gpu_instance.yml](gpu_setup/gpu_instance.yml)

```yml
  hooks:
    - execContainer:
        image: dcwangmit01/nvidia-device-plugin:0.1.0
```

## Cleanup Tasks

### Delete GPU Instance 
```sh
kops delete ig gpu-nodes
```


## TODO 
- [x] Test Cuda Support for v10.2, 9.1


## References 
- https://docs.nvidia.com/datacenter/kubernetes/kubernetes-upstream/index.html
- https://github.com/NVIDIA/deepops/blob/master/docs/kubernetes-cluster.md
- https://docs.nvidia.com/ngc/ngc-ami-release-notes/index.html
- https://medium.com/@RouYunPan/how-to-use-tensorflow-gpu-with-docker-2b72f784fdf3
- https://github.com/kubernetes/kops/tree/master/hooks/nvidia-device-plugin

## Sample application 1 POD + 1 PV
Sample application with a POD (running debian 9) and a 5Gb PERSISTENT VOLUME. 

1. Create the namespace and pod:
```console
kubectl apply -f pod-test-pv.yaml
```

2. Create the persistent volume claim:
```console
kubectl apply -f pvc-test-pv.yaml
```

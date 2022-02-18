### How to install a TLS certificate from .pfx file

````diff
!! N.B Before install the new secret, is recommended to delete the previous secret used. !!
````
1. Extract the .key file from the .pfx file:
```console
openssl pkcs12 -in pfx-filename.pfx -nocerts -out key-filename-encrypted.key
```

2. Decrypt the .key file:
```console
openssl rsa -in key-filename.key -out key-filename-decrypted.key
```

3. Extract the .crt file from .pfx file:
```console
openssl pkcs12 -in pfx-filename.pfx -clcerts -nokeys -out crt-filename.crt
```

4. Create a secret in your Kubernetes cluster:
```console
kubectl create secret tls <your-secret-name> --cert crt-filename.crt --key key-filename-decrypted.key -n <namespace>
```

5. Verify that your new secret exists in your clusters namespace:
```console
kubectl get secret -n your-namespace
```

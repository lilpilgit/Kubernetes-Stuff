#!/bin/bash
#replace devuser with the name of the user to create
#automatically create a config for the user created from a config template
#Use for example the admin config as template.
echo + Creating private key: devuser.key
openssl genrsa -out devuser.key 4096

echo + Creating signing request: devuser.csr
openssl req -new -key devuser.key -out devuser.csr -subj '/CN=devuser/O=dev'

cp signing-request-template.yaml devuser-signing-request.yaml
sed -i "s@__USERNAME__@devuser@" devuser-signing-request.yaml

B64=`cat devuser.csr | base64 | tr -d '\n'`
sed -i "s@__CSRREQUEST__@${B64}@" devuser-signing-request.yaml

echo + Creating signing request in kubernetes
kubectl.exe create -f devuser-signing-request.yaml

echo + List of signing requests
kubectl.exe get csr

kubectl.exe certificate approve devuser-csr

KEY=`cat devuser.key | base64 | tr -d '\n'`
CERT=`kubectl.exe get csr devuser-csr -o jsonpath='{.status.certificate}'`

echo "======KEY"
echo ${KEY}
echo

echo "======Cert"
echo $CERT
echo

echo "======Config"
sed -i -r "s/^(\s*)(client-certificate-data:.*$)/\1client-certificate-data: ${CERT}/" config
sed -i -r "s/^(\s*)(client-key-data:.*$)/\1client-key-data: ${KEY}/" config
echo

echo "======Cluster role binding applying..."
kubectl.exe apply -f clusterrolebindings.yaml

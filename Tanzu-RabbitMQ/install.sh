#!/bin/bash

shopt -s expand_aliases

# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

{
    export BROKER_NAMESPACE=9204-q-broker
    export OPERATORS_NAMESPACE=rabbitmq-system
    export PFX_FILE=<NOME-FILE.pfx>
    export KUBECONFIG=/root/.kube/config_noprod # <----------------------------- DA CONFIGURARE
    export SNAM_CA_FILE=snam-ca.pem
    export LOG_FILENAME="log-tanzu-rabbitmq-noprod.txt"


    printf "\n\n================================== Env variables ==================================\n\n"
    echo "KUBECONFIG: ${KUBECONFIG}"
    echo "Namespace broker server: ${BROKER_NAMESPACE}";
    echo "Namespace operators: ${OPERATORS_NAMESPACE}"
    echo "File PFX rilasciato da SNAM: ${PFX_FILE}"
    echo "Certificato della CA Snam (per Shovel): ${SNAM_CA_FILE}"
    printf "=======================================================================================\n\n"

    #Controllo se l'utente corrente è root
    if [ $EUID -ne 0 ]; then
        echo "This script should be run as root." > /dev/stderr
        exit 1
    fi


    while true; do
        read -r -p "Are the variables correct? (Yy/Nn): " answer
        case $answer in
            [Yy]* ) break;;
            [Nn]* ) exit 1;;
            * ) echo "Please answer Y or N.";;
        esac
    done

    ##Installazione di kubectl
    printf "\n\n(+) Installation of kubectl...\n\n"
    #download del binario
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    #Download del checksum
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    #Validazione del binario
    echo "$(<kubectl.sha256)  kubectl" | sha256sum --check
    #installazione
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    #verifica della installazione
    kubectl version --client
    printf "\n\n================= Done =================\n\n"

    #Installazione di carvel. Lo script di installazione presente al seguente link sulla documentazione ufficiale https://carvel.dev/install.sh è stato modificato
    #così da poter bypassare il controllo del certificato, causa proxy
    printf "\n\n(+) Installation of Carvel...\n\n"
    ./carvel.sh
    printf "\n\n================= Done =================\n\n"

    #Installazione di kapp-controller
    printf "\n\n(+) Installation of kapp-controller...\n\n"
    kapp deploy -a kc -f "kapp-deployment.yaml" -y # <------------------ modificare la configurazione delle variabili di ambiente del proxy nello yaml
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Installazione di helm (viene installata la versione 3.6.3 in quanto sarà utile anche per il connected registry)
    printf "\n\n(+) Installation of helm 3.6.3-1\n\n"
    curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm=3.6.3-1 #versione esatta per l'installazione dell'azure connected registry
    printf "\n\n================= Done =================\n\n"

    #Installazione di cert-manager
    printf "\n\n(+) Installation of cert-manager\n\n"
    kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install cert-manager jetstack/cert-manager --namespace cert-manager  --version 1.7 --set installCRDs=true
    #kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml"
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Installazione di secretgen-controller
    printf "\n\n(+) Installation of secretgen-controller...\n\n"
    kapp deploy -a sg -f "https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/latest/download/release.yml" -y
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Creazione del namespace per l'operator
    printf "\n\n(+) Creation of namespace ${OPERATORS_NAMESPACE}...\n\n" 
    kubectl create namespace ${OPERATORS_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Creazione del namespace per il broker server
    printf "\n\n(+) Creation of namespace ${BROKER_NAMESPACE}...\n\n"
    kubectl create namespace ${BROKER_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Deploy del secret per fare l'image pull
    printf "\n\n(+) Deploy imagepull secret...\n\n"
    kubectl apply -f "tanzu-imagepull-secret.yaml"
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Deploy del package repository
    printf "\n\n(+) Deploy package repository...\n\n"
    kapp deploy -a tanzu-rabbitmq-repo -f "package-repository.yaml" -y
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Controllo dei package appena installati
    printf "\n\n(+) Get installed packages...\n\n"
    kubectl get packages -A
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Deploy del service account necessario all'installazione del package
    printf "\n\n(+) Deploy service account...\n\n"
    kubectl apply -f "service-account-package.yaml"
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Installazione del package
    printf "\n\n(+) Install package repository...\n\n"
    kapp deploy -a tanzu-rabbitmq -f "package-install.yaml" -y
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Deploy di una storage class non root
    printf "\n\n(+) Install storage class non root...\n\n"
    kubectl apply -f "storageclass-default-non-root.yaml"   # <------------------------ DA CONFIGURARE LO yaml
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Deploy del secret per fare l'image pull del broker server che verrà popolato in automatico da secretgen controller
    printf "\n\n(+) Install image pull secret to deploy broker server...\n\n"
    kubectl apply -f "tanzu-imagepull-secret-server.yaml"
    sleep 5
    printf "\n\n================= Done =================\n\n"

    ## Installazione del certificato TLS a partire dal file .pfx rilasciato da SNAM
    printf "\n\n(+) Installing TLS secret for secure connections of broker server...\n\n"
    openssl pkcs12 -in ${PFX_FILE} -nocerts -out tls-key-encrypted.key
    openssl rsa -in tls-key-encrypted.key -out tls-key-decrypted.key
    openssl pkcs12 -in ${PFX_FILE} -clcerts -nokeys -out ca.crt
    kubectl create secret tls tanzu-tls-secret --cert ca.crt --key tls-key-decrypted.key -n ${BROKER_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    kubectl create configmap snam-ca --from-file=${SNAM_CA_FILE} -n ${BROKER_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f - #config map contenente la CA di Snam da installare nel path dei certificati trusted
    kubectl get secret -n ${BROKER_NAMESPACE}
    sleep 5
    printf "\n\n================= Done =================\n\n"

    #Configurazione del TLS per il Messaging Topology Operator
    printf "\n\n(+) Installing CA secret for secure connections of Messaging Topology Operator...\n\n"
    kubectl -n ${OPERATORS_NAMESPACE} create secret generic tanzu-ca --from-file=./ca.crt --dry-run=client -o yaml | kubectl apply -f -
    sleep 5
    kubectl -n ${OPERATORS_NAMESPACE} patch deployment messaging-topology-operator --patch "spec:
      template:
        spec:
          containers:
          - name: manager
            volumeMounts:
            - mountPath: /etc/ssl/certs/tanzu-ca.crt
              name: tanzu-ca
              subPath: ca.crt
          volumes:
          - name: tanzu-ca
            secret:
              defaultMode: 420
              secretName: tanzu-ca"
    sleep 60
    printf "\n\n================= Done =================\n\n"
    
    #Installazione del broker server
    printf "\n\n(+) Installing broker server...\n\n"
    kubectl apply -f "broker-server.yaml"
    sleep 60
    printf "\n\n================= Done =================\n\n"

    #Print dell'utente di default
    printf "\n\n(i) Default user:\n\n"
    echo "Username: $(kubectl get secret broker-default-user -o jsonpath='{.data.username}' -n ${BROKER_NAMESPACE} | base64 --decode)"
    echo "Password: $(kubectl get secret broker-default-user -o jsonpath='{.data.password}' -n ${BROKER_NAMESPACE} | base64 --decode)" 
    printf "\n\n========================================\n\n"

    #Creazione dell'utente admin
    printf "\n\n(+) Deploy admin user:\n\n"
    kubectl apply -f "admin-user.yaml"
    sleep 5
    printf "\n\n================= Done =================\n\n"


} | tee ${LOG_FILENAME}
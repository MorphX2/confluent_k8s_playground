#!/bin/bash

KUBENAMESPACES=$(kubectl get namespaces)
NAMESPACE=javaproducers

docker build -t kafkajavaproducer:latest .

if ! echo ${KUBENAMESPACES} | grep -q "${NAMESPACE}"; then
    echo "Creating $NAMESPACE namespace"
    kubecutl create namespace $NAMESPACE
else
    echo "$NAMESPACE already exist"
fi

echo "Performing helm upgrade/install"
helm upgrade --install java-producer helm_charts/ --namespace $NAMESPACE


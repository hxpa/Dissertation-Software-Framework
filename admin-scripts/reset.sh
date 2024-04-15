#!/bin/bash
# Script to delete the admin cluster and resources
# Author: Huthayfa Patel

## FUNCTIONS

# Outputs dashed line in terminal
line_break() {
    echo "--------------------------------------------------"
}

# Outputs empty line in terminal
empty_break() {
    echo "$1"
    echo
}

# Removes Kubecost
uninstall_kubecost() {
    line_break
    empty_break "Stopping Kubecost..."
    helm uninstall kubecost -n "kubecost"
    kubectl delete ns "kubecost"
    empty_break "Kubecost has been stopped"
}

# Stops and deletes Minikube cluster
stop_minikube() {
    line_break
    empty_break "Stopping Minikube..."
    minikube stop
    minikube delete
    empty_break "Minikube has been stopped and deleted"
}

## MAIN

line_break
empty_break "Resetting admin cluster.."
kubectl delete ns "dissertation" # Deletes dissertation namespace
uninstall_kubecost && stop_minikube # Run functions

line_break
empty_break "Admin cluster reset"


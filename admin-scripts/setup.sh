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

# Creates a kubernetes namespace
create_namespace() {
    local namespace="$1" # Takes input (name of namespace)
    # Checks if namespace already exists
    # If so, skip
    # If not, create
    if kubectl get namespace "$namespace" &>/dev/null; then
        line_break
        empty_break "$namespace namespace already exists"
    else
        line_break
        empty_break "Creating $namespace namespace..."
        kubectl create namespace "$namespace"
        empty_break "$namespace namespace created"
    fi
}

# Starts local Minikube cluster
start_minikube() {
    # Checks if Minikube is already running
    # If so, skip
    # If not, start
    if minikube status &>/dev/null; then
        line_break
        empty_break "Minikube is already running"
    else
        line_break
        empty_break "Starting Minikube..."
        minikube start --cpus 4 --memory 4000mb
        minikube addons enable metrics-server # for kubecost
        empty_break "Minikube is now running"
    fi
}

# Creates Kubecost deployment on Minikube cluster
start_kubecost() {
    local namespace="kubecost" # Sets namespace as Kubecost

    create_namespace $namespace # Creates Kubecost namespace

    # Checks if Kubecost is already running
    # If so, skip
    # If not, create and start 
    if helm list -n $namespace | grep -q "kubecost"; then
        line_break
        empty_break "Kubecost is already running"
    else
        line_break
        empty_break "Starting Kubecost..."
        helm install kubecost cost-analyzer \
        --repo https://kubecost.github.io/cost-analyzer/ \
        --namespace kubecost --create-namespace \
        --set kubecostToken="czQwMDQ2MzBAZ2xvcy5hYy51aw==xm343yadf98" \
        --set kubecostProductConfigs.currencyCode=GBP
        sleep 100 # Delay for pods to deploy
        kubectl port-forward --namespace kubecost deployment/kubecost-cost-analyzer 9090 & # Port forward to access in local browser
        empty_break "Kubecost is now running"
    fi
}

# Displays port forwaded URLs in terminal
url() {
    local name="$1" # Takes input (name of app)
    local url="$2" # Takes input (app URL)

    # Commands to run if Minikube
    if [ "$name" == "Minikube" ]; then 
        minikube dashboard --url &
        sleep 60 # Delay for dashboard to deploy
        line_break
    # Commands to run for Kubecost
    else
        line_break
        empty_break "$name URL: $url"
    fi
}

## MAIN

line_break
empty_break "Setting up admin cluster..."
start_minikube && start_kubecost # Run functions
create_namespace dissertation # Run function with dissertation as input
line_break

url "Minikube" # Run function with Minikube as input
url "Kubecost" "http://localhost:9090" # Run function with Kubecost and Kubecost URL as input

line_break
empty_break "Admin cluster setup"
line_break


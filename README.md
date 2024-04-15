# Dissertation Software Framework

## Disseration Title

***Kubernetes Dynamic Admission Controllers (DACs): An Effective Mitigation Method Against Supply Chain Attacks Using Untrustworthy Base Images***

## Special Thanks
Thanks to gkampitakis as their source code was used as inspiration for this framework. Please see their repo [here](https://github.com/gkampitakis/k8s-dac-demo/tree/main).

## Pre-Requisites

1. Docker Desktop installed
2. Minikube installed
3. Helm installed
4. Kubectl installed

## Known Issues and Workarounds

### Pods Failing

During building, the vulnerable and protected deployment pods kept failing after completion so:

*command: ["sleep", "infinity"]*

was added to their yaml and kept the pods alive.

### Cert Issues

During building, the Certs would sometimes not be recognised in the webhook server deployment. Unfortunately, a workaround was not developed in time before the dissertation deadline.


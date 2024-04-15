#!/bin/bash
# Script to generate and deploy dacs
# Author: Huthayfa Patel

## VARIABLES

dacsdir="./dacs"

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

# Builds dacs
build_dacs() {
    eval $(minikube docker-env)
    docker build -t admission-controller .
}

# Generate dacs cert
generate_certs() {
    # generate keys
    chmod 0700 "../dacs"

    cat >server.conf <<EOF
    [req]
    req_extensions = v3_req
    distinguished_name = req_distinguished_name
    prompt = no
    [req_distinguished_name]
    CN = webhook-server.webhook-demo.svc
    [ v3_req ]
    basicConstraints = CA:FALSE
    keyUsage = nonRepudiation, digitalSignature, keyEncipherment
    extendedKeyUsage = clientAuth, serverAuth
    subjectAltName = @alt_names
    [alt_names]
    DNS.1 = webhook-server.webhook-demo.svc
EOF

    openssl req -nodes -new -x509 -keyout ca.key -out ca.crt -subj "/CN=Admission Controller Webhook Demo CA"
    openssl genrsa -out webhook-server-tls.key 2048
    openssl req -new -key webhook-server-tls.key -subj "/CN=webhook-server.webhook-demo.svc" -config server.conf \
    | openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -out webhook-server-tls.crt -extensions v3_req -extfile server.conf

    # add secret to diss namespace
    kubectl -n dissertation create secret tls webhook-server-tls \
    --cert "webhook-server-tls.crt" \
    --key "webhook-server-tls.key"

}

# Deploys dacs
deploy_dacs() {
    # deploy dacs yaml
    kubectl create -f validating-dacs.yaml
    # deploy webhook yaml with ca cert
    ca_pem_b64="$(openssl base64 -A <"ca.crt")"
    sed -e 's@${CA_PEM_B64}@'"$ca_pem_b64"'@g' <"validating-webhook.yaml" \
        | kubectl create -f -
}

## MAIN

cd "$dacsdir"

line_break 
empty_break "Generating DACs Certs" && generate_certs
line_break

line_break 
empty_break "Building DACs" && build_dacs
line_break

line_break 
empty_break "Deploying DACs" && deploy_dacs
line_break

line_break
empty_break "DACs Deployed Successfully"
line_break


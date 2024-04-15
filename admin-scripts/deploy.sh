#!/bin/bash
# Script to deploy diss-chart
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


## MAIN

line_break
empty_break "Deploying Diss Chart.."
helm install diss-chart ./diss-chart/ --namespace "dissertation"

line_break
empty_break "Diss Chart deployed"


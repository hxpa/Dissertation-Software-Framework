# Script to containerise DACs into admission-controller image
# Split into two stages - first stage builds DACs from Go file - second stage builds final image used in cluster
# Author: Huthayfa Patel

# Uses official Golang 1.18 image as base to build DACs from Go files
FROM golang:1.18 AS builder 

# Sets working dir inside container
WORKDIR /go/src/app

# Copies required Go files 
COPY dacs.go .
COPY go.mod .
COPY go.sum .

# Donwloads required dependencies specified in copied go.mod file
RUN go mod download

# Builds DACs from copied Go files
RUN CGO_ENABLED=0 GOOS=linux go build -o admission-controller .

# Uses scratch image as minimal base to build final image used in cluster
FROM scratch

# Copies application files from previous stage
COPY --from=builder /go/src/app/admission-controller /admission-controller

# Sets entrypoint for container
ENTRYPOINT ["/admission-controller"]


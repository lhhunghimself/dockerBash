#!/bin/bash

mkdir -p /tmp/$$/$1
cmd=$'FROM  alpine:latest\nMAINTAINER lhhung\nENTRYPOINT ['
echo "$cmd\"$1\"]" > /tmp/$$/$1/Dockerfile
sudo docker build -t $1 /tmp/$$/$1

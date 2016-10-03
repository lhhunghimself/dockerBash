#!/bin/bash

#local install
#sudo ln -s ${PWD}/dbash/dbash.pl /usr/local/bin/dbash

#docker:: dbash alias
echo "alias docker::dbash='sudo docker run --rm -i -v /var/run/docker.sock:/var/run/docker.sock -v /:/local dbash'" >> ~/.bashrc

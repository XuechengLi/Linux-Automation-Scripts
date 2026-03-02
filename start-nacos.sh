#!/bin/bash

export JAVA_HOME=/opt/jdk/jdk21.0.6
export PATH=$JAVA_HOME/bin:$PATH


cd /opt/nacos-server-3.1.1/bin
./startup.sh -m standalone

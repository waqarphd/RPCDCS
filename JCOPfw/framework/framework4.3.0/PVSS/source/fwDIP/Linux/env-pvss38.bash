#!/bin/bash

export PVSS_II_ROOT=${HOME}/pvss
export PVSS_PATH=/opt/pvss/pvss2_v3.8
export PATH=${PVSS_PATH}/bin:${PATH}
export LD_LIBRARY_PATH=${PVSS_PATH}/bin
export PLATFORM=linux_RHEL4
export LINUXVERSION=slc4
export DIPAPIBASE=`pwd`/..
export API_ROOT=/opt/pvss/pvss2_v3.8/api
export RPATH=-Wl,-rpath,$ORIGIN:/opt/pvss/pvss2_v3.8/bin
#Location of a valid Linux DIP distribution, e.g. below.
#export DIPBASE=/home/slc4/workspace/Projects/DIP/Release/dist/linux
export DIPBASE=/home/slc4/workspace/dip-5.4.3
#Std. library search path, to be extended with the bin directory of the PVSS installation for an obsure reason.
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PVSS_PATH/bin
export PLATFORM=linux_RHEL4

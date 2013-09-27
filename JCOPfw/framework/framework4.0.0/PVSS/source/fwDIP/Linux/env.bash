#!/bin/bash

export PVSS_II_ROOT=${HOME}/pvss
export PVSS_PATH=/opt/pvss/pvss2_v3.6
export PATH=${PVSS_PATH}/bin:${PATH}
export LD_LIBRARY_PATH=${PVSS_PATH}/bin
export PLATFORM=linux_RHEL4
export LINUXVERSION=slc4
export DIPAPIBASE=`pwd`/..
export API_ROOT=/opt/pvss/pvss2_v3.6/api
#Location of a valid Linux DIP distribution, e.g. below.
export DIPBASE=/home/mdutour/CvsSnapshot/Projects/DIP/Release/dist/linux
#Std. library search path, to be extended with the bin directory of the PVSS installation for an obsure reason.
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/pvss/pvss2_v3.6/bin
export PLATFORM=linux_RHEL4

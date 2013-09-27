#!/bin/bash

export PVSS_II_ROOT=${HOME}/pvss
export PVSS_PATH=/opt/WinCC_OA/3.11
export PVSS_DIR=${PVSS_PATH}
export PATH=${PVSS_PATH}/bin:${PATH}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${PVSS_PATH}/bin
export PLATFORM=linux_RHEL4
export LINUXVERSION=slc4
export DIPAPIBASE=`pwd`/..
export API_ROOT=${PVSS_PATH}/api
export RPATH="'-Wl,-rpath,\$\$ORIGIN:${PVSS_PATH}/bin'"
#Location of a valid Linux DIP distribution, e.g. below.
export DIPBASE=/home/enice/workspace/dip-5.5.0
#Std. library search path, to be extended with the bin directory of the PVSS installation for an obsure reason.


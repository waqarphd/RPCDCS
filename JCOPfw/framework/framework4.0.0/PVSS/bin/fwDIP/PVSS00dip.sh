#!/bin/bash
#############################################################
# Wrapper script to start an API manager on linux
# with some variables pre-configured (i.e. LD_LIBRARY_PATH)
#
# (c) Piotr Golonka, CERN IT/CO-BE, December 2006
#
############################################################

# Here, the user may override the path to PVSS directory:
#PVSS_II_PATH=/opt/PVSS/pvss2_v3.6

#echo "Starting"
# Put the path/filename of the actual manager here:

PVSS_PROJ=${PVSS_II%"/config/config"}
echo $PVSS_PROJ

MANAGER=$PVSS_PROJ/bin/PVSS00dip_api

if  test -z $PVSS_II_PATH  ; then
# guess the PVSS installation path:
# when run from PVSS console, PVSS_II variable is defined
# and points to a config file, from which we can extract
# PVSS path

    PVSS_II_PATH=`cat $PVSS_II|awk -F \" '/pvss_path/{print $2}'`
#    echo "Guessing PVSS_II_PATH:" $PVSS_II_PATH
fi

if  test ! -d $PVSS_II_PATH  ; then
 echo "ERROR: the directory pointed by PVSS_II_HOME variable is not readable:"
 echo $PVSS_II_PATH
 echo " Exiting"
 exit
fi

export LD_LIBRARY_PATH=$PVSS_PROJ/bin:$LD_LIBRARY_PATH
#echo $LD_LIBRARY_PATH
echo Starting: $MANAGER $*
exec $MANAGER $*

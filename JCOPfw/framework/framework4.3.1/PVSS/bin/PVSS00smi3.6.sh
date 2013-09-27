#!/bin/bash
#############################################################
# Wrapper script to start an API manager on linux
# with some variables pre-configured (i.e. LD_LIBRARY_PATH)
#
# Author:        Piotr Golonka, CERN EN/ICE-SCD, April 2005
# Last modified: Piotr Golonka,                  Nov   2011
#
############################################################

# Here, the user may override the path to PVSS directory:
#PVSS_II_PATH=/opt/PVSS/pvss2_v3.6
# Put the path/filename of the actual manager here:

PVSS_PROJ=${PVSS_II%"/config/config"}
#echo $PVSS_PROJ

BIN_PATH=`dirname $0`
#echo $BIN_PATH

#MANAGER=$PVSS_PROJ/bin/PVSS00smi3.6
MANAGER=$BIN_PATH/PVSS00smi3.6

if  test -z $PVSS_II_PATH  ; then 
# guess the PVSS installation path:
# when run from PVSS console, PVSS_II variable is defined
# and points to a config file, from which we can extract
# PVSS path

    PVSS_II_PATH=`cat $PVSS_II|awk -F \" '/pvss_path/{print $2}'`
    #echo "Guessing PVSS_II_PATH:" $PVSS_II_PATH
fi

if  test ! -d $PVSS_II_PATH  ; then
 echo "ERROR: the directory pointed by PVSS_II_HOME variable is not readable:"
 echo $PVSS_II_PATH
 echo " Exiting"
 exit
fi

PVSS_LIB_PATH=$PVSS_II_PATH/bin

if  test ! -d $PVSS_LIB_PATH  ; then
 echo "ERROR: cannot find the directory containing PVSS API libraries:"
 echo "$PVSS_LIB_PATH"
 echo " Exiting"
 exit
fi

#export LD_LIBRARY_PATH=$PVSS_PROJ/bin:$RH9_LIB_PATH:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$BIN_PATH:$PVSS_LIB_PATH:$LD_LIBRARY_PATH
#echo $LD_LIBRARY_PATH
echo Starting: $MANAGER $*
exec $MANAGER $*

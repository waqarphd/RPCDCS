#!/bin/bash
#
# This script will set up the necessary environment variables
# to run PVSS and the JCOP Framework on Linux
#
# Before running the script you should edit the definition of
# variables in the PVSS SETUP and JCOP FRAMEWORK DEFINITION 
# sections.
#
# $Author: mgonzale $ 
# $Revision: 1.2 $  
# $Date: 2002/12/09 10:37:07 $


#########################
# PVSS SETUP DEFINITION #
#########################

# Location of PVSS installation
export PVSS_SYSTEM_ROOT="/home/pvss/pvss2_v2.11.1"

# Location of your PVSS project
export PROJECT_ROOT="/home/dcs/PVSSProjects/myProject"

#############################
# JCOP FRAMEWORK DEFINITION #
#############################

# Location of the PVSS part of the JCOP Framework
export JCOP_FW="/home/dcs/framework/JCOP_FW_1_1/PVSS"

# Location of DIM
export DIMDIR=/home/dcs/framework/JCOP_FW_1_1/DIM

# DIM platform
export XDIR=linux 

# DIM Name Server (DNS)
export DIM_DNS_NODE=myComputer.cern.ch 
 
 
#########################
# SETUP OF ENVIRONMENT  #
#########################
#
# You should not need to edit below this line!
#

# Tell PVSS how to find the project's configuration file:
export PVSS_II="$PROJECT_ROOT/config/config"

echo "Using version PVSS installed in (PVSS_SYSTEM_ROOT) $PVSS_SYSTEM_ROOT"
echo "Using PVSS project located in (PVSS_II) $PVSS_II"

# Make the PVSS tools available in PATH.
# The fancy bit here means that this script can be re-run without making
# the PATH infinitely long.
# Rid any previous PVSS bin directory from the path
if [ ${PVSS_SYSTEM_ROOT}null != 'null' ] 
then 
  echo $PATH | grep $PVSS_SYSTEM_ROOT/bin 1>/dev/null 2>&1
  if [ $? -eq 0 ] 
  then
    PATH=`echo $PATH | sed sI:$PVSS_SYSTEM_ROOT/binII`
  fi
fi

# Add the bin directory in the PVSS installation to the path
echo $PATH | grep $PVSS_SYSTEM_ROOT 1>/dev/null 2>&1
if [ $? -eq 1 ] 
then 
  PATH=`echo $PATH | sed 's/\(.*\):$/\1/'`:$PVSS_SYSTEM_ROOT/bin
fi 
#echo "PVSS_SYSTEM_ROOT PATH=$PATH"
#echo "PVSS_SYSTEM_ROOT  LD_LIBRARY_PATH(1) = $LD_LIBRARY_PATH"

# Setup the library path defintion too.
# The fancy bit here means that this script can be re-run without making
# the LD_LIBRARY_PATH infinitely long.
# Rid any previous PVSS library directory from the path
if [ ${PVSS_SYSTEM_ROOT}null != 'null' ] 
then 
  echo $LD_LIBRARY_PATH | grep $PVSS_SYSTEM_ROOT/bin 1>/dev/null 2>&1
  if [ $? -eq 0 ] 
  then
    LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | sed sI:$PVSS_SYSTEM_ROOT/binII`
  fi
fi

#echo "LD_LIBRARY_PATH(2) = $LD_LIBRARY_PATH"


# Add the PVSS bin directory to the LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH | grep $PVSS_SYSTEM_ROOT 1>/dev/null 2>&1
if [ $? -eq 1 ] 
then 
  #echo "then was true"
  LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | sed 's/\(.*\):$/\1/'`:$PVSS_SYSTEM_ROOT/bin
fi 

# Remove any leading colon:
#echo "LD_LIBRARY_PATH(3) = $LD_LIBRARY_PATH"
export LD_LIBRARY_PATH=`echo ${LD_LIBRARY_PATH} | sed 's/^://'`
#echo "LD_LIBRARY_PATH(4) = $LD_LIBRARY_PATH"

#export LD_LIBRARY_PATH=${PVSS_SYSTEM_ROOT}/bin
#echo "Final LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
#echo "PVSS_SYSTEM_ROOT PATH=$PATH"
#echo "PVSS_SYSTEM_ROOT  LD_LIBRARY_PATH(1) = $LD_LIBRARY_PATH"

# Add the PROJECT_ROOT bin directory to the path
echo $PATH | grep $PROJECT_ROOT 1>/dev/null 2>&1
if [ $? -eq 1 ] 
then 
  PATH=`echo $PATH | sed 's/\(.*\):$/\1/'`:$PROJECT_ROOT/bin
fi 
#echo "PATH=$PATH"

# Add the PROJECT_ROOT bin directory to the LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH | grep $PROJECT_ROOT 1>/dev/null 2>&1
if [ $? -eq 1 ] 
then 
  #echo "then was true"
  LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | sed 's/\(.*\):$/\1/'`:$PROJECT_ROOT/bin
fi 
#echo "LD_LIBRARY_PATH(1) = $LD_LIBRARY_PATH"
#echo "PROJECT_ROOT PATH=$PATH"
#echo "PROJECT_ROOT  LD_LIBRARY_PATH(1) = $LD_LIBRARY_PATH"

# Add the JCOP_FW bin directory to the path
echo $PATH | grep $JCOP_FW 1>/dev/null 2>&1
if [ $? -eq 1 ] 
then 
  PATH=`echo $PATH | sed 's/\(.*\):$/\1/'`:$JCOP_FW/bin
fi 
#echo "PATH=$PATH"

# Add the JCOP_FW bin directory to the LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH | grep $JCOP_FW 1>/dev/null 2>&1
if [ $? -eq 1 ] 
then 
  #echo "then was true"
  LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | sed 's/\(.*\):$/\1/'`:$JCOP_FW/bin
fi 
#echo "LD_LIBRARY_PATH(1) = $LD_LIBRARY_PATH"
#echo "JCOP_FW PATH=$PATH"
#echo "JCOP_FW  LD_LIBRARY_PATH(1) = $LD_LIBRARY_PATH"

#compile api 
export API_ROOT=$PVSS_SYSTEM_ROOT/api 
export PLATFORM=linux 

# Make the DIM tools available in PATH. 
# The fancy bit here means that this script can be re-run without making 
# the PATH infinitely long. 
# Rid any previous PVSS bin directory from the path 
if [ ${DIMDIR}null != 'null' ]  
then  
  echo $PATH | grep DIMDIR/linux 1>/dev/null 2>&1 
  if [ $? -eq 0 ]  
  then 
    PATH=`echo $PATH | sed sI:DIMDIR/linuxII` 
  fi 
fi 
 
# Add the DIM bin directory to the path 
echo $PATH | grep $DIMDIR/linux 1>/dev/null 2>&1 
if [ $? -eq 1 ]  
then  
  PATH=`echo $PATH | sed 's/\(.*\):$/\1/'`:$DIMDIR/linux 
fi  


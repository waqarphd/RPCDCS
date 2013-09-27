Notes on building the DIP API Manager.
======================================

The api manager is built on 2 platforms XP and SLC4. SLC3 has been removed as no CERN wide supported anymore.
For the linux machines the source files are held in the afs directory - 

/afs/cern.ch/project/itcobe/Work/piotr/fwDIP/PVSS/source/fwDIP/Source

Make sure to refer to the DIP libraries using the following environment variables:
API_ROOT: Location of the PVSS API installation, e.g.: /opt/pvss/pvss2_v3.6/api
DIPAPIBASE: Location of the DIP API Manager source code, e.g.: /home/mdutour/CvsSnapshot/Projects/Framework/Software/framework2.0/Tools/fwDIP/PVSS/source/fwDIP
DIPBASE: Location of a valid Linux DIP distribution, e.g.: /home/mdutour/CvsSnapshot/Projects/DIP/Release/dist/linux
LD_LIBRARY_PATH: Std. library search path, to be extended with the bin directory of the PVSS installation for an obsure reason.

The binaries are not stored in CVS has they should be recontructed from the sources.
They can be stores on a different media such as a CD.


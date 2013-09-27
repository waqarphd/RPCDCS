// FILE: addVerInfo.hxx
// VERANTWORTUNG: Stano

// Specify the date and time

// This is in fact cxx, but it should not be
// compiled by default in Resources subproject.

// The file will be copied to the managers directory
// as cxx and will be recompiled each time a manager
// is linked.

#include <Resources.hxx>
#include <stdio.h>

// as significant part of "-version" - output is generated in a shared lib 
// (since 2.10 on NT and since 2.11 also on Linux) und is therefore not 
// significant for the executable:
#include <version.hxx>

#define SET_VERSINFO(vi) \
    vi[0] = version[0]; /* warning-suppression: "version unused ..." */ \
    sprintf(vi, "%s %s linked at %s", \
    PVSS_VERSION " " PVSS_VERS_COMMENT PVSS_VERS_WARNING, \
    PVSS_PATCH, __DATE__ " " __TIME__);


#ifndef ADDVERINFO
 
  class AddVersionInfo
  {
    public:
      AddVersionInfo();
  };
 
  AddVersionInfo::AddVersionInfo()
  {
    char vi[256];
    
    SET_VERSINFO(vi); 
    Resources::setAddVersionInfo(vi);
  }
 
  static AddVersionInfo linkedAt;
 
 
#else
 
  void setAddVersionInfo()
  {
    char vi[256];
    
    SET_VERSINFO(vi); 
    Resources::setAddVersionInfo(vi);
  }
#endif


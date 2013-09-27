include $(API_ROOT)/Manager.mk

#Root paths:
OBJDIR = $(DIPAPIBASE)/Linux
SRCDIR = $(DIPAPIBASE)/Sources
DIPAPISRC = $(SRCDIR)

#Libraries:
DIPLIBDIR  = ${DIPBASE}/lib
PLATDEPLIB = ${DIPBASE}/lib/PlatformDependant.a
LIBS = $(MANAGER_LIBS) $(LINKLIB) $(DIPLIB) $(PLATDEPLIB) -L$(DIPLIBDIR) -ldip -L$(API_ROOT)/bin

#Includes:
PLATDEPINC = ${DIPBASE}/include
DIPINC     = ${DIPBASE}/include
INCLUDE = $(MANAGER_INCL) -I$(DIPINC) -I$(DIPAPISRC) -I$(PLATDEPINC) -I$(API_ROOT)/include/Basics/Variables

#Target parameters:
OBJS = $(MANAGER_OBJS)
OBJFILES = AnswerCallBackHandler.o ApiMain.o RedManager.o Browser.o CdipClientDataObject.o CdipDataMapping.o CdipSubscription.o CdpeWrapper.o DIPClientManager.o DipApiManager.o DipApiResources.o PVSS_DIP_TypeMap.o addVerInfo.o dipManager.o dipPubGroup.o dipPublicationManager.o dpeMapping.o dpeMappingTuple.o mapping.o pubDpeWrapper.o simpleDPEWrapper.o CmdLine.o  
TARGET = PVSS00dip.exe

$(TARGET) : $(OBJFILES)
	@rm -f addVerInfo.o
	$(MAKE) -f Makefile addVerInfo.o
	@echo =====================================
	@echo linking target $@ for linux
	@echo =====================================
	$(LINK_CMD) $(RPATH) -frepo $(OBJFILES) $(OBJS) $(LIBS) -o $(TARGET) 


%.o : $(SRCDIR)/%.cpp
	@echo -------------------------------------------
	@echo compiling cpp using $(CXX) $@ to .o
	@echo -------------------------------------------
	$(CXX) $(ALL_CXXFLAGS) -c $(SRCDIR)/$*.cpp

%.o : $(SRCDIR)/%.cxx
	@echo -------------------------------------------
	@echo compiling cxx using $(CXX) $@ to .o
	@echo -------------------------------------------
	$(CXX) $(ALL_CXXFLAGS) -c $(SRCDIR)/$*.cxx


clean:
	@rm -f $(OBJFILES) $(TARGET) log

dos:
	make clean
	unix2dos *.cpp *.cxx *.h *.hxx

unix:
	dos2unix *.cpp *.cxx *.h *.hxx

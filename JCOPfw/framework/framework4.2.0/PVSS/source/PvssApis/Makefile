include $(API_ROOT)/Manager.mk

INCLUDE = $(MANAGER_INCL) -I. -I $(DIMDIR)/dim -I $(SMIDIR)/smixx

SDIR = src
ODIR = linux

SMILIBS	= $(MANAGER_LIBS) $(LINKLIB) -L$(DIMDIR)/$(ODIR) -L$(SMIDIR)/$(ODIR) -ldim -lsmi -lsmiui -lpthread

#DIMLIBS	= $(MANAGER_LIBS) $(LINKLIB) -lpthread
DIMLIBS	= $(MANAGER_LIBS) $(LINKLIB) -L$(DIMDIR)/$(ODIR) -ldim -lpthread

#RH90LIBS = -lwklin
RH90LIBS =

OBJS = $(MANAGER_OBJS)

all: $(ODIR)/PVSS00dim$(VERSION) $(ODIR)/PVSS00smi$(VERSION) 

fwUi: $(ODIR)/FwUi$(VERSION).so

dim: $(ODIR)/PVSS00dim$(VERSION)

$(ODIR)/PVSS00dim$(VERSION): $(SDIR)/DimApiMan.cxx $(ODIR)/ApiLib$(VERSION).o $(ODIR)/addVerInfo$(VERSION).o
	$(CXX) -m32 $(ALL_CXXFLAGS) -w -c $(SDIR)/DimApiMan.cxx -o $(ODIR)/DimApiMan$(VERSION).o
	$(LINK_CMD) -m32 -o $(ODIR)/PVSS00dim$(VERSION) $(ODIR)/addVerInfo$(VERSION).o $(ODIR)/DimApiMan$(VERSION).o $(ODIR)/ApiLib$(VERSION).o $(OBJS) $(DIMLIBS) $(RH90LIBS)
#	$(LINK_CMD) -o $(ODIR)/PVSS00dim$(VERSION) $(ODIR)/addVerInfo$(VERSION).o $(ODIR)/DimApiMan$(VERSION).o $(ODIR)/ApiLib$(VERSION).o $(OBJS) $(DIMDIR)/$(ODIR)/libdim.a $(DIMLIBS) $(RH90LIBS)

$(ODIR)/PVSS00smi$(VERSION): $(SDIR)/SmiApiMan.cxx $(ODIR)/ApiLib$(VERSION).o $(ODIR)/addVerInfo$(VERSION).o

	$(CXX) -m32 $(ALL_CXXFLAGS) -c $(SDIR)/SmiApiMan.cxx -o $(ODIR)/SmiApiMan$(VERSION).o
	$(LINK_CMD) -m32 -o $(ODIR)/PVSS00smi$(VERSION) $(ODIR)/addVerInfo$(VERSION).o $(ODIR)/SmiApiMan$(VERSION).o $(ODIR)/ApiLib$(VERSION).o $(OBJS) $(SMILIBS) $(RH90LIBS)


$(ODIR)/FwUi$(VERSION).so: $(SDIR)/fwUiLib.cxx $(ODIR)/addVerInfo$(VERSION).o
	$(CXX) -m32 $(ALL_CXXFLAGS) -c $(SDIR)/fwUiLib.cxx -o $(ODIR)/fwUiLib$(VERSION).o
	$(LINK_CMD) -o $(ODIR)/FwUi$(VERSION).so -shared $(ODIR)/fwUiLib$(VERSION).o $(ODIR)/addVerInfo$(VERSION).o $(OBJS) $(LIBS)

$(ODIR)/ApiLib$(VERSION).o:	$(SDIR)/ApiLib.cxx $(SDIR)/ApiLib.hxx
	@echo Making target Apilib
	$(CXX) -m32 $(ALL_CXXFLAGS) -c $(SDIR)/ApiLib.cxx -o $(ODIR)/ApiLib$(VERSION).o

$(SDIR)/addVerInfo$(VERSION).cxx: $(API_ROOT)/include/Basics/Utilities/addVerInfo.hxx
	@cp -f $(API_ROOT)/include/Basics/Utilities/addVerInfo.hxx $(SDIR)/addVerInfo$(VERSION).cxx

$(ODIR)/addVerInfo$(VERSION).o: $(OFILES) $(SDIR)/addVerInfo$(VERSION).cxx
	$(CXX) -m32 $(ALL_CXXFLAGS) -c $(SDIR)/addVerInfo$(VERSION).cxx -o $(ODIR)/addVerInfo$(VERSION).o

clean:
	@rm -f $(ODIR)/*.o


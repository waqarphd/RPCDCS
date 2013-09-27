CXX = g++

INCLUDE = -I$(DIMDIR)/dim

SDIR = src
ODIR = linux

LIBS	= -L$(DIMDIR)/$(ODIR) -ldim -lpthread

all: $(ODIR)/pvss_dim_server $(ODIR)/pvss_dim_client

$(ODIR)/pvss_dim_server: $(SDIR)/pvss_dim_server.cxx
	$(CXX) -g $(INCLUDE) -o $(ODIR)/pvss_dim_server $(SDIR)/pvss_dim_server.cxx $(LIBS)

$(ODIR)/pvss_dim_client: $(SDIR)/pvss_dim_client.cxx
	$(CXX) -g $(INCLUDE) -o $(ODIR)/pvss_dim_client $(SDIR)/pvss_dim_client.cxx $(LIBS)

clean:
	@rm -f *.o $(ODIR)/pvss_dim_client $(ODIR)/pvss_dim_server

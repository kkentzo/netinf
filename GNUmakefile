UNAME := $(shell uname)
CC = gcc -v
TOOL_NAME = netinf

ADDITIONAL_OBJCFLAGS = -g 

#====================================================
ifeq ($(UNAME),Darwin)
# MAC settings
MAKEFILEDIR=/Developer/Makefiles/pb_makefiles
ADDITIONAL_OBJC_LIBS = -framework Foundation -lgsl -lgslcblas 

ADDITIONAL_LIB_DIRS = -L/opt/local/lib -L/usr/lib
ADDITIONAL_INCLUDE_DIRS = -I/opt/local/include

include $(MAKEFILEDIR)/common.make

# Files to compile acc to project
netinf_OBJC_FILES = main.m params.m aco.m graphs.m common.m GSL.m Graph.m RNN.m Dynamics.m pso.m

include $(MAKEFILEDIR)/tool.make

$(TOOL_NAME): $(netinf_OBJC_FILES)
	$(CC) $(ADDITIONAL_OBJCFLAGS) $(ADDITIONAL_INCLUDE_DIRS) $(ADDITIONAL_LIB_DIRS) $(ADDITIONAL_OBJC_LIBS) $(netinf_OBJC_FILES) -o $(TOOL_NAME)

clean:
	rm netinf; rm -rf netinf.dSYM

else
# LINUX settings
GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles
ADDITIONAL_OBJC_LIBS = -lgsl -lgslcblas 

include $(GNUSTEP_MAKEFILES)/common.make

# include common library files
#$(TOOL_NAME)_SUBPROJECTS = $(OBJCLIB_DIR)

# Files to compile acc to project
$(TOOL_NAME)_OBJC_FILES = main.m params.m aco.m graphs.m common.m Graph.m pso.m GSL.m Dynamics.m RNN.m

include $(GNUSTEP_MAKEFILES)/tool.make

endif
#====================================================




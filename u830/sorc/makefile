SHELL=/bin/sh
#
# This makefile was produced by /usr/bin/fmgen at 03:45:31 PM on 03/07/96
# If it is invoked by the command line
#	make -f makefile
# it will compile the fortran modules indicated by SRCS into the object
# modules indicated by OBJS and produce an executable named a.out.
#
# To remove all the objects but leave the executables use the command line
#	make -f makefile clean
#
# To remove everything but the source files use the command line
#	make -f makefile clobber
#
# To remove the source files created by /usr/bin/fmgen and this makefile
# use the command line
#	make -f makefile void
#
# The parameters SRCS and OBJS should not need to be changed.  If, however,
# you need to add a new module add the name of the source module to the
# SRCS parameter and add the name of the resulting object file to the OBJS
# parameter.  The new modules are not limited to fortran, but may be C, YACC,
# LEX, or CAL.  An explicit rule will need to be added for PASCAL modules.
#
SRCS= dru830.f rd83ob.f

OBJS= dru830.o rd83ob.o

# Tunable parameters
#
# FC		Name of the fortran compiling system to use
# LDFLAGS	Flags to the loader
# LIBS		List of libraries
# CMD		Name of the executable
# PROFLIB       Library needed for profiling
#
FC =		ifort
LDFLAGS =       -Bstatic	
LIBS =          /mdlstat/save/mos/mos2k/u830lib/libu830lib_4.a \
                /mdlstat/save/mos/mos2k/moslib/libmoslib_4.a 
CMD =		u830.x
PROFLIB =

FFLAGS =        -O3 -fp-model strict -auto -fpscomp logicals -zero -fixed \
                -assume byterecl -integer-size 32 -real-size 32

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build a.out.
#
all:		$(CMD)

$(CMD):         $(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) \
                            -Wl,--start-group $(LIBS) -Wl,--end-group

# Make the profiled version of the command and call it a.out.prof
#
$(CMD).prof:	$(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(PROFLIB) \
                            -Wl,--start-group $(LIBS) -Wl,--end-group

clean:
	-rm -f $(OBJS)

clobber:	clean
	-rm -f $(CMD) $(CMD).prof

void:	clobber
	-rm -f $(SRCS) makefile

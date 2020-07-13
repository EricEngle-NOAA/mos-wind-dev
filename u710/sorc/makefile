SHELL=/bin/sh
#
#
SRCS=	dru710.f 

OBJS=	dru710.o 

# Tunable parameters
#
# FC		Name of the fortran compiling system to use
# LDFLAGS	Flags to the loader
# LIBS		List of libraries
# CMD		Name of the executable
#
FC =	        ifort
LDFLAGS =       -Bstatic	
LIBS =          /mdlstat/save/mos/mos2k/u7xxlib/libu710lib_4.a \
                /mdlstat/save/mos/mos2k/moslib/libmoslib_4.a
CMD =	        u710.x

# To perform the default compilation, use the first line
# To compile with flowtracing turned on, use the second line
# To compile giving profile additonal information, use the third line
# WARNING:  SIMULTANEOUSLY PROFILING AND FLOWTRACING IS NOT RECOMMENDED 

FFLAGS =        -O3 -fp-model strict -auto -fpscomp logicals -zero -fixed \
                -assume byterecl -integer-size 32 -real-size 32

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build a.out.
#
all:            $(CMD)

$(CMD):         $(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) \
                            -Wl,--start-group $(LIBS) -Wl,--end-group

# Make the profiled version of the command and call it a.out.prof
#
$(CMD).prof:    $(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(PROFLIB) \
                            -Wl,--start-group $(LIBS) -Wl,--end-group

clean:
	-rm -f $(OBJS)

clobber:	clean
	-rm -f $(CMD) $(CMD).prof

void:	clobber
	-rm -f $(SRCS) makefile

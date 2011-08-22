#!/bin/sh

# This program will configure the makefile for various OSes.
#
# Config version 1.1
SYS=

# Heading

cat > Makefile <<EoF
# Makefile for HEYU, a program to control an X10 CM11A computer interface.
# This makefile is generated by the Configure.sh program.
#
EoF

# paths:
cat >> Makefile <<EoF
BIN = /usr/local/bin
MAN = /usr/local/man/man1
MAN5 = /usr/local/man/man5

#       set DFLAGS equal to:
#          -DSYSV       if using SYSTEM V
#          -DVOID       if compiler doesn't understand 'void'

EoF

OPTIONS=

while [ $# -ge 1 ] ; do
    case "$1" in
	help|-h|-help)
	    echo "Usage: $0 <system type> [-nocm17a] [-noext0]"
	    echo " Valid system types are linux,sunos,solaris,opensolaris,opensolaris_bsd,"
	    echo " freebsd,openbsd,netbsd,darwin,sco,aix,sysv,attsvr4,nextstep,osf,generic"
	    echo " If no system type is specified, the output of uname(1) will be used."
            echo " Switch -nocm17a omits support for the optional CM17A Firecracker device." 
            echo " Switch -noext0 omits support for extended type 0 shutter controllers."
            echo " Switch -norfxs omits support for RFXSensors."
            echo " Switch -norfxm omits support for RFXMeters."
            echo " Switch -nodmx omits support for the Digimax thermostat."
            echo " Switch -noore omits support for Oregon sensors."
            echo " Switch -nokaku omits support for KaKu/HomeEasy signals"
            echo " Switch -flags=n sets the number of user flags (32 min, 1024 max)"
            echo " Switch -counters=n sets the number of counters (32 min, 1024 max)"
            echo " Switch -timers=n sets the number of timers (32 min, 1024 max)"
            echo " Above numbers are rounded up to the nearest multiple of 32"
	    rm Makefile 
	    exit
	    ;;
        nocm17a|-nocm17a|NOCM17A|-NOCM17A|--disable-cm17a)
            OPTIONS="$OPTIONS --disable-cm17a"
            ;;
        noext0|-noext0|NOEXT0|-NOEXT0|--disable-ext0)
            OPTIONS="$OPTIONS --disable-ext0"
            ;;
        norfxs|-norfxs|NORFXS|-NORFXS|--disable-rfxs)
            OPTIONS="$OPTIONS --disable-rfxs"
            ;;
        norfxm|-norfxm|NORFXM|-NORFXM|--disable-rfxm)
            OPTIONS="$OPTIONS --disable-rfxm"
            ;;
        nodmx|-nodmx|NODMX|-NODMX|--disable-dmx)
            OPTIONS="$OPTIONS --disable-dmx"
            ;;
        noore|-noore|NOORE|-NOORE|--disable-ore)
            OPTIONS="$OPTIONS --disable-ore"
            ;;
        nokaku|-nokaku|NOKAKU|-NOKAKU|--disable-kaku)
            OPTIONS="$OPTIONS --disable-kaku"
            ;;
	flags=*|-flags=*|FLAGS=*|-FLAGS=*)
	    IFS="${IFS}=" read keyword FLAGS <<EoF
$1
EoF
	    [ $FLAGS -ge 1 ] && [ $FLAGS -le 1024 ] || {
            	echo " Invalid flags argument, should be a number in the 1-1024 range"
	    	rm Makefile
		exit
	    }
	    FLAGS_FLAG="-DNUM_FLAG_BANKS=`expr \( $FLAGS + 31 \) / 32`"
	    ;;
	counters=*|-counters=*|COUNTERS=*|-COUNTERS=*)
	    IFS="${IFS}=" read keyword COUNTERS <<EoF
$1
EoF
	    [ $COUNTERS -ge 1 ] && [ $COUNTERS -le 1024 ] || {
            	echo " Invalid counters argument, should be a number in the 1-1024 range"
	    	rm Makefile
		exit
	    }
	    COUNTERS_FLAG="-DNUM_COUNTER_BANKS=`expr \( $COUNTERS + 31 \) / 32`"
	    ;;
	timers=*|-timers=*|TIMERS=*|-TIMERS=*)
	    IFS="${IFS}=" read keyword TIMERS <<EoF
$1
EoF
	    [ $TIMERS -ge 1 ] && [ $TIMERS -le 1024 ] || {
            	echo " Invalid timers argument, should be a number in the 1-1024 range"
	    	rm Makefile
		exit
	    }
	    TIMERS_FLAG="-DNUM_TIMER_BANKS=`expr \( $TIMERS + 31 \) / 32`"
	    ;;
	*)
	    SYS="$1"
	    ;;
    esac
    shift
done

test -x configure && test configure -nt configure.ac && \
test -s config.h.in && test config.h.in -nt configure.ac || {
	type autoconf >/dev/null && type autoheader >/dev/null || {
		echo "Please install autoconf package and re-run ./Configure.sh"
		rm Makefile 
		exit
	}
	autoconf
	autoheader
}

cat <<EoF

This script will create a Makefile based by default on
the output of uname(1), or otherwise on the system type
parameter you enter.
 
EoF



if [ "$SYS" = "" ] ; then
    SYS=`uname -s | tr '[A-Z]' '[a-z]'`
fi

CC=gcc  #Set default for later

echo "#This makefile is built for $SYS" >> Makefile
case "$SYS" in
    linux)
        cat >> Makefile <<-EoF
	OWNER = root
	GROUP = root 
	CC = gcc
	CFLAGS = -g -O \$(DFLAGS) -Wall
	DFLAGS = -DSYSV -DPOSIX $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
	LIBS = -lm -lc
EoF
	;;
    sunos*|solaris)
    	type gcc > /dev/null
    	if [ $? = 0 ] ; then
    	    echo "CC = gcc" >> Makefile
            WALLFLAG=-Wall
	else
            CC=cc
	    echo "CC = cc" >> Makefile
            WALLFLAG=
	fi
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	DFLAGS = -DSYSV -DPOSIX -DLOCKDIR=\"/var/spool/locks\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
	CFLAGS = -g -O \$(DFLAGS) \$WALLFLAG
	LIBS = -lm -lc -lrt
EoF
	;;
    opensolaris)
cat >> Makefile <<EoF
	BIN = /opt/heyu/bin
	MAN = /opt/heyu/man/man1
	MAN5 = /opt/heyu/man/man5
EoF
    	type gcc > /dev/null
    	if [ $? = 0 ] ; then
    	    echo "CC = gcc" >> Makefile
            WALLFLAG=-Wall
	else
            CC=cc
	    echo "CC = cc" >> Makefile
            WALLFLAG=
	fi
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	DFLAGS = -DSYSV -DPOSIX -DSYSBASEDIR=\"/opt/heyu/etc\" -DLOCKDIR=\"/var/spool/locks\" 
	CFLAGS = -g -O \$(DFLAGS) \$WALLFLAG
	LIBS = -lm -lc -lrt
EoF
	;;
    opensolaris_bsd)
    	type gcc > /dev/null
    	if [ $? = 0 ] ; then
    	    echo "CC = gcc" >> Makefile
            WALLFLAG=-Wall
	else
            CC=cc
	    echo "CC = cc" >> Makefile
            WALLFLAG=
	fi
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	DFLAGS = -DSYSV -DPOSIX -DLOCKDIR=\"/var/spool/locks\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
	CFLAGS = -g -O \$(DFLAGS) \$WALLFLAG
	LIBS = -lm -lc -lrt
EoF
	;;
    freebsd)
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = wheel
	CC = gcc
	CFLAGS = -g -O \$(DFLAGS) -Wall
	LIBS = -lm -lc
	DFLAGS= -DPOSIX -DLOCKDIR=\"/var/spool/lock\" -DSYSBASEDIR=\"/usr/local/etc/heyu\" -DSPOOLDIR=\"/var/tmp/heyu\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
EoF
	;;
    openbsd)
        cat >> Makefile <<-EoF
	OWNER = root
	GROUP = wheel
	CC = gcc
	CFLAGS = -g -O \$(DFLAGS) -Wall
	LIBS = -lm -lc
	DFLAGS= -DPOSIX -DLOCKDIR=\"/var/spool/lock\" -DSYSBASEDIR=\"/etc/heyu\" -DSPOOLDIR=\"/var/tmp/heyu\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
EoF
       ;;
    netbsd)
	cat >> Makefile <<-EoF
	OWNER= root
	GROUP = wheel
	DFLAGS = -DPOSIX -DLOCKDIR=\"/var/spool/lock\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
	CC = gcc
	CFLAGS = -g -O \$(DFLAGS) -Wall
	LIBS = -lm -lc
EoF
	;;
    darwin)
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = wheel
	DFLAGS = -DPOSIX $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
	CC = gcc
	CFLAGS = -g -O \$(DFLAGS) -Wall
	LIBS = -lm -lc
EoF
	;;
    sco*)
        CC=cc
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	CC = cc
	MAN = /usr/local/man/man.1
	MAN5 = /usr/local/man/man.5
	CFLAGS = -O \$(DFLAGS)
	LIBS = -lm -lc -lsocket
	DFLAGS= -DSYSV -DSCO -DLOCKDIR=\"/var/spool/locks\" -DSPOOLDIR=\"/usr/tmp/heyu\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
EoF
	;;
    aix|sysv)
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	CC = gcc
	CFLAGS = -g -O \$(DFLAGS) -Wall
	LIBS = -lm -lc
	DFLAGS = -DSYSV -DPOSIX $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
EoF
	;;
    attsvr4)
        CC=cc
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	CC = cc
	CFLAGS = -I/usr/local/include -g -O \$(DFLAGS)
	LIBS = -lc -L/usr/ucblib -lucb -lm -lgen -lcmd
	DFLAGS = -DSYSV -DPOSIX -DLOCKDIR=\"/var/spool/locks\" -DSPOOLDIR=\"/var/spool/heyu\" -DSYSBASEDIR=\"/usr/local/etc/heyu\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
EoF
	;;
    nextstep)
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	CC = gcc
	DFLAGS =  -DPOSIX $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
	CFLAGS = -g \$(DFLAGS) -posix
	LDFLAGS = -posix
	LIBS = -lm -lposix
EoF
	;;
    osf)
	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = uucp
	CC = gcc
	CFLAGS = -g \$(DFLAGS)
	LIBS = -lm -lc
	DFLAGS = -DSYSV -DLOCKDIR=\"/var/spool/locks\" $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
EoF
      ;;
    generic)
    	cat >> Makefile <<-EoF
	OWNER = root
	GROUP = sys
	CC = gcc
	CFLAGS = -g -O \$(DFLAGS) -Wall
	LIBS = -lm -lc
	DFLAGS=  $FLAGS_FLAG $TIMERS_FLAG $COUNTERS_FLAG
EoF
	;;
    *)
    	echo "Your system type was not understood.  Please try one of "
    	echo "the following".
    	$0 -help
    	exit
    	;;
esac


cat >> Makefile <<EoF
# # The rest of the makefile should need no changes

EoF

cat Makefile.in >> Makefile

(	set -x
	./configure $OPTIONS
)

if [ "$SYS" = "sysv" ] ; then
echo "The Makefile has been created for sysv, however if"
echo "you are running under AT&T SysV r4, please re-run"
echo "Configure.sh with the system type parameter attsvr4"
else
echo "The Makefile has been created for $SYS."
fi
if [ "$SYS" = "opensolaris" ] ; then
echo "Please see \"Notes for OpenSolaris\" in file INSTALL before proceeding."
echo
fi

echo ""
echo "Note: If you are upgrading from an earlier version,"
echo "run 'heyu stop' before proceeding further."
echo ""
echo "** Now run 'make' as a normal user **"
echo ""

set -e
set -x

TRAVIS_ROOT="$1"

# reasonable options include:
#  smp, udp, mpi, ofi
GASNET_CONDUIT="$2"

# we can't handle this yet in build-run-prk.sh
#if [ "x$GASNET_CONDUIT" -eq "x" ] ; then
#    BUPC_PREFIX=bupc-$CC
#else
#    BUPC_PREFIX=bupc-$CC-$GASNET_CONDUIT
#fi
BUPC_PREFIX=bupc-$CC

export BUPC_RELEASE=berkeley_upc-2.22.0

if [ ! -d "$BUPC_PREFIX" ]; then
    wget --no-check-certificate -q http://upc.lbl.gov/download/release/$BUPC_RELEASE.tar.gz
    tar -xzf $BUPC_RELEASE.tar.gz
    cd $BUPC_RELEASE
    mkdir build && cd build
    # disable IBV just in case Linux has headers for it
    case "$GASNET_CONDUIT" in
        smp)
            ../configure --prefix=$BUPC_PREFIX --disable-ibv --without-mpi-cc \
                         --enable-$GASNET_CONDUIT
            ;;
        udp)
            ../configure --prefix=$BUPC_PREFIX --disable-ibv --without-mpi-cc \
                         --enable-$GASNET_CONDUIT
            ;;
        ofi)
            # TODO factor Hydra out of Sandia OpenSHMEM install so it can be used as spawner here
            sh ./travis/install-libfabric.sh $TRAVIS_ROOT
            ../configure --prefix=$BUPC_PREFIX --disable-ibv --without-mpi-cc \
                         --enable-$GASNET_CONDUIT --with-ofihome=$TRAVIS_ROOT/libfabric --with-ofi-spawner=ssh
            ;;
        mpi)
            sh ./travis/install-mpi.sh $TRAVIS_ROOT mpich
            ../configure --prefix=$BUPC_PREFIX --disable-ibv \
                         --enable-$GASNET_CONDUIT --with-mpi-cc=$TRAVIS_ROOT/mpich/bin/mpicc
            ;;
        *)
            echo "GASNet conduit not specified - configure will guess."
            ../configure --prefix=$BUPC_PREFIX
            exit 85
            ;;
    esac
else
    echo "Berkeley UPC (w/ $CC) installed..."
    find $BUPC_PREFIX -name upcc -type f
fi


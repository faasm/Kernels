set -e
set -x

os=`uname`
TRAVIS_ROOT="$1"

if [ ! -d "$TRAVIS_ROOT/opencoarrays" ]; then
    case "$os" in
        Darwin)
            echo "Mac"
            set +e
            brew update
            brew install gcc6
            brew install mpich
            brew unlink cmake
            brew install cmake
            cmake --version
            set -e
            ;;

        Linux)
            echo "Linux"
            sh ./travis/install-mpi.sh $TRAVIS_ROOT mpich 1
            sh ./travis/install-cmake.sh $TRAVIS_ROOT
            ;;
    esac

    cd $TRAVIS_ROOT
    git clone --depth 10 https://github.com/sourceryinstitute/opencoarrays.git opencoarrays-source
    cd opencoarrays-source
    mkdir build
    cd build
    # mpif90 is more widely available than mpifort...
    which mpicc
    which mpif90
    mpicc -show
    mpif90 -show
    export MPICH_CC=gcc-6
    export MPICH_FC=gfortran-6
    mpicc -show
    mpif90 -show
    CC=mpicc FC=mpif90 cmake .. -DCMAKE_INSTALL_PREFIX=$TRAVIS_ROOT/opencoarrays \
                                -DMPI_C_COMPILER=mpicc -DMPI_Fortran_COMPILER=mpifort
    make
    ctest
    make install
    find $TRAVIS_ROOT -name caf
    find $TRAVIS_ROOT -name cafrun
else
    echo "OpenCoarrays installed..."
    find $TRAVIS_ROOT -name caf
    find $TRAVIS_ROOT -name cafrun
fi

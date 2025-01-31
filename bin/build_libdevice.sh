#!/bin/bash
#
#  File: build_libdevice.sh
#        build the rocm-device-libs libraries in $AOMP/lib/libdevice
#
# --- Start standard header ----
function getdname(){
   local __DIRN=`dirname "$1"`
   if [ "$__DIRN" = "." ] ; then
      __DIRN=$PWD;
   else
      if [ ${__DIRN:0:1} != "/" ] ; then
         if [ ${__DIRN:0:2} == ".." ] ; then
               __DIRN=`dirname $PWD`/${__DIRN:3}
         else
            if [ ${__DIRN:0:1} = "." ] ; then
               __DIRN=$PWD/${__DIRN:2}
            else
               __DIRN=$PWD/$__DIRN
            fi
         fi
      fi
   fi
   echo $__DIRN
}
thisdir=$(getdname $0)
[ ! -L "$0" ] || thisdir=$(getdname `readlink "$0"`)
. $thisdir/aomp_common_vars
# --- end standard header ----

# We now pickup HSA from the AOMP install directory because it is built
# with build_roct.sh and build_rocr.sh . 
HSA_DIR=${HSA_DIR:-$AOMP/hsa}
SKIPTEST=${SKIPTEST:-"YES"}

INSTALL_ROOT_DIR=${INSTALL_LIBDEVICE:-$AOMP_INSTALL_DIR}
INSTALL_DIR=$INSTALL_ROOT_DIR

export LLVM_DIR=$AOMP_INSTALL_DIR
export LLVM_BUILD=$AOMP_INSTALL_DIR
SOURCEDIR=$AOMP_REPOS/$AOMP_LIBDEVICE_REPO_NAME

REPO_BRANCH=$AOMP_LIBDEVICE_REPO_BRANCH
REPO_DIR=$AOMP_REPOS/$AOMP_LIBDEVICE_REPO_NAME
checkrepo

MYCMAKEOPTS="-DLLVM_DIR=$LLVM_DIR -DBUILD_HC_LIB=ON -DROCM_DEVICELIB_INCLUDE_TESTS=OFF"

if [ ! -d $AOMP_INSTALL_DIR/lib ] ; then 
  echo "ERROR: Directory $AOMP/lib is missing"
  echo "       AOMP must be installed in $AOMP_INSTALL_DIR to continue"
  exit 1
fi

export LLVM_BUILD HSA_DIR
export PATH=$LLVM_BUILD/bin:$PATH

if [ "$1" != "install" ] ; then 
    
   if [ $COPYSOURCE ] ; then 
      if [ -d $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME ] ; then 
         echo rm -rf $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME
         $SUDO rm -rf $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME
      fi
      mkdir -p $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME
      echo rsync -a $SOURCEDIR/ $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME/
      rsync -a $SOURCEDIR/ $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME/
      # Fixup ll files to avoid link warnings
      for llfile in `find $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME -type f | grep "\.ll" ` ; do 
        sed -i -e"s/:64-A5/:64-S32-A5/" $llfile
      done
   fi

      builddir_libdevice=$BUILD_DIR/build/libdevice
      if [ -d $builddir_libdevice ] ; then 
         echo rm -rf $builddir_libdevice
         # need SUDO because a previous make install was done with sudo 
         $SUDO rm -rf $builddir_libdevice
      fi
      mkdir -p $builddir_libdevice
      cd $builddir_libdevice
      echo 
      echo DOING BUILD in Directory $builddir_libdevice
      echo 

      CC="$LLVM_BUILD/bin/clang"
      export CC
      echo "cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME"
      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME
      if [ $? != 0 ] ; then 
         echo "ERROR cmake failed  command was \n"
         echo "      cmake $MYCMAKEOPTS -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR $BUILD_DIR/$AOMP_LIBDEVICE_REPO_NAME"
         exit 1
      fi
      echo "make -j $NUM_THREADS"
      make -j $NUM_THREADS 
      if [ $? != 0 ] ; then 
         echo "ERROR make failed "
         exit 1
      fi


   echo 
   echo "  Done with all makes"
   echo "  Please run ./build_libdevice.sh install "
   echo 

   if [ "$SKIPTEST" != "YES" ] ; then 
         builddir_libdevice=$BUILD_DIR/build/libdevice
         cd $builddir_libdevice
         echo "running tests in $builddir_libdevice"
         make test 
      echo 
      echo "# done with all tests"
      echo 
   fi
fi

if [ "$1" == "install" ] ; then 

   echo 
   echo mkdir -p $INSTALL_DIR/include
   $SUDO mkdir -p $INSTALL_DIR/include
   $SUDO mkdir -p $INSTALL_DIR/lib
   builddir_libdevice=$BUILD_DIR/build/libdevice
   echo "running make install from $builddir_libdevice"
   cd $builddir_libdevice
   echo $SUDO make -j $NUM_THREADS install
   $SUDO make -j $NUM_THREADS install

   # rocm-device-lib cmake installs to lib dir, move all bc files up one level
   # and cleanup unused oclc_isa_version bc files and link correct one
   #echo
   #echo "POST-INSTALL REORG OF SUBDIRECTORIES $INSTALL_DIR"
   #echo "--"
   #echo "-- $INSTALL_DIR"
   #echo "-- MOVING bc FILES FROM lib DIRECTORY UP ONE LEVEL"
   #$SUDO mv $INSTALL_DIR/lib/*.bc $INSTALL_DIR
   #$SUDO rm -rf $INSTALL_DIR/lib/cmake
   #$SUDO rmdir $INSTALL_DIR/lib 

   # END OF POST-INSTALL REORG 

   echo 
   echo " $0 Installation complete into $INSTALL_DIR"
   echo 
fi

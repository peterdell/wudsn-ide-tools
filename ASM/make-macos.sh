#!/bin/bash

set -e

export OS="macOS"
export EXT="macos"
export EXT32="$EXT-i386"
export EXT64="$EXT-x86-64"
export EXTA64="$EXT-aarch-64"
export EXTPPC="$EXT-powerpc"

echo Creating $OS binaries.


#------------------------------------------------------------------------
# Install XCode Commnd Line Tools if required.
#------------------------------------------------------------------------
function installXCodeCommandlineTools() {
  export XCODE_COMMANDLINE_TOOLS="/Library/Developer/CommandLineTools"
  if [ ! -d $XCODE_COMMANDLINE_TOOLS ]; then
    xcode-select --install
  fi
  export XCODE_COMMANDLINE_TOOLS_LIBS="${XCODE_COMMANDLINE_TOOLS}/SDKs/MacOSX.sdk"
}

#-------------------------------------------------------------------------
# Create ATASM.
#-------------------------------------------------------------------------
function makeATASM() {

cd ATASM/src

#echo Creating ATASM - $OS 32-bit version
#export ARCH="-arch i386"
#make
#chmod a+x atasm
#mv atasm ../atasm.$EXT32
#make clean

echo Creating ATASM - $OS 64-bit version
export ARCH="-arch x86_64"
make
chmod a+x atasm
mv atasm ../atasm.$EXT64
make clean

#echo Creating ATASM - $OS PPC version
#export ARCH="-arch ppc"
#make
#chmod a+x atasm
#mv atasm ../atasm.$EXTPPC
#make clean

cd ../..
}

#------------------------------------------------------------------------
# Create DASM.
#------------------------------------------------------------------------
function makeDASM() {

cd DASM

mkdir -p bin
cd src

#echo Creating DASM - $OS 32-bit version
#export CC="gcc -arch i386"
#make
#mv dasm   ../bin/dasm.$EXT32
#mv ftohex ../bin/ftohex.$EXT32
#make clean

echo Creating DASM - $OS 64-bit version
export CC="clang -target x86_64-apple-darwin-macho"
make
mv dasm   ../bin/dasm.$EXT64
mv ftohex ../bin/ftohex.$EXT64
make clean

#echo Creating DASM - $OS PPC version
#export CC="gcc -arch ppc"
#make
#mv dasm   ../bin/dasm.$EXTPPC
#mv ftohex ../bin/ftohex.$EXTPPC
#make clean

cd ..

cd test
make clean
cd ..

cd ..

}

#------------------------------------------------------------------------
# Create MADS.
#------------------------------------------------------------------------
function makeMADS() { 

# The MADS folder was initially created using
# git clone --depth=1 https://github.com/tebe6502/Mad-Assembler.git MADS

cd MADS
git pull --depth=1 --rebase

#echo Creating MADS - $OS Intel 32-bit version
#ppc386 -Mdelphi -v -O3 -XXs -omads.$EXT32 mads.pas
#rm -f mads.o

OPT="-Mdelphi -O3 -XR$XCODE_COMMANDLINE_TOOLS_LIBS"
EXECUTABLE="mads.$EXT64"
echo Creating MADS - $OS Intel 64-bit version
ppcx64 $OPT -o$EXECUTABLE mads.pas
rm -f mads.o

#echo Creating MADS - $OS M1 64-bit version
#fpc -Paarch64 -Mdelphi -v -O3 -XXs -omads.$EXTA64 mads.pas
#rm -f mads.o

#echo Creating MADS - $OS PPC version
#ppcppc -Mdelphi -v -O3 -XXs -omads.$EXTPPC mads.pas
rm -f mads.o
 
cd ..

}

#------------------------------------------------------------------------
# Display Result Details.
#------------------------------------------------------------------------
function displayAssembler() {
  echo Executables for $1: 
  for f in $1$2*.$EXT32 $1$2*.$EXT64 $1$2*.$EXTPPC
  do
    file $f
  done
}

installXCodeCommandlineTools
#makeATASM
makeDASM
makeMADS

#------------------------------------------------------------------------
# List result. 
#------------------------------------------------------------------------
echo Done.
displayAssembler ATASM /
displayAssembler DASM  /bin/
displayAssembler MADS  /

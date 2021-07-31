@echo off

setlocal

if "%~1" == "" (
  echo Package revision must be provided as the first argument
  goto :EOF
)

set PKG_VER=1.6.0
set PKG_REV=%~1

set SRC_TAG=1.6.0

rem
rem Replace `Community` with `Enterprise` for Enterprise Edition
rem
set VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall

rem
rem We don't need to set the environment for compiling, but rather
rem just to run CMake and other DevOps tools. Generated project
rem files are set up to use correct compiler flavor for each build
rem type.
rem
call "%VCVARSALL%" x64

rem
rem This project is set up with two sub-modules, one for tests
rem and one for test MMDB databases. This script explicitly
rem excludes tests from the CMake build, so we can get just the
rem main project.
rem
git clone --branch %SRC_TAG% https://github.com/maxmind/libmaxminddb.git libmaxminddb

cd libmaxminddb

rem
rem Build debug and release configurations for x64
rem
mkdir build-x64 && cd build-x64

rem generate project files for the x64 platform
cmake -DBUILD_TESTING=OFF -A x64 ..

rem build both configurations
cmake --build . --config Debug
cmake --build . --config Release

cd ..

rem
rem Build debug and release configurations for Win32
rem
mkdir build-x86 && cd build-x86

cmake -DBUILD_TESTING=OFF -A Win32 ..

cmake --build . --config Debug
cmake --build . --config Release

cd ..\..\

rem
rem Collect all package files in the staging area
rem
mkdir nuget\licenses\
copy /Y libmaxminddb\LICENSE. nuget\licenses\

mkdir nuget\build\native\include\
copy /Y libmaxminddb\include\*.h nuget\build\native\include\

mkdir nuget\build\native\lib\x64\Debug
copy /Y libmaxminddb\build-x64\Debug\maxminddb.lib nuget\build\native\lib\x64\Debug\
copy /Y libmaxminddb\build-x64\Debug\maxminddb.pdb nuget\build\native\lib\x64\Debug\

rem unfortunately, no PDB for the release build, which \help in debugging
mkdir nuget\build\native\lib\x64\Release
copy /Y libmaxminddb\build-x64\Release\maxminddb.lib nuget\build\native\lib\x64\Release\

mkdir nuget\build\native\lib\Win32\Debug
copy /Y libmaxminddb\build-x86\Debug\maxminddb.lib nuget\build\native\lib\Win32\Debug\
copy /Y libmaxminddb\build-x86\Debug\maxminddb.pdb nuget\build\native\lib\Win32\Debug\

mkdir nuget\build\native\lib\Win32\Release
copy /Y libmaxminddb\build-x86\Release\maxminddb.lib nuget\build\native\lib\Win32\Release\

rem
rem Create a package
rem
nuget pack nuget\StoneSteps.MaxMindDB.Static.nuspec -Version %PKG_VER%.%PKG_REV%

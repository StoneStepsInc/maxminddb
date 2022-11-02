@echo off

setlocal

if "%~1" == "" (
  echo Package revision must be provided as the first argument
  goto :EOF
)

set PKG_VER=1.7.1
set PKG_REV=%~1

set MAXMIND_FNAME=libmaxminddb-%PKG_VER%
set MAXMIND_SHA256=e8414f0dedcecbc1f6c31cb65cd81650952ab0677a4d8c49cab603b3b8fb083e

rem
rem Replace `Community` with `Enterprise` for Enterprise Edition
rem
set VCVARSALL=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall
set SEVENZIP_EXE=c:\Program Files\7-Zip\7z.exe

rem
rem We don't need to set the environment for compiling, but rather
rem just to run CMake and other DevOps tools. Generated project
rem files are set up to use correct compiler flavor for each build
rem type.
rem
call "%VCVARSALL%" x64

curl --location --output %MAXMIND_FNAME%.tar.gz https://github.com/maxmind/libmaxminddb/releases/download/%PKG_VER%/%MAXMIND_FNAME%.tar.gz

"%SEVENZIP_EXE%" h -scrcSHA256 %MAXMIND_FNAME%.tar.gz | findstr /C:"SHA256 for data" | call devops\check-sha256 "%MAXMIND_SHA256%"

tar xzf %MAXMIND_FNAME%.tar.gz

cd %MAXMIND_FNAME%

rem
rem Build debug and release configurations for x64
rem
mkdir build\x64

rem generate project files for the x64 platform
cmake -S . -B build\x64 -DBUILD_TESTING=OFF -A x64

rem build both configurations
cmake --build build\x64 --config Debug
cmake --build build\x64 --config Release

rem
rem Build debug and release configurations for Win32
rem
mkdir build\Win32

cmake -S . -B build\Win32 -DBUILD_TESTING=OFF -A Win32

cmake --build build\Win32 --config Debug
cmake --build build\Win32 --config Release

cd ..

rem
rem Collect all package files in the staging area
rem
mkdir nuget\licenses\
copy /Y %MAXMIND_FNAME%\LICENSE. nuget\licenses\

mkdir nuget\build\native\include\
copy /Y %MAXMIND_FNAME%\include\*.h nuget\build\native\include\

mkdir nuget\build\native\lib\x64\Debug
copy /Y %MAXMIND_FNAME%\build\x64\Debug\maxminddb.lib nuget\build\native\lib\x64\Debug\
copy /Y %MAXMIND_FNAME%\build\x64\Debug\maxminddb.pdb nuget\build\native\lib\x64\Debug\

rem unfortunately, no PDB for the release build, which \help in debugging
mkdir nuget\build\native\lib\x64\Release
copy /Y %MAXMIND_FNAME%\build\x64\Release\maxminddb.lib nuget\build\native\lib\x64\Release\

mkdir nuget\build\native\lib\Win32\Debug
copy /Y %MAXMIND_FNAME%\build\Win32\Debug\maxminddb.lib nuget\build\native\lib\Win32\Debug\
copy /Y %MAXMIND_FNAME%\build\Win32\Debug\maxminddb.pdb nuget\build\native\lib\Win32\Debug\

mkdir nuget\build\native\lib\Win32\Release
copy /Y %MAXMIND_FNAME%\build\Win32\Release\maxminddb.lib nuget\build\native\lib\Win32\Release\

rem
rem Create a package
rem
nuget pack nuget\StoneSteps.MaxMindDB.Static.nuspec -Version %PKG_VER%.%PKG_REV%

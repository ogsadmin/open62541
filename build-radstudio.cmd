@echo off
::
:: Prerequisites 
:: ---------------------------------------------------------
::  rem Install vcpkg (what a sh***, this only works if installed to the c:\ root !!!)
::  pushd C:\
::  git clone https://github.com/microsoft/vcpkg.git
::  cd vcpkg
::  .\bootstrap-vcpkg.bat
::  .\vcpkg install check:x64-windows-static
::  .\vcpkg install mbedtls:x64-windows-static
::
rem Set the environment variables
::
set CC_SHORTNAME=msvc
set GENERATOR=Visual Studio 17 2022
::
rem Run the powershell build script...
::
powershell -executionpolicy bypass .\tools\azure-devops\win\build-radstudio.ps1

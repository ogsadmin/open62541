Write-Host -ForegroundColor Green "`n## Build Path $env:Build_Repository_LocalPath #####`n"

$build_encryption = "MBEDTLS"

if ($env:CC_SHORTNAME -eq "vs2008" -or $env:CC_SHORTNAME -eq "vs2013") {
    # on VS2008 mbedtls can not be built since it includes stdint.h which is not available there
    $build_encryption = "OFF"
    Write-Host -ForegroundColor Green "`n## Building without encryption on VS2008 or VS2013 #####`n"
}

if ($env:CC_SHORTNAME -eq "mingw" -or $env:CC_SHORTNAME -eq "clang-mingw") {
    # Workaround for CMake not wanting sh.exe on PATH for MinGW (necessary for CMake 3.12.2)
    $env:PATH = ($env:PATH.Split(';') | Where-Object { $_ -ne 'C:\Program Files\Git\bin' }) -join ';'
    $env:PATH = ($env:PATH.Split(';') | Where-Object { $_ -ne 'C:\Program Files\Git\usr\bin' }) -join ';'
    # Add mingw to path so that CMake finds e.g. clang
    $env:PATH = "$env:MSYS2_ROOT\mingw64\bin;$env:PATH"
    [System.Environment]::SetEnvironmentVariable('Path', $path, 'Machine')
}

$vcpkg_toolchain = ""
$vcpkg_triplet = ""

if ($env:CC_SHORTNAME -eq "mingw") {

} elseif ($env:CC_SHORTNAME -eq "clang-mingw") {
    # Setup clang
    $env:CC = "clang --target=x86_64-w64-mingw32"
    $env:CXX = "clang++ --target=x86_64-w64-mingw32"
    clang --version
} else {
    $vcpkg_toolchain = '-DCMAKE_TOOLCHAIN_FILE="C:/vcpkg/scripts/buildsystems/vcpkg.cmake"'
    #$vcpkg_triplet = '-DVCPKG_TARGET_TRIPLET="x64-windows-static"'
    # we do a 32-bit build:
    $vcpkg_triplet = '-DVCPKG_TARGET_TRIPLET="x86-windows-static"'
}

$cmake_cnf="$vcpkg_toolchain", "$vcpkg_triplet", "-G`"$env:GENERATOR`""

Write-Host -ForegroundColor Green "`n###################################################################"
Write-Host -ForegroundColor Green "`n##### Building RadStudio 32-Bit shared library $env:CC_NAME (.dll) #####`n"
New-Item -ItemType directory -Path "build"

cd build

& cmake $cmake_cnf `
	-DCMAKE_POLICY_VERSION_MINIMUM="3.10" `
        -DBUILD_SHARED_LIBS:BOOL=ON `
	-DUA_BUILD_EXAMPLES:BOOL=ON `
	-DUA_ENABLE_JSON_ENCODING:BOOL=ON `
        -DUA_ENABLE_NODESETLOADER:BOOL=ON `
	-DUA_NAMESPACE_ZERO::STRING="FULL" `
        -DCMAKE_BUILD_TYPE=Debug `
        -DUA_FORCE_WERROR=ON `
        -A Win32 `
        ..
& cmake --build .
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host -ForegroundColor Red "`n`n*** Make failed. Exiting ... ***"
    exit $LASTEXITCODE
}

# Finally, generate the embarcadero radstudio import library 
# (the windows world uses OMF, Embarcadero uses COFF for 32-bit compilers)
# see: https://blogs.embarcadero.com/how-to-achieve-common-tasks-with-the-new-clang-toolchain-in-12-1/#Creating_DLL_Import_Libraries
implib -a bin\Debug\open62541-embt.lib bin\Debug\open62541.dll

cd ..
#Remove-Item -Path build -Recurse -Force

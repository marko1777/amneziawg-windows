@echo off
rem SPDX-License-Identifier: MIT
rem Copyright (C) 2019-2021 WireGuard LLC. All Rights Reserved.

setlocal
set BUILDDIR=%~dp0
set PATH=%BUILDDIR%.deps\llvm-mingw\bin;%BUILDDIR%.deps\go\bin;%PATH%
set PATHEXT=.exe
cd /d %BUILDDIR% || exit /b 1

if exist .deps\prepared goto :build
:installdeps
	rmdir /s /q .deps 2> NUL
	mkdir .deps .deps\lua_x64 .deps\lua_x86 || goto :error
	cd .deps || goto :error
	call :download go.zip https://go.dev/dl/go1.23.0.windows-amd64.zip d4be481ef73079ee0ad46081d278923aa3fd78db1b3cf147172592f73e14c1ac || goto :error
	rem Mirror of https://github.com/mstorsjo/llvm-mingw/releases/download/20201020/llvm-mingw-20201020-msvcrt-x86_64.zip
	call :download llvm-mingw-msvcrt.zip https://download.wireguard.com/windows-toolchain/distfiles/llvm-mingw-20201020-msvcrt-x86_64.zip 2e46593245090df96d15e360e092f0b62b97e93866e0162dca7f93b16722b844 || goto :error
	call :download wintun.zip https://www.wintun.net/builds/wintun-0.14.1.zip 07c256185d6ee3652e09fa55c0b673e2624b565e02c4b9091c79ca7d2f24ef51 || goto :error
    REM have to do this seperatly since there is no way to escape % when you pass it to a subroutine
    curl -fLo lua_x64.zip "https://netix.dl.sourceforge.net/project/luabinaries/5.1.5/Windows%%20Libraries/Dynamic/lua-5.1.5_Win64_dll17_lib.zip?viasf=1"
    call :extract_clean lua_x64.zip lua_x64 || goto :error
    curl -flo lua_x86.zip "https://unlimited.dl.sourceforge.net/project/luabinaries/5.1.5/Windows%%20Libraries/Dynamic/lua-5.1.5_Win32_dll17_lib.zip?viasf=1"
    call :extract_clean lua_x86.zip lua_x86 || goto :error
	copy /y NUL prepared > NUL || goto :error
	cd .. || goto :error

:build
	set GOOS=windows
	set GOARM=7
	set GOPATH=%BUILDDIR%.deps\gopath
	set GOROOT=%BUILDDIR%.deps\go
	set CGO_ENABLED=1
	set CGO_CFLAGS=-O3 -Wall -Wno-unused-function -Wno-switch -std=gnu11 -DWINVER=0x0601
	REM set CGO_LDFLAGS=-LC:/tools/lua/ -LC:/tools/luajit-build/ -Wl,--dynamicbase -Wl,--nxcompat -Wl,--export-all-symbols
    set CGO_LDFLAGS=-Wl,--dynamicbase -Wl,--nxcompat -Wl,--export-all-symbols
	set CGO_LDFLAGS=%CGO_LDFLAGS% -Wl,--high-entropy-va
	call :build_plat x64 x86_64 amd64 || goto :error
	call :build_plat x86 i686 386 || goto :error

:success
	echo [+] Success
	exit /b 0

:download
	echo [+] Downloading %1 %2
	curl -#fLo %1 %2 || exit /b 1
    echo [+] Verifying %1
    for /f %%a in ('CertUtil -hashfile %1 SHA256 ^| findstr /r "^[0-9a-f]*$"') do if not "%%a"=="%~3" exit /b 1
	echo [+] Extracting %1
    tar -xf %1 || exit /b 1
	echo [+] Cleaning up %1
	del %1 || exit /b 1
	goto :eof

:extract_clean
	echo [+] Extracting %1
    tar -xf %1 -C %2/ || exit /b 1
	echo [+] Cleaning up %1
	del %1 || exit /b 1
	goto :eof

:build_plat
    if not exist "%~1\luajit-build" (
        echo [+] Building luajit %1

        REM del .deps\src\*.exe .deps\src\*.o .deps\src\wincompat\*.o .deps\src\wincompat\*.lib 2> NUL
        REM set LDFLAGS=-s
        REM mingw32-make -C .deps\luajit PLATFORM=windows CC=%~2-w64-mingw32-gcc WINDRES=%~2-w64-mingw32-windres V=1 RUNSTATEDIR= SYSTEMDUNITDIR= -j%NUMBER_OF_PROCESSORS% || exit /b 1
        REM mingw32-make -C .deps\luajit\src PLATFORM=windows -j%NUMBER_OF_PROCESSORS%
        REM make --no-print-directory -C .deps\src PLATFORM=windows CC=%~2-w64-mingw32-gcc WINDRES=%~2-w64-mingw32-windres V=1 RUNSTATEDIR= SYSTEMDUNITDIR= -j%NUMBER_OF_PROCESSORS% || exit /b 1
        REM move /Y .deps\src\awg.exe "%~1\awg.exe" > NUL || exit /b 1
    )
	set CC=%~2-w64-mingw32-gcc
	set GOARCH=%~3
	mkdir %1 >NUL 2>&1
	set CGO_LDFLAGS=-L%BUILDDIR%.deps\lua_%1\include -LC:/tools/luajit-build
	echo [+] Building library %1
	go build  -tags "luajit" -buildmode c-shared -ldflags="-w -s" -trimpath -v -o "%~1/tunnel.dll" || exit /b 1
	del "%~1\tunnel.h"
	goto :eof

:error
	echo [-] Failed with error #%errorlevel%.
	cmd /c exit %errorlevel%


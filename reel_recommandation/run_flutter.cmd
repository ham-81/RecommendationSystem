@echo off
setlocal EnableDelayedExpansion

:: Set up the VS 2022 Build Tools environment for 64-bit architecture
IF EXIST "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) ELSE (
    echo Visual Studio 2022 Build Tools not found.
)

:: Run flutter
flutter run -d windows

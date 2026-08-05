@echo off
REM ---------------------------------------------------------------------------
REM Fallback: rebuild avra.exe from the vendored source using MSVC.
REM Normally you don't need this -- windows\avra\avra.exe is committed. Use this
REM only to regenerate the binary (e.g. after editing the source). Requires
REM Visual Studio with "Desktop development with C++".
REM Output: windows\avra\avra.exe
REM ---------------------------------------------------------------------------
setlocal
set "REPO=%~dp0..\.."
set "SRC=%REPO%\common\build-avra\avra-src"
set "COMPAT=%REPO%\common\build-avra\compat"
set "OUTDIR=%REPO%\windows\avra"
set "OBJ=%~dp0obj"

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
  echo ERROR: vswhere not found. Install Visual Studio with C++ tools,
  echo        or just use the committed windows\avra\avra.exe.
  exit /b 1
)
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * ^
  -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
  -property installationPath`) do set "VSPATH=%%i"
if "%VSPATH%"=="" (
  echo ERROR: no VC++ toolset found. Install "Desktop development with C++".
  exit /b 1
)

call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat" >nul
if not exist "%OBJ%" mkdir "%OBJ%"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

REM compat\unistd.h shim lets avra's single unlink() build under MSVC.
cl /nologo /O2 /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_WARNINGS ^
   /I "%COMPAT%" "%SRC%\*.c" /Fe:"%OUTDIR%\avra.exe" /Fo"%OBJ%\\"
set RC=%ERRORLEVEL%
endlocal & exit /b %RC%

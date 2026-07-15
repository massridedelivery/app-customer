@echo off
REM Windows wrapper so `make <target>` works from cmd/PowerShell.
REM Delegates to GNU make against the repo Makefile (single source of truth).
REM Requires GNU make (GnuWin32). Install: winget install GnuWin32.Make
setlocal
where make.exe >nul 2>nul
if %errorlevel%==0 (
  make.exe -f "%~dp0Makefile" %*
) else if exist "C:\Program Files (x86)\GnuWin32\bin\make.exe" (
  "C:\Program Files (x86)\GnuWin32\bin\make.exe" -f "%~dp0Makefile" %*
) else (
  echo [make.bat] GNU make not found. Install it with: winget install GnuWin32.Make
  echo            Or run directly: flutter run --flavor dev --dart-define-from-file=env/dev.json
  exit /b 1
)

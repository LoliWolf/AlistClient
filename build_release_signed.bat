@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

echo [INFO] Project root: %CD%

set "JAVA17_HOME=C:\Program Files\Java\jdk-17"
if exist "%JAVA17_HOME%\bin\java.exe" (
  set "JAVA_HOME=%JAVA17_HOME%"
  set "PATH=%JAVA_HOME%\bin;%PATH%"
  echo [INFO] Using JAVA_HOME=!JAVA_HOME!
) else (
  echo [ERROR] Java 17 not found at "%JAVA17_HOME%".
  echo [ERROR] Please install JDK 17 at this path, then rerun this script.
  goto :fail
)

set "FVM_BAT=%LOCALAPPDATA%\Pub\Cache\bin\fvm.bat"
set "FVM_CONFIG=.fvm\fvm_config.json"
set "USE_FVM=0"
set "FVM_SDK_VERSION="
if exist "%FVM_CONFIG%" (
  if exist "%FVM_BAT%" (
    set "USE_FVM=1"
    echo [INFO] Using FVM: %FVM_BAT%
    for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "(Get-Content '%FVM_CONFIG%' | ConvertFrom-Json).flutterSdkVersion"`) do (
      set "FVM_SDK_VERSION=%%v"
    )
    if defined FVM_SDK_VERSION (
      echo [INFO] FVM target SDK: !FVM_SDK_VERSION!
    ) else (
      echo [WARN] Could not read flutterSdkVersion from %FVM_CONFIG%, fallback to system flutter.
      set "USE_FVM=0"
    )
  ) else (
    echo [WARN] .fvm found but fvm.bat not found in Pub Cache, fallback to flutter.
  )
)

if "%USE_FVM%"=="1" (
  echo [STEP 0/4] ensure FVM SDK installed
  call "%FVM_BAT%" list | findstr /I /C:"!FVM_SDK_VERSION!" >nul
  if errorlevel 1 (
    echo [INFO] Installing Flutter SDK !FVM_SDK_VERSION! via FVM...
    call "%FVM_BAT%" install !FVM_SDK_VERSION!
    if errorlevel 1 goto :fail
  ) else (
    echo [INFO] Flutter SDK !FVM_SDK_VERSION! already installed.
  )
)

echo [STEP 1/4] pub get
if "%USE_FVM%"=="1" (
  call "%FVM_BAT%" flutter pub get
) else (
  call flutter pub get
)
if errorlevel 1 goto :fail

echo [STEP 2/4] build release apk
if "%USE_FVM%"=="1" (
  call "%FVM_BAT%" flutter build apk --release
) else (
  call flutter build apk --release
)
if errorlevel 1 goto :fail

set "APK_DIR=%CD%\build\app\outputs\flutter-apk"
set "RELEASE_APK=%APK_DIR%\app-release.apk"
set "SIGNED_APK=%APK_DIR%\app-release-signed.apk"
set "ALIGNED_APK=%APK_DIR%\app-release-aligned.apk"

if not exist "%RELEASE_APK%" (
  echo [ERROR] Release APK not found: %RELEASE_APK%
  goto :fail
)

set "ANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk"
if not exist "%ANDROID_SDK_ROOT%\build-tools" (
  echo [ERROR] Android build-tools not found: %ANDROID_SDK_ROOT%\build-tools
  goto :fail
)

set "LATEST_BT="
for /f "delims=" %%d in ('dir /b /ad "%ANDROID_SDK_ROOT%\build-tools" ^| sort /r') do (
  if not defined LATEST_BT set "LATEST_BT=%%d"
)
if not defined LATEST_BT (
  echo [ERROR] No build-tools version found.
  goto :fail
)

set "APK_SIGNER=%ANDROID_SDK_ROOT%\build-tools\%LATEST_BT%\apksigner.bat"
set "ZIPALIGN=%ANDROID_SDK_ROOT%\build-tools\%LATEST_BT%\zipalign.exe"

if not exist "%APK_SIGNER%" (
  echo [ERROR] apksigner not found: %APK_SIGNER%
  goto :fail
)
if not exist "%ZIPALIGN%" (
  echo [ERROR] zipalign not found: %ZIPALIGN%
  goto :fail
)

echo [STEP 3/4] verify app-release.apk signature
call "%APK_SIGNER%" verify "%RELEASE_APK%" >nul 2>&1
if not errorlevel 1 (
  copy /Y "%RELEASE_APK%" "%SIGNED_APK%" >nul
  echo [INFO] app-release.apk is already signed.
  goto :done
)

echo [STEP 4/4] sign release apk with debug keystore fallback
set "DEBUG_KEYSTORE=%USERPROFILE%\.android\debug.keystore"
if not exist "%DEBUG_KEYSTORE%" (
  echo [ERROR] Debug keystore not found: %DEBUG_KEYSTORE%
  echo [ERROR] Configure release keystore in android/local.properties or create debug keystore first.
  goto :fail
)

"%ZIPALIGN%" -f 4 "%RELEASE_APK%" "%ALIGNED_APK%"
if errorlevel 1 goto :fail

call "%APK_SIGNER%" sign ^
  --ks "%DEBUG_KEYSTORE%" ^
  --ks-key-alias androiddebugkey ^
  --ks-pass pass:android ^
  --key-pass pass:android ^
  --out "%SIGNED_APK%" ^
  "%ALIGNED_APK%"
if errorlevel 1 goto :fail

call "%APK_SIGNER%" verify --verbose "%SIGNED_APK%"
if errorlevel 1 goto :fail

:done
echo [SUCCESS] Signed release APK:
echo %SIGNED_APK%
exit /b 0

:fail
echo [FAILED] Build or signing failed.
exit /b 1

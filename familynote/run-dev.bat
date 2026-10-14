@echo off
rem Starts FamilyNote in Chrome using familynote\dart_defines.json (git-ignored).
rem The project folder has an apostrophe, so map it to a drive letter first.
if not exist T:\familynote (
  subst T: "%~dp0.."
)
if not exist T:\familynote\dart_defines.json (
  echo Missing dart_defines.json. Copy dart_defines.example.json to dart_defines.json and paste the anon key.
  pause
  exit /b 1
)
set PATH=C:\Users\danil\dev\flutter\bin;%PATH%
cd /d T:\familynote
flutter run -d chrome --dart-define-from-file=dart_defines.json

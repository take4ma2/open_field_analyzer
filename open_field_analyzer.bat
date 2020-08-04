@echo off

echo %1
echo %~dp0

if exist %1 goto EXECUTE else goto USAGE


:EXECUTE
cd /d %~dp0
ruby open_field_analyzer.rb %1

goto EXIT

:USAGE
echo "Drag and Drop Open Field XY data files included directory on this batch file"

:EXIT
pause

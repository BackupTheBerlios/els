@echo off

echo Welcome to the Easy Linux Server !
echo.
net use F: \\LINUX\APP
net use G: \\LINUX\DAT
net use H: \\LINUX\HOME
net use I: \\LINUX\DAT
net time \\LINUX /set /yes

rem nbtstat -s >>G:\TRANSFER\STATUS.TXT
rem mem        >>G:\TRANSFER\STATUS.TXT

if exist h:logon.bat h:logon.bat

@echo off

echo Welcome to the Easy Linux Server !
echo.
net use F: \\SERVER\APP
net use G: \\SERVER\DAT
net use H: \\SERVER\HOME
net use I: \\SERVER\DAT
net time \\SERVER /set /yes

if exist h:logon.bat h:logon.bat

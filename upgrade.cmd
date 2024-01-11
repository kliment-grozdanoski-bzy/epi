@ECHO OFF
IF /I "%1" == "" ( GOTO latest)


GOTO specific_release

:specific_release
CALL powershell -ExecutionPolicy RemoteSigned -Command "%cd%\upgrade.ps1 -Release %*;"
GOTO finished

:latest 
CALL powershell -ExecutionPolicy RemoteSigned -Command "%cd%\upgrade.ps1;"
GOTO finished

:finished
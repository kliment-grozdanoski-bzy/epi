@ECHO OFF

REM You can enable these variables on your local machine to aid local development, once
REM you have added your keys etc do NOT push back to git. To stop git from detecting a
REM change you can stop tracking this file in SourceTree or via bash with this command:
REM     git update-index --assume-unchanged build.cmd
REM and if you want to start tracking again use
REM     git update-index --no-assume-unchanged build.cmd

REM SET Octopus_Server=http://octopusdeploy.bfl.local
REM SET Octopus_API_Key=YOUR_KEY
REM SET Nuget_Deployments_Server=http://nugetdeployments.bfl.local
REM SET Nuget_Deployments_Api_Key=YOUR_KEY
REM SET nuget_server=http://nuget.bfl.local
REM SET nuget_api_key=YOUR_KEY
REM SET BUILD_NUMBER=0.0.2
REM SET db_project_name=template-powerbi-reports
REM SET GITHUB_ENTERPRISE_TOKEN = YOUR_KEY
REM SET GitHub_Endpoint=http://git.bfl.local/api/v3
REM SET Branch_Name=master





REM Setup the whole environment after initial clone of the repo, only needs to be run ONCE
IF /I "%1" == "FIRST" ( GOTO install_prerequisites )

REM Initialsation that prepares the build environment ready for rake (or other tools) to operate
IF /I "%1" == "INIT" ( GOTO initialise )

REM All other calls go to the standard runner
GOTO standard_command


:install_prerequisites

    ECHO Preparing for first run - Setting up all prerequisites (this only needs to be run once)...
    ECHO.
    ECHO Setting Build.cmd as git assume unchanged
    CALL git update-index --assume-unchanged build.cmd
   
    CALL :initialise
   
    ECHO.
    ECHO Development setup completed, environment ready for developement!
    ECHO.
    GOTO finished

:initialise

    ECHO Initialising build environment, please wait...
    ECHO.
	
	ECHO Preparing build tools...
    IF EXIST "BuildTools.DB" RD "BuildTools.DB" /S /Q
    MKDIR "BuildTools.DB"
	COPY \\alddevap21\Software\Nuget\.net4.5\Nuget.exe BuildTools.DB\Nuget.exe
    CALL BuildTools.DB\Nuget.exe install "BuildTools.DB" -Source http://nuget.bfl.local/api/v2 -ExcludeVersion
	ECHO.
	ECHO Preparing environment...
    CALL powershell -ExecutionPolicy RemoteSigned -Command "%cd%\build.ps1 -Install"
    ECHO.
    ECHO Build initialisation completed, environment ready for build instructions!
    ECHO.
    GOTO :eof

:standard_command
    
    CALL  powershell -ExecutionPolicy RemoteSigned -Command "%cd%\build.ps1 %*;"

:finished
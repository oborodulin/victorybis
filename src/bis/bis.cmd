@Echo Off
rem {Copyright}
rem {License}
rem �������� �������� ������������� � ��������� �������� ������ ������� Victory BIS
rem ���������: ������ �������� ��� ����������

setlocal EnableExtensions EnableDelayedExpansion

if /i "%EXEC_MODE%" NEQ "%EM_TST%" cls

:run_tests
rem ������������ �������� � ��� ���������
set g_script_name=%~nx0
set g_script_name=%g_script_name:cmd-win1251.cmd=exe%
set g_script_header=Victory BIS for Windows 7/10 {Current_Version}. {Copyright} {Current_Date}

rem ������������� ��� ����������� ��������� � ������� ��� ������ �������, � ��������� �� ������������
call :bis_setup %*
call :bis_check_setup
if ERRORLEVEL 1 endlocal & exit /b 1
rem ���� ������� ������������ �� ����� ��� ������ ��� ����� LL_INF, �� ���������� ���������
if not defined p_log_level goto pkg_menu_loop
if %p_log_level% LEQ %LL_INF% goto pkg_menu_loop
rem ����� (� ��� �� ��� ������ ������������ LL_DBG) - ����������� ���������� �� ����������� ���������
call :choice_process "" ProcessingSetup
if ERRORLEVEL %NO% call :echo -ri:SetupAbort & endlocal & exit /b 0

rem ���� ����������� ���� ������ ������������ �������
:pkg_menu_loop
call :packages_menu "%p_pkg_name%" "%p_pkg_choice%" g_pkg_cfg_file g_pkg_name g_pkg_descr use_log g_log_level
rem "�����"
if ERRORLEVEL 1 endlocal & exit /b 0

rem ���� ���������� ������������ ��� � ������, �� ������������� ���������
if "%use_log%" EQU "" set use_log=p_use_log
if "%g_log_level%" EQU "" set g_log_level=p_log_level

call :trim %g_pkg_name% g_pkg_name
call :echo -rv:"%g_pkg_cfg_file% %g_pkg_name% %g_pkg_descr% %use_log% %g_log_level%" -rl:5FINE

rem ���������� ����� ������� ���������
call :get_pkg_dirs "%g_pkg_name%"

rem ��� �������������, ���� ������ ������������ � ������, �������������� ����� ���-���� �� ��������
if /i "%use_log%" EQU "%VL_TRUE%" (
	if not exist "!pkgs[%g_pkg_name%]#LogDir!" 1>nul MD "!pkgs[%g_pkg_name%]#LogDir!"
	set g_log_file=!pkgs[%g_pkg_name%]#LogDir!/%g_pkg_name%.log
)
rem ���� ����������� ���� ������ �������
:mod_menu_loop
 
call :modules_menu "%p_mod_name%" "%p_mod_choice%" "%g_pkg_name%" "%g_pkg_descr%" g_mod_name g_mod_ver

rem "���������� ��� ������"
if ERRORLEVEL 3 call :echo -ri:FuncNotImpl & endlocal & exit /b 0
rem "�������"
if ERRORLEVEL 2 goto pkg_menu_loop
rem "�����"
if ERRORLEVEL 1 endlocal & exit /b 0

call :echo -rv:"%g_mod_name% %g_mod_ver%" -rl:5FINE

call :echo -ri:CfgFile -v1:"%g_pkg_cfg_file%"
call :echo -ri:SetupDir -v1:"!pkgs[%g_pkg_name%]#SetupDir!"

call :execute_module "%p_exec_choice%" "%g_pkg_name%" "%g_mod_name%" "%g_mod_ver%"
if ERRORLEVEL 1 (
	set l_em_res=%ERRORLEVEL%
	echo from execute_module return code: "!l_em_res!"
	pause
	exit /b !l_em_res!
)
rem ���������� �������� ����� � ��������� ������� ����������� ��������������
set p_pkg_choice=
set p_mod_choice=
set p_exec_choice=
set p_pkg_name=
set p_mod_name=

goto mod_menu_loop

endlocal & exit /b 0

rem =======================================================================================
rem ��� ��� � �������� ������������ ���������� �������� ���������� Errorlevel �� Choice, �� 
rem ��� �������������� � ������������� ������������ ������������

rem ---------------------------------------------
rem ����������� ���� ������������ �������
rem ����������: g_pkg_cfg_file g_pkg_name g_pkg_descr use_log g_log_level
rem ---------------------------------------------
:packages_menu _def_pkg_name _pkg_choice
if /i "%EXEC_MODE%" EQU "%EM_RUN%" CLS
set _def_pkg_name=%~1
set _pkg_choice=%~2
set l_delay=%DEF_DELAY%
set l_choice=
if "%_def_pkg_name%" EQU "" (
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -be:1
	call :echo -rf:"%menus_file%" -ri:ChoicePackage -v1:%l_delay% -rc:0E
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -ae:1
)
rem ���� ������ �� ������� ��� ��������
if defined g_pkg_cnt (
rem ������� ��
	for /l %%p in (1,1,%g_pkg_cnt%) do (
		call :echo -rv:"%%p - !g_pkg[%%p]#Name!	!g_pkg[%%p]#Descr!" -rc:0F -cp:65001 -rs:8
		set l_choice=!l_choice!%%p
	)
 	set /a "x=%g_pkg_cnt%+1"
) else (
	pushd "%bis_config_dir%"
	1>nul chcp 65001
	call :get_res_val -rf:"%xpaths_file%" -ri:XPathPkgs
	set "x=1" 
	rem �������� �����, �������� � ������ ������������ ���� ������� �� ������ ������������ � ���������������� ��������
	for /F %%i in ('dir *.xml /b /o:n /a-d') do (
		set l_pkg_cfg_file=%%i
		for /F "tokens=1-4 delims=	()" %%a in ('%xml_sel_% "!res_val!" -v "./name" -o "	(" -v "./description" -o ")	" -v "./useLog" -o "	" -v "./logLevel" -n "%bis_config_dir%/!l_pkg_cfg_file!"') do (
			set l_pkg_name=%%~a
			set l_pkg_descr=%%~b
			call :trim !l_pkg_name! l_trim_pkg_name

			if "%_def_pkg_name%" EQU "" call :echo -rv:"!x! - !l_pkg_name!	!l_pkg_descr!" -rc:0F -cp:65001 -rs:8
			set g_pkg[!x!]#File=!l_pkg_cfg_file!
			set g_pkg[!x!]#Name=!l_pkg_name!
			set g_pkg[!x!]#Descr=!l_pkg_descr!
			set g_pkg[!x!]#UseLog=%%~c
			set g_pkg[!x!]#LogLevel=%%~d
			if /i "%_def_pkg_name%" EQU "!l_trim_pkg_name!" set _pkg_choice=!x!
		)
		set l_choice=!l_choice!!x!
	 	set /a "x+=1"
	)
	popd
	set /a "g_pkg_cnt=!x!-1"
)
set l_choice=!l_choice!!x!
1>nul chcp 1251
if "%_def_pkg_name%" EQU "" call :echo -rf:"%menus_file%" -ri:ActionDefExit -v1:%x% -rc:0D -rs:8 -be:1 -ae:1

rem ���� �������� ����� ������ ������ �� ���������
if "%_pkg_choice%" NEQ "" set "pkg_num=%_pkg_choice%" & goto package_def

call :get_res_val -rf:"%menus_file%" -ri:EnterPkgChoice -v1:%x%
call :choice_process "" "" %l_delay% %x% "%res_val%" "%l_choice%"
set pkg_num=%ERRORLEVEL%

if %pkg_num% GEQ %x% exit /b 1

:package_def
for /f "usebackq delims==# tokens=1-3" %%j in (`set g_pkg[%pkg_num%]`) do (
	rem echo %%j %%k %%l
	set l_pkg_cur#%%k=%%l
) 
set %3=%bis_config_dir%/%l_pkg_cur#File%
set %4=%l_pkg_cur#Name%
set %5=%l_pkg_cur#Descr%
set %6=%l_pkg_cur#UseLog%
set %7=%l_pkg_cur#LogLevel%
exit /b 0

rem ---------------------------------------------
rem ����������� ���� ������� ��������� ������
rem ����������: g_mod_name g_mod_ver
rem (�������������: 	mods[%_mod_name%]#SetupDir
rem 					mods[%_mod_name%]#BinDirCnt
rem 					mods[%_mod_name%]#BinDirs[i]
rem 					mods[%_mod_name%]#HomeEnv
rem 					mods[%_mod_name%]#HomeDir
rem						mods[%_mod_name%]#Installed)
rem ---------------------------------------------
:modules_menu _def_mod_name _mod_choice _pkg_name _pkg_descr
set _def_mod_name=%~1
set _mod_choice=%~2
set _pkg_name=%~3
set _pkg_descr=%~4
if /i "%EXEC_MODE%" EQU "%EM_RUN%" CLS
set l_delay=%DEF_DELAY%
set l_choice=

if "%_def_mod_name%" EQU "" (
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -be:1
	call :echo -rf:"%menus_file%" -ri:ChoiceModule -v1:%l_delay% -rc:0E
	call :echo -rv:"%_pkg_name% [%_pkg_descr%]" -rc:0E
	call :echo -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0E -ae:1
)
pushd "%bis_config_dir%"
1>nul chcp 65001
set "x=1"
rem �������� ����� � ������ ���� ������� � �������� ������
call :get_res_val -rf:"%xpaths_file%" -ri:XPathMods
for /F "tokens=1-3 delims=	" %%a in ('%xml_sel_% "!res_val!" -v "./name" -o "	" -v "./version" -o "	" -v "./description" -n "%g_pkg_cfg_file%"') do (
	set l_mod_name=%%a
	set l_mod_name=!l_mod_name:~0,10!
	set l_mod_ver=%%b
	set l_mod_ver=!l_mod_ver:~0,12!
	set l_mod_descr=%%c

	if "%_def_mod_name%" EQU "" call :echo -rv:"%BS%         !x! - !l_mod_name! v.!l_mod_ver! " -rc:0F -cp:65001 -ln:%VL_FALSE%
	rem �������� ������� ��������� ������, ��� ������� �������� ������ � �������� �������
	call :get_mod_install_dirs "%_pkg_name%" "!l_mod_name!" "!l_mod_ver!"
	rem ���������� ���������� �� ��� ������
	call :is_mod_installed "!l_mod_name!" "!l_mod_ver!"
	rem ���� ������ ����������, ��������� � ������ ��������� ������ � �������
	if "%_def_mod_name%" EQU "" (
		if ERRORLEVEL 1 call :echo -rv:"[+]" -rc:0D -ln:%VL_FALSE%
		call :echo -rv:"!l_mod_descr!" -rc:0F -cp:65001 -rs:8
	)
	set g_mod[!x!]#Name=!l_mod_name!
	set g_mod[!x!]#Ver=!l_mod_ver!
	if /i "%_def_mod_name%" EQU "!l_mod_name!" set _mod_choice=!x!
	set l_choice=!l_choice!!x!
 	set /a "x+=1"
)
popd
set all_num=%x%
set l_choice=!l_choice!!x!
1>nul chcp 1251
if "%_def_mod_name%" EQU "" call :echo -rf:"%menus_file%" -ri:SetupAllModules -v1:%all_num% -rc:0D -rs:9 -be:1

set /a "x+=1"
set ret_pkg=%x%
set l_choice=!l_choice!!x!
if "%_def_mod_name%" EQU "" call :echo -rf:"%menus_file%" -ri:ActionReturnToPkgMenu -v1:%ret_pkg% -rc:0D -rs:9

set /a "x+=1"
set l_choice=!l_choice!!x!
if "%_def_mod_name%" EQU "" call :echo -rf:"%menus_file%" -ri:ActionExit -v1:%x% -rc:0D -rs:9 -ae:1

rem ���� �������� ����� ������ ������ �� ���������
if "%_mod_choice%" NEQ "" set "mod_num=%_mod_choice%" & goto module_def

call :get_res_val -rf:"%menus_file%" -ri:EnterModChoice -v1:%x%
call :choice_process "" "" %l_delay% %ret_pkg% "%res_val%" "%l_choice%"
set mod_num=%ERRORLEVEL%

if %mod_num% GEQ %x% exit /b 1
if %mod_num% GEQ %ret_pkg% exit /b 2
if %mod_num% GEQ %all_num% exit /b 3

:module_def
for /f "usebackq delims==# tokens=1-3,*" %%j in (`set g_mod[%mod_num%]`) do set l_mod_cur#%%k=%%l%%m

set %5=%l_mod_cur#Name%
set %6=%l_mod_cur#Ver%
exit /b 0

rem ---------------------------------------------
rem ���������� ������� ��������� ������
rem (�������������: 	pkgs[%_pkg_name%]#SetupDir
rem 					pkgs[%_pkg_name%]#LogDir
rem 					pkgs[%_pkg_name%]#DistribDir
rem 					pkgs[%_pkg_name%]#BackupDataDir
rem 					pkgs[%_pkg_name%]#BackupConfigDir)
rem ---------------------------------------------
:get_pkg_dirs _pkg_name
set _pkg_name=%~1

call :get_res_val -rf:"%xpaths_file%" -ri:XPathOSParams
for /F "tokens=1-5" %%a in ('%xml_sel_% "!res_val!" -v "concat(./setupDir, substring('%EMPTY_NODE%', 1 div not(./setupDir)))" -o "	" -v "concat(./distribDir, substring('%EMPTY_NODE%', 1 div not(./distribDir)))" -o "	" -v "concat(./backupDataDir, substring('%EMPTY_NODE%', 1 div not(./backupDataDir)))" -o "	" -v "concat(./backupConfigDir, substring('%EMPTY_NODE%', 1 div not(./backupConfigDir)))" -o "	" -v "concat(./logDir, substring('%EMPTY_NODE%', 1 div not(./logDir)))" -n "%g_pkg_cfg_file%"') do (
	set pkgs[%_pkg_name%]#SetupDir=%%~a
	call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#SetupDir!" pkgs[%_pkg_name%]#SetupDir
	if "%%~b" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#DistribDir=%%~b
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#DistribDir!" pkgs[%_pkg_name%]#DistribDir
	) else (
		set pkgs[%_pkg_name%]#DistribDir=%bis_distrib_dir%/%_pkg_name%
	)
	if "%%~c" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#BackupDataDir=%%~c
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#BackupDataDir!" pkgs[%_pkg_name%]#BackupDataDir
	) else (
		set pkgs[%_pkg_name%]#BackupDataDir=%bis_backup_data_dir%
	)
	if "%%~d" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#BackupConfigDir=%%~d
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#BackupConfigDir!" pkgs[%_pkg_name%]#BackupConfigDir
	) else (
		set pkgs[%_pkg_name%]#BackupConfigDir=%bis_backup_config_dir%
	)
	if "%%~e" NEQ "%EMPTY_NODE%" (
		set pkgs[%_pkg_name%]#LogDir=%%~e
		call :binding_var "%_pkg_name%" "" "!pkgs[%_pkg_name%]#LogDir!" pkgs[%_pkg_name%]#LogDir
	) else (
		set pkgs[%_pkg_name%]#LogDir=%bis_log_dir%
	)
)
call :echo -ri:PkgSetupDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#SetupDir!"
call :echo -ri:PkgLogDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#LogDir!"
call :echo -ri:PkgDistribDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#DistribDir!"
call :echo -ri:PkgBackupDataDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#BackupDataDir!"
call :echo -ri:PkgBackupConfigDir -v1:%_pkg_name% -v2:"!pkgs[%_pkg_name%]#BackupConfigDir!"
exit /b 0

rem ---------------------------------------------
rem ��������� ��������� ��������� ������
rem (�������������: 	mods[%_mod_name%]#DistribDir)
rem ---------------------------------------------
:execute_module
set _exec_choice=%~1
set _pkg_name=%~2
set _mod_name=%~3
set _mod_ver=%~4

rem �������� ������� ��������� ������, ��� ������� �������� ������ � �������� �������
call :get_mod_install_dirs "%_pkg_name%" "%_mod_name%" "%_mod_ver%"

rem ���������� ������� ������������ ������ (������ ���� �������� �� :execute_choice)
set mods[%_mod_name%]#DistribDir=!pkgs[%_pkg_name%]#DistribDir!/%_mod_name%/%_mod_ver%

rem ���������� ���������� �� ��� ������
call :is_mod_installed "%_mod_name%" "%_mod_ver%"
rem ���� ������ ����������, ��������� � ������ ��������� ������ � �������
if /i "%EXEC_MODE%" EQU "%EM_RUN%" cls
if ERRORLEVEL 1 endlocal & call :execute_choice "%_exec_choice%" "%_pkg_name%" "%_mod_name%" "%_mod_ver%" & exit /b !ERRORLEVEL!

rem ��������� ��� ���� ������
call :execute_mod_phases "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
exit /b 0

rem ---------------------------------------------
rem ��������� ��� ���� ��������� ������
rem ---------------------------------------------
:execute_mod_phases
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem �������� ���� ����������
call :get_mod_phases "%_mod_name%" "%_mod_ver%"
rem ������ �� ����� ����� � ������� ����������
for /l %%n in (0,1,!mods[%_mod_name%]#PhaseCnt!) do ( 
	call :get_exec_code
	if ERRORLEVEL %CODE_RUN% (
		call :execute_phase "!mods[%_mod_name%]#Phase[%%n]@Id!" "!mods[%_mod_name%]#Phase[%%n]@Name!" "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
		if ERRORLEVEL 1 exit /b %ERRORLEVEL%
	)
) 
exit /b 0

rem ---------------------------------------------
rem �������� ���� ��������� ��������� ������
rem (�������������: 	mods[%_mod_name%]#Phase[!ps!]@Id
rem 					mods[%_mod_name%]#Phase[!ps!]@Name)
rem ---------------------------------------------
:get_mod_phases _mod_name _mod_ver
set _mod_name=%~1
set _mod_ver=%~2

if defined mods[%_mod_name%]#PhaseCnt exit /b 0
rem �������� ���� ������
set "ps=0"
call :get_res_val -rf:"%xpaths_file%" -ri:XPathModExecs -v1:"%_mod_name%" -v2:"%_mod_ver%"
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./phase" -o "	" -v "./id" -n "%g_pkg_cfg_file%"') do (
	set l_phase=%%~a
	if "%%b" NEQ "" (
		set l_phase_id=%%~b
	) else (
		set l_phase_id=%_mod_name%-!l_phase!
	)
	set mods[%_mod_name%]#Phase[!ps!]@Id=!l_phase_id!
	set mods[%_mod_name%]#Phase[!ps!]@Name=!l_phase!
	set /a "ps+=1"
)
set /a "ps-=1"
set mods[%_mod_name%]#PhaseCnt=%ps%
exit /b 0

rem ---------------------------------------------
rem ��������� �������� ����
rem ---------------------------------------------
:execute_phase
setlocal
set _phase_id=%~1
set _phase=%~2
set _pkg_name=%~3
set _mod_name=%~4
set _mod_ver=%~5

call :echo -ri:ExecPhaseId -v1:"%_phase_id%" -ae:1
call :choice_process "%_phase_id%" ProcessingPhase
if ERRORLEVEL %NO% call :echo -ri:PhaseExecAbort -v1:"%_phase_id%" & endlocal & exit /b 0
if /i "%_phase%" EQU "%PH_DOWNLOAD%" call :phase_download "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
if /i "%_phase%" EQU "%PH_INSTALL%" call :phase_install "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
if /i "%_phase%" EQU "%PH_CONFIG%" call :phase_config "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem ���������� ��������� ����������� ��������� ������
rem (�������������: 	mods[%_mod_name%]#DistribUrl
rem 					mods[%_mod_name%]#DistribFile
rem 					mods[%_mod_name%]#DistribPath)
rem ---------------------------------------------
:get_mod_distrib_params _mod_name _mod_ver
set _mod_name=%~1
set _mod_ver=%~2

if defined mods[%_mod_name%]#DistribUrl exit /b 0
rem �������� URL ������������ � ��� ��� �����
call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseDownload -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:%proc_arch%
for /F "tokens=1,2" %%a in ('%xml_sel_% "%res_val%" -v "../distribUrl" -o "	" -v "../distribFile" -n "%g_pkg_cfg_file%"') do (
	set mods[%_mod_name%]#DistribUrl=%%~a
	if "%%~b" NEQ "" (
		set mods[%_mod_name%]#DistribFile=%%~b
	) else (
		set mods[%_mod_name%]#DistribFile=%%~nxa
	)
)
rem ���������� ���� � ������������ ������
set mods[%_mod_name%]#DistribPath=!mods[%_mod_name%]#DistribDir!/!mods[%_mod_name%]#DistribFile!
exit /b 0

rem ====================================================================================================================
rem ���� ����������:
rem ====================================================================================================================

rem ---------------------------------------------
rem ��������� ������������� ������������ ������
rem ---------------------------------------------
:phase_download _pkg_name _mod_name _mod_ver
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

call :get_mod_distrib_params "%_mod_name%" "%_mod_ver%"

setlocal
call :echo -ri:ModDistribUrl -v1:%_mod_name% -v2:"!mods[%_mod_name%]#DistribUrl!"
call :echo -ri:ModDistribPath -v1:%_mod_name% -v2:"!mods[%_mod_name%]#DistribPath!"

if not exist "!mods[%_mod_name%]#DistribPath!" goto exec_download

call :echo -ri:ModDistribFound -v1:!mods[%_mod_name%]#DistribPath! -rc:0F

call :choice_process "%~0" UseExistDistrib %SHORT_DELAY%
if %choice% EQU %YES% call :echo -ri:ProcessingAbort -v1:%process% & endlocal & exit /b 0

:exec_download
rem ���� ��� �������� ������������ ������, �� ������ ���
if not exist "!mods[%_mod_name%]#DistribDir!" 1>nul MD "!mods[%_mod_name%]#DistribDir!"

rem ��������� �� URL'� �������� ������������ ������ � ��� �������
call :download "%curl_%" "!mods[%_mod_name%]#DistribUrl!" "!mods[%_mod_name%]#DistribPath!"

endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem ������������ ����������� ��������� ����������
rem ---------------------------------------------
:phase_install
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

call :get_mod_distrib_params "%_mod_name%" "%_mod_ver%"
rem ���� �� ������ ����������� ������
if not exist "!mods[%_mod_name%]#DistribPath!" call :echo -ri:DistribPathExistError -v1:"!mods[%_mod_name%]#DistribPath!" -v2:"%_mod_name%" & endlocal & exit /b 1

rem ���� ����� ������� ��������� ������ � ��� ���, �� ������ ���
if "!mods[%_mod_name%]#SetupDir!" NEQ "" if not exist "!mods[%_mod_name%]#SetupDir!" (
	call :echo -ri:CreateModSetupDir -v1:"%_mod_name%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	1>nul MD "!mods[%_mod_name%]#SetupDir!"
	call :echo -ri:ResultOk -rc:0A
)
rem ���� ������ ����������, ��������� � ���������� ������� �����
call :is_mod_installed "%_mod_name%" "%_mod_ver%"
if ERRORLEVEL 1 goto implicit_goals
rem ����� �������� ���� ���� ���������
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_INSTALL%" goals_cnt
rem ������ �� ����� ����� � ������� ����������
for /l %%n in (0,1,%goals_cnt%) do ( 
	set install_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!install_goal!" -ae:1
	if /i "!install_goal!" EQU "%GL_UNPACK_7Z_SFX%" call :goal_unpack_7z_sfx "%_mod_name%"
	if /i "!install_goal!" EQU "%GL_UNPACK_ZIP%" call :goal_unpack_zip "%_mod_name%"
	if /i "!install_goal!" EQU "%GL_SILENT%" call :goal_silent %PH_INSTALL% "%_mod_name%" "%_mod_ver%"
	if /i "!install_goal!" EQU "%GL_CMD_SHELL%" (
		call :get_exec_name "%~0"
		call :goal_cmd_shell "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!exec_name!"
	)
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 
:implicit_goals
rem ������ ������� �����
call :goal_add_path_env "%_mod_name%"
if "!mods[%_mod_name%]#HomeEnv!" NEQ "" call :goal_add_env "!mods[%_mod_name%]#HomeEnv!" "!mods[%_mod_name%]#HomeDir!"
set l_result=%ERRORLEVEL%

endlocal & (set "mods[%_mod_name%]#Installed=1" & exit /b %l_result%)

rem ---------------------------------------------
rem ���������� �������� ������: ���������,
rem ����������� ������ � ��������
rem (�������������: 	mods[%_mod_name%]#SetupDir
rem 			mods[%_mod_name%]#BinDirCnt
rem 			mods[%_mod_name%]#BinDirs[i]
rem 			mods[%_mod_name%]#HomeEnv
rem 			mods[%_mod_name%]#HomeDir)
rem ---------------------------------------------
:get_mod_install_dirs
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
rem �������� ������� ��������� ������ � ��� �������� �������
if not defined mods[%_mod_name%]#SetupDir if not defined mods[%_mod_name%]#HomeDir (
	call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseConfig -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:%PH_INSTALL%
	for /F "tokens=1-3" %%a in ('%xml_sel_% "!res_val!" -v "concat(./modSetupDir, substring('%EMPTY_NODE%', 1 div not(./modSetupDir)))" -o "	" -v "concat(./modHomeDir/envVar, substring('%EMPTY_NODE%', 1 div not(./modHomeDir/envVar)))" -o "	" -v "concat(./modHomeDir/directory, substring('%EMPTY_NODE%', 1 div not(./modHomeDir/directory)))" -n "%g_pkg_cfg_file%"') do (
		if "%%a" NEQ "%EMPTY_NODE%" set mods[%_mod_name%]#SetupDir=%%~a
		if "%%b" NEQ "%EMPTY_NODE%" set mods[%_mod_name%]#HomeEnv=%%~b
		if "%%c" NEQ "%EMPTY_NODE%" set mods[%_mod_name%]#HomeDir=%%~c
	)
	if defined mods[%_mod_name%]#SetupDir call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#SetupDir!" mods[%_mod_name%]#SetupDir
	if defined mods[%_mod_name%]#HomeDir call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#HomeDir!" mods[%_mod_name%]#HomeDir
	
	call :echo -ri:ModSetupDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#SetupDir!"
	call :echo -ri:ModHomeDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#HomeEnv!" -v3:"!mods[%_mod_name%]#HomeDir!"
)
rem �������� �������� �������� ������ ������
if not defined mods[%_mod_name%]#BinDirCnt (
	call :get_res_val -rf:"%xpaths_file%" -ri:XPathModBinDirs -v1:"%_mod_name%" -v2:"%_mod_ver%"
	set "i=0"
	for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -n "%g_pkg_cfg_file%"') do (
		set mods[%_mod_name%]#BinDirs[!i!]=%%~a
		set /a "i+=1"
	)
	set /a l_bin_dirs_cnt=!i!-1
	set mods[%_mod_name%]#BinDirCnt=!l_bin_dirs_cnt!
	for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
		call :binding_var "%_pkg_name%" "%_mod_name%" "!mods[%_mod_name%]#BinDirs[%%j]!" mods[%_mod_name%]#BinDirs[%%j]
		call :echo -ri:ModBinDir -v1:%_mod_name% -v2:"!mods[%_mod_name%]#BinDirs[%%j]!"
	)
)
exit /b 0

rem ---------------------------------------------
rem ���������� ���������� �� ��� ������ ��:
rem - ������� �������� �������� ������� � ��� �������� ���������
rem - ������ �������
rem (�������������: 	mods[%_mod_name%]#Installed)
rem ---------------------------------------------
:is_mod_installed
set _mod_name=%~1
set _mod_ver=%~2

if defined mods[%_mod_name%]#Installed exit /b !mods[%_mod_name%]#Installed!

setlocal
call :echo -ri:CheckModInstalled -v1:"%_mod_name%" -rl:0FILE
if "!mods[%_mod_name%]#SetupDir!" NEQ "" (
	call :echo -ri:CheckModInstalledFS -v1:"!mods[%_mod_name%]#SetupDir!" -rl:0FILE
	if exist "!mods[%_mod_name%]#SetupDir!" for /F "usebackq" %%f IN (`dir "!mods[%_mod_name%]#SetupDir!/" /b /A:`) do (
		call :echo -ri:ResultYes -rl:0FILE
		endlocal & set mods[%_mod_name%]#Installed=1
		exit /b 1
	)
)
call :get_res_val -rf:"%xpaths_file%" -ri:XPathInstallVer -v1:"%_mod_name%" -v2:"%_mod_ver%"
for /F "tokens=1,2" %%i in ('%xml_sel_% "!res_val!" -v "./regKey" -o "	" -v "./regParam" -n "%g_pkg_cfg_file%"') do (
        set l_regKey=%%i
	set l_regParam=%%j
	call :echo -ri:CheckModInstalledReg -v1:"!l_regKey!" -v2:"!l_regParam!" -rl:0FILE
	call :reg -oc:%RC_GET% -kn:"!l_regKey!" -vn:"!l_regParam!"
	if "!reg!" NEQ "" (
		call :echo -ri:ResultYes -rl:0FILE
		call :echo -ri:RegModVersion -v1:"%_mod_name%" -v2:"!reg!" -rl:0FILE
		endlocal & set mods[%_mod_name%]#Installed=1
		exit /b 1
	)
)
call :echo -ri:ResultNo -rl:0FILE
endlocal & set mods[%_mod_name%]#Installed=0
exit /b 0

rem ---------------------------------------------
rem �������� ���� �������� ����
rem ����������: goals_cnt
rem (�������������: 	phase_goals[x])
rem ---------------------------------------------
:get_phase_goals _mod_name _mod_ver _phase goals_cnt
set _mod_name=%~1
set _mod_ver=%~2
set _phase=%~3

rem �������� ���� ���� ���������
call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseGoals -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_phase%"
set "x=0"
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./goal" -n "%g_pkg_cfg_file%"') do (
	set phase_goals[!x!]=%%a
	set /a "x+=1"
)
set /a "x-=1"
set %4=%x%
exit /b 0

rem ---------------------------------------------
rem ��������� �������� � ��� ������������� �������
rem ---------------------------------------------
:execute_choice
set _exec_choice=%~1
set _pkg_name=%~2
set _mod_name=%~3
set _mod_ver=%~4

set l_delay=%DEF_DELAY%
set l_choice=
call :echo -rf:"%menus_file%" -ri:ExecModChoice -v1:"%_mod_name%" -v2:%l_delay% -rc:0E -be:1
rem �������� ���� ����������
call :get_mod_phases "%_mod_name%" "%_mod_ver%"
rem ������ �� ����� ����� � ������� ����������
set "x=1" 
for /l %%n in (0,1,!mods[%_mod_name%]#PhaseCnt!) do ( 
	set l_mod_choice[!x!]#Phase=!mods[%_mod_name%]#Phase[%%n]@Name!
	set l_mod_choice[!x!]#Id=!mods[%_mod_name%]#Phase[%%n]@Id!
	
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_INSTALL%" (
		call :echo -rf:"%menus_file%" -ri:RepairModSetup -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_CONFIG%" (
		call :echo -rf:"%menus_file%" -ri:ApplyModConfig -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_BACKUP%" (
		call :echo -rf:"%menus_file%" -ri:BackupRestore -v1:!x! -rc:0F -rs:8
		set l_choice=!l_choice!!x!
 		set /a "x+=1"
	)
	if /i "!mods[%_mod_name%]#Phase[%%n]@Name!" EQU "%PH_UNINSTALL%" (
		set "l_phase_uninstall_id=!mods[%_mod_name%]#Phase[%%n]@Id!"
		set "phase_uninstall_exist=%VL_TRUE%"
	)
)
rem ���������� ������������� �� ���������
set l_mod_choice[!x!]#Phase=%PH_UNINSTALL%
if defined l_phase_uninstall_id (
	set l_mod_choice[!x!]#Id=!l_phase_uninstall_id!
) else (
	set l_mod_choice[!x!]#Id=%_mod_name%-%PH_UNINSTALL% [%PH_INSTALL%]
)
set l_phase_uninstall_id=
set l_choice=!l_choice!!x!
call :echo -rf:"%menus_file%" -ri:UninstallMod -v1:%x% -rc:0F -rs:8

set /a "x+=1"
set l_choice=!l_choice!!x!
call :echo -rf:"%menus_file%" -ri:ActionNo -v1:%x% -rc:0F -rs:8 -ae:1

rem ���� �������� ����� ���������� �� ���������
if "%_exec_choice%" NEQ "" set "exec_num=%_exec_choice%" & goto execute_def

call :get_res_val -rf:"%menus_file%" -ri:ChoiceModExec
call :choice_process "" "" %l_delay% %x% "%res_val%" "%l_choice%"
set exec_num=%ERRORLEVEL%

if %exec_num% GEQ %x% exit /b 0

:execute_def
for /f "usebackq delims==# tokens=1-3,*" %%j in (`set l_mod_choice[%exec_num%]`) do (
	rem echo %%j %%k %%l
	set l_mod_choice_cur#%%k=%%l%%m
) 
call :echo -ri:ExecPhaseId -v1:"%l_mod_choice_cur#Id%" -ae:1
rem ���� ������� "����������� ���������", �� �� ����������� ���������� ���������� ����
if /i "%l_mod_choice_cur#Phase%" EQU "%PH_INSTALL%" goto continue_execute_choice

call :choice_process "%l_mod_choice_cur#Phase%" ProcessingPhase
if ERRORLEVEL %NO% call :echo -ri:PhaseExecAbort -v1:"%l_mod_choice_cur#Phase%" & exit /b 0

:continue_execute_choice
if /i "%l_mod_choice_cur#Phase%" EQU "%PH_INSTALL%" (
	rem ��������� ��� ���� ������
	call :execute_mod_phases "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_CONFIG%" (
	call :phase_config "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_BACKUP%" (
	call :phase_backup "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
) else if /i "%l_mod_choice_cur#Phase%" EQU "%PH_UNINSTALL%" (
	rem �������� ������� ��������� ������, ��� ������� �������� ������ � �������� �������
rem	call :get_mod_install_dirs "%_mod_name%" "%_mod_ver%"
	rem �������� �������������� �������� ����� �� ������ ������� ���������

	rem ���� ���� ���� �������������, �� �������� ������������� �� ���, ����� - �� ���� �����������
	if /i "%phase_uninstall_exist%" EQU "%VL_TRUE%" (
		call :phase_uninstall "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
	) else (
		call :phase_module_uninstall "%_pkg_name%" "%_mod_name%" "%_mod_ver%"
	)
)
if ERRORLEVEL 1 exit /b %ERRORLEVEL%
exit /b 0

rem ---------------------------------------------
rem ��������� ������������ ��������� ������
rem ---------------------------------------------
:phase_config
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem �������������� ������� �����
call :goal_backup_config "%_mod_name%" "%_mod_ver%"

rem �������� ���� ���� ������������
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_CONFIG%" goals_cnt

rem ������ �� ����� ����� � ������� ����������
for /l %%n in (0,1,%goals_cnt%) do ( 
	set config_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!config_goal!" & echo.
	if /i "!config_goal!" EQU "%GL_CMD_SHELL%" (
		call :get_exec_name "%~0"
		call :goal_cmd_shell "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!exec_name!"
	)
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 
rem �������������� ������� �����
rem �������� ��� � �������������� ������ ����������������� ����� ������
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCfgFile -v1:"%_mod_name%" -v2:"%_mod_ver%"
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./name" -o "	" -v "./comment" -n "%g_pkg_cfg_file%"') do (
	set l_config_file=%%a
	set l_comment=%%b
	call :goal_apply_cfg_prms "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "!l_config_file!" "!l_comment!"
)
endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem �����������/��������������� ������ ������
rem ---------------------------------------------
:phase_backup
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

call :echo -ri:DefFuncNotImpl -v1:"%~0" & endlocal & exit /b 0

call :echo -ri:AddPathEnv -v1:%_dir% -rc:0F -ln:%VL_FALSE%
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem �������������� ������ �������� ���� �������������
rem ---------------------------------------------
:phase_uninstall
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem �������� ���� ���� �������������
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_UNINSTALL%" goals_cnt
rem ������ �� ����� ����� � ������� ����������
for /l %%n in (0,1,%goals_cnt%) do ( 
	set uninstall_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!uninstall_goal!" -ae:1
	if /i "!uninstall_goal!" EQU "%GL_UNINSTALL_PORTABLE%" call :goal_uninstall_portable "%_mod_name%"
	if /i "!uninstall_goal!" EQU "%GL_SILENT%" call :goal_silent %PH_UNINSTALL% "%_mod_name%" "%_mod_ver%"
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 
rem ������ ������� �����
call :goal_del_path_env "%_mod_name%"
if "!mods[%_mod_name%]#HomeEnv!" NEQ "" call :goal_del_env "!mods[%_mod_name%]#HomeEnv!"
set l_result=%ERRORLEVEL%

endlocal & (set "mods[%_mod_name%]#Installed=0" & exit /b %l_result%)

rem ---------------------------------------------
rem �������������� ������ �������� ���� �����������
rem ---------------------------------------------
:phase_module_uninstall
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3

rem �������� ���� ���� ���������
call :get_phase_goals "%_mod_name%" "%_mod_ver%" "%PH_INSTALL%" goals_cnt
rem ������ �� ����� ����� � �������� �������
for /l %%n in (%goals_cnt%,-1,0) do ( 
	set uninstall_goal=!phase_goals[%%n]!
	call :echo -ri:ExecGoal -v1:"!uninstall_goal!"
	if /i "!uninstall_goal!" EQU "%GL_UNPACK_7Z_SFX%" call :goal_uninstall_portable "%_mod_name%"
	if /i "!uninstall_goal!" EQU "%GL_UNPACK_ZIP%" call :goal_uninstall_portable "%_mod_name%"
	if /i "!uninstall_goal!" EQU "%GL_SILENT%" call :goal_silent %PH_UNINSTALL% "%_mod_name%" "%_mod_ver%"
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%
) 
rem ������ ������� �����
call :goal_del_path_env "%_mod_name%"
if "!mods[%_mod_name%]#HomeEnv!" NEQ "" call :goal_del_env "!mods[%_mod_name%]#HomeEnv!"
set l_result=%ERRORLEVEL%

endlocal & (set "mods[%_mod_name%]#Installed=0" & exit /b %l_result%)

rem ====================================================================================================================
rem ����:
rem ====================================================================================================================

rem ---------------------------------------------
rem ������������� 7-zip ��������������������� �����
rem ---------------------------------------------
:goal_unpack_7z_sfx
setlocal
set _mod_name=%~1

rem ��������: �� ����� ��� ����������� ������� ���������
if "!mods[%_mod_name%]#SetupDir!" EQU "" call :echo -ri:ModSetupDirParamError -v1:"%_mod_name%" & endlocal & exit /b 1
if not exist "!mods[%_mod_name%]#SetupDir!" call :echo -ri:ModSetupDirExistError -v1:"!mods[%_mod_name%]#SetupDir!" -v2:"%_mod_name%" & endlocal & exit /b 1

call :echo -ri:Unpack7zSfx -v1:!mods[%_mod_name%]#DistribFile! -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%

call :get_res_val -ri:UnpackDistribFile -v1:"!mods[%_mod_name%]#DistribFile!"
start "%res_val%" /D "!mods[%_mod_name%]#SetupDir!" /WAIT "!mods[%_mod_name%]#DistribPath!" -y
rem -gm2 -InstallPath="!mods[%_mod_name%]#SetupDir!"
rem -y -o"!mods[%_mod_name%]#SetupDir!"
call :echo -ri:ResultOk -rc:0A

call :echo -ri:DefUnpackDir -rc:0F -ln:%VL_FALSE%
rem ��� ��� ���������� ����������� � ������� ������������, �� �������, ������� � ��� ��������� � ������, ����� ������ ������������
pushd "!mods[%_mod_name%]#DistribDir!" 
set "x=0" 
for /F %%i in ('dir * /b') do if /i "%%i" NEQ "!mods[%_mod_name%]#DistribFile!" set /a "x+=1" & set l_src_obj=%%i
rem echo %x% %l_src_obj%
call :echo -ri:ResultOk -rc:0A
rem ���� ��������� ��������� ���������� ������ ������ ��������
if %x% EQU 1 (
	call :echo -ri:MoveModDistribSetupDir -v1:"!mods[%_mod_name%]#DistribDir!/%l_src_obj%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	1>nul %copy_% "!mods[%_mod_name%]#DistribDir!/%l_src_obj%" "!mods[%_mod_name%]#SetupDir!" /E /MOVE
	call :echo -ri:ResultOk -rc:0A
) else if %x% GTR 1 (
	rem ����� ��������� ��� �������� � �����, ����� ������������
	call :echo -ri:MoveUnpackSetupDir -v1:"!mods[%_mod_name%]#DistribDir!" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%
	for /F %%i in ('dir * /b') do if /i "%%i" NEQ "!mods[%_mod_name%]#DistribFile!" 1>nul move "!mods[%_mod_name%]#DistribDir!/%%i" "!mods[%_mod_name%]#SetupDir!"
	call :echo -ri:ResultOk -rc:0A
)
popd
endlocal & exit /b 0

rem ---------------------------------------------
rem ����� �����������/������������� ������������
rem ---------------------------------------------
:goal_silent
setlocal
set _phase=%~1
set _mod_name=%~2
set _mod_ver=%~3

if /i "%_phase%" EQU "%PH_INSTALL%" (
	call :echo -ri:SilentInstall -v1:!mods[%_mod_name%]#DistribFile! -rc:0F -ln:%VL_FALSE%
	call :get_res_val -ri:InstallDistribFile -v1:"!mods[%_mod_name%]#DistribFile!" & set goal_title=!res_val!
)
if /i "%_phase%" EQU "%PH_UNINSTALL%" (
	call :echo -ri:SilentUninstall -v1:%_mod_name% -rc:0F -ln:%VL_FALSE%
	call :get_res_val -ri:UninstallDistribFile -v1:"!mods[%_mod_name%]#DistribFile!" & set goal_title=!res_val!
)
call :get_res_val -rf:"%xpaths_file%" -ri:XPathPhaseConfig -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:%_phase%
for /F "tokens=*" %%a in ('%xml_sel_% "!res_val!" -v "./keys" -n "%g_pkg_cfg_file%"') do (
	set l_keys=%%a
)
call :echo -ri:SilentKeys -v1:!mods[%_mod_name%]#DistribFile! -v2:"%l_keys%"

echo start "%goal_title%" /WAIT "!mods[%_mod_name%]#DistribPath!" "%l_keys%"

call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0

rem ---------------------------------------------
rem ������������� zip-�����
rem ---------------------------------------------
:goal_unpack_zip
setlocal
set _mod_name=%~1

rem ��������: �� ����� ��� ����������� ������� ���������
if "!mods[%_mod_name%]#SetupDir!" EQU "" call :echo -ri:ModSetupDirParamError -v1:"%_mod_name%" & endlocal & exit /b 1
if not exist "!mods[%_mod_name%]#SetupDir!" call :echo -ri:ModSetupDirExistError -v1:"!mods[%_mod_name%]#SetupDir!" -v2:"%_mod_name%" & endlocal & exit /b 1

call :echo -ri:UnpackZip -v1:!mods[%_mod_name%]#DistribFile! -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F -ln:%VL_FALSE%

call :get_exec_name "%~0"
call :get_res_val -ri:UnpackDistribFile -v1:"!mods[%_mod_name%]#DistribFile!"
start "%res_val%" /WAIT "%z7_%" x "!mods[%_mod_name%]#DistribPath!" -o"!mods[%_mod_name%]#SetupDir!" -r 1> "%bis_log_dir%\%_mod_name%-%exec_name%.log" 2>&1

call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0

rem ---------------------------------------------
rem ������� ������� ������������ ����������
rem ---------------------------------------------
:goal_uninstall_portable
setlocal
set _mod_name=%~1

rem ���� ���� ������� ��������� ������, �� ������� ���
if not exist "!mods[%_mod_name%]#SetupDir!" endlocal & exit /b 1

call :echo -ri:DelModSetupDir -v1:"%_mod_name%" -v2:"!mods[%_mod_name%]#SetupDir!" -rc:0F

call :choice_process "%~0" DelExistModSetupDir %DEF_DELAY% N
if ERRORLEVEL %NO% call :echo -ri:ProcessingAbort -v1:%process% & endlocal & exit /b 0

1>nul RD /S /Q "!mods[%_mod_name%]#SetupDir!"
call :echo -ri:ResultOk -rc:0A

endlocal & exit /b 0

rem ---------------------------------------------
rem ��������� �������� ���� � ���������� ����� PATH
rem (���������� ������� ���� � ����������� ���������� 
rem �� �� ��������)
rem ---------------------------------------------
:goal_add_path_env
setlocal
set _mod_name=%~1

call :print_exec_name "%~0"
rem ���� ���� �� ���� ������� �� ����������, �� �� ���� �� ���������
for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	if not exist "!mods[%_mod_name%]#BinDirs[%%j]!" call :echo -ri:PathDirExistError -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" & endlocal & exit /b 1
)
rem ����� � ������ �������� ������� ������������ �����
call :get_reg_value "" "%RH_HKCU%" PATH
set l_paths=!reg_value!
:paths_loop
for /f "tokens=1* delims=;" %%i in ("%l_paths%") do (
	set l_path=%%i
	set $check_path=!l_path:%_mod_name%=!
	if "!$check_path!" NEQ "!l_path!" (
		call :get_res_val -rf:"%menus_file%" -ri:ExistModPathEnv -v1:"%_mod_name%" -v2:"!l_path!" -v3:%DEF_DELAY%
		call :choice_process "" "" %DEF_DELAY% N "!res_val!"
		if !choice! EQU %YES% (
			call :echo -ri:DelPathEnv -v1:"!l_path!" -rc:0F -ln:%VL_FALSE%
			call :reg -oc:%RC_DEL% -vn:PATH -vv:"!l_path!"
			call :echo -ri:ResultOk -rc:0A
		)
	)
	set l_paths=%%j
)
if defined l_paths goto :paths_loop
rem ���������� �����
for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	call :echo -ri:AddPathEnv -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" -rc:0F -ln:%VL_FALSE%
	call :convert_case %CM_LOWER% "!mods[%_mod_name%]#BinDirs[%%j]!" l_bin_dir
	call :convert_slashes %CSD_WIN% "!l_bin_dir!" l_bin_dir
	call :reg -oc:%RC_ADD% -vn:PATH -vv:"!l_bin_dir!"
	call :echo -ri:ResultOk -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ������� �������� ���� �� ���������� ����� PATH
rem ---------------------------------------------
:goal_del_path_env
setlocal
set _mod_name=%~1

call :print_exec_name "%~0"

for /l %%j in (0,1,!mods[%_mod_name%]#BinDirCnt!) do (
	call :echo -ri:DelPathEnv -v1:"!mods[%_mod_name%]#BinDirs[%%j]!" -rc:0F -ln:%VL_FALSE%
	call :convert_case %CM_LOWER% "!mods[%_mod_name%]#BinDirs[%%j]!" l_bin_dir
	call :reg -oc:%RC_DEL% -vn:PATH -vv:"!l_bin_dir!"
	call :echo -ri:ResultOk -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ��������� ���������� ����� � �������� ���������
rem ---------------------------------------------
:goal_add_env
setlocal
set _env=%~1
set _val=%~2

call :print_exec_name "%~0"

call :echo -ri:AddEnv -v1:"%_env%" -v2:"%_val%" -rc:0F -ln:%VL_FALSE%
rem call :reg -oc:%RC_SET% -vn:"%_env%" -vv:"%_val%"
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem ������� ���������� ����� � �������� ������
rem ---------------------------------------------
:goal_del_env
setlocal
set _env=%~1

call :print_exec_name "%~0"

call :echo -ri:DelEnv -v1:"%_env%" -rc:0F -ln:%VL_FALSE%
rem call :reg -oc:%RC_DEL% -vn:"%_env%"
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem ��������� ������� ���������� ����������
rem ---------------------------------------------
:goal_cmd_shell
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
rem �������� ������� ����������
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdCommands -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%"
set "copy_num=0"
set "move_num=0"
set "md_num=0"
for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "name()" -n "%g_pkg_cfg_file%"') do (
	set l_cmd=%%a
	if /i "!l_cmd!" EQU "COPY" set /a "copy_num+=1" & call :cmd_copy "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" !copy_num!
	if /i "!l_cmd!" EQU "MOVE" set /a "move_num+=1" & call :cmd_move "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" !move_num!
	if /i "!l_cmd!" EQU "MD" set /a "md_num+=1" & call :cmd_md "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" !md_num!
	if /i "!l_cmd!" EQU "BATCH" call :cmd_batch "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%"
)
endlocal & exit /b %ERRORLEVEL%

rem ---------------------------------------------
rem �������� �������� ������� �������� ������� �� 
rem �������� ��������� � ������� ����������
rem ---------------------------------------------
:cmd_copy
setlocal EnableExtensions EnableDelayedExpansion
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
set _copy_num=%~5

call :echo -ri:CmdCopy -rc:0F -ln:%VL_FALSE%

rem �������� ���� ������ ����������
call :get_cmd_objects XPathCmdCopySrc "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_copy_num% l_src_dir l_src_paths src_cnt

rem �������� ���� ������ ����������
call :get_cmd_objects XPathCmdCopyDst "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_copy_num% l_dst_dir l_dst_paths dst_cnt

rem ��������:
call :get_exec_name "%~0"
call :validate_src_dst_cnts "!exec_name!" %src_cnt% %dst_cnt%
if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

rem ����������:
rem ���� ������� ������ ������� �������� � ������� ����������
if %src_cnt% EQU -1 if %dst_cnt% EQU -1 (
	call :echo -ri:CmdCopyMoveObjects -v1:"%l_src_dir%" -v2:"%l_dst_dir%"
	if not exist "%l_src_dir%" call :echo -ri:SrcDirExistError -v1:"%l_src_dir%" & endlocal & exit /b 1
	1>nul %copy_% "%l_src_dir%" "%l_dst_dir%" /E
	call :echo -ri:ResultCountOk -v1:1 -rc:0A
)
rem ���� ������� ����� ��������� � ������� ����������
if %src_cnt% GTR -1 if %dst_cnt% EQU -1 (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"%l_dst_dir%"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		if not exist "%l_dst_dir%" call :echo -ri:DstDirExistError -v1:"%l_dst_dir%" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "%l_dst_dir%" l_dst_dir
		1>nul copy /y "!l_src_paths[%%n]!" "!l_dst_dir!"
	)
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
) 
rem ���� ������� ����� ��������� � ��������������� ���-�� ������ ����������
if %src_cnt% GTR -1 if %dst_cnt% EQU %src_cnt% (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"!l_dst_paths[%%n]!"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		for /f %%l in ("!l_dst_paths[%%n]!") do set l_dst_dir=%%~dpl
		if not exist "!l_dst_dir!" call :echo -ri:DstDirExistError -v1:"!l_dst_dir!" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
		1>nul copy /y "!l_src_paths[%%n]!" "!l_dst_paths[%%n]!"
	) 
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
)
rem ���� ������ ���� ���� �������� � ��������� ������ ����������
if %src_cnt% EQU 0 if %dst_cnt% GTR %src_cnt% (
	call :convert_slashes %CSD_WIN% "!l_src_paths[0]!" l_src_paths[0]
	for /l %%n in (0,1,%dst_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[0]!" -v2:"!l_dst_paths[%%n]!"
		if not exist "!l_src_paths[0]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[0]!" & endlocal & exit /b 1
		for /f %%l in ("!l_dst_paths[%%n]!") do set l_dst_dir=%%~dpl
		if not exist "!l_dst_dir!" call :echo -ri:DstDirExistError -v1:"!l_dst_dir!" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
		1>nul copy /y "!l_src_paths[0]!" "!l_dst_paths[%%n]!"
	) 
	set /a "obj_cnt=%dst_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� �������� ������� �������� ������� �� 
rem �������� ��������� � ������� ����������
rem ---------------------------------------------
:cmd_move
setlocal EnableExtensions EnableDelayedExpansion
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
set _move_num=%~5

call :echo -ri:CmdMove -rc:0F -ln:%VL_FALSE%

rem �������� ���� ������ ����������
call :get_cmd_objects XPathCmdCopySrc "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_move_num% l_src_dir l_src_paths src_cnt

rem �������� ���� ������ ����������
call :get_cmd_objects XPathCmdCopyDst "%_pkg_name%" "%_mod_name%" "%_mod_ver%" "%_exec_name%" %_move_num% l_dst_dir l_dst_paths dst_cnt

rem ��������:
call :get_exec_name "%~0"
call :validate_src_dst_cnts "!exec_name!" %src_cnt% %dst_cnt%
if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

rem ����������:
rem ���� ������� ������ ������� �������� � ������� ����������
if %src_cnt% EQU -1 if %dst_cnt% EQU -1 (
	call :echo -ri:CmdCopyMoveObjects -v1:"%l_src_dir%" -v2:"%l_dst_dir%"
	if not exist "%l_src_dir%" call :echo -ri:SrcDirExistError -v1:"%l_src_dir%" & endlocal & exit /b 1
	1>nul %copy_% "%l_src_dir%" "%l_dst_dir%" /E /MOVE
	call :echo -ri:ResultCountOk -v1:1 -rc:0A
)
rem ���� ������� ����� ��������� � ������� ����������
if %src_cnt% GTR -1 if %dst_cnt% EQU -1 (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"%l_dst_dir%"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		if not exist "%l_dst_dir%" call :echo -ri:DstDirExistError -v1:"%l_dst_dir%" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "%l_dst_dir%" l_dst_dir
		1>nul move /y "!l_src_paths[%%n]!" "!l_dst_dir!"
	)
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
) 
rem ���� ������� ����� ��������� � ��������������� ���-�� ������ ����������
if %src_cnt% GTR -1 if %dst_cnt% EQU %src_cnt% (
	for /l %%n in (0,1,%src_cnt%) do ( 
		call :echo -ri:CmdCopyMoveObjects -v1:"!l_src_paths[%%n]!" -v2:"!l_dst_paths[%%n]!"
		if not exist "!l_src_paths[%%n]!" call :echo -ri:SrcFileExistError -v1:"!l_src_paths[%%n]!" & endlocal & exit /b 1
		for /f %%l in ("!l_dst_paths[%%n]!") do set l_dst_dir=%%~dpl
		if not exist "!l_dst_dir!" call :echo -ri:DstDirExistError -v1:"!l_dst_dir!" & endlocal & exit /b 1
		call :convert_slashes %CSD_WIN% "!l_src_paths[%%n]!" l_src_paths[%%n]
		call :convert_slashes %CSD_WIN% "!l_dst_paths[%%n]!" l_dst_paths[%%n]
		1>nul move /y "!l_src_paths[%%n]!" "!l_dst_paths[%%n]!"
	) 
	set /a "obj_cnt=%src_cnt%+1"
	call :echo -ri:ResultCountOk -v1:!obj_cnt! -rc:0A
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ������ �������� � ������������ ��������
rem ---------------------------------------------
:cmd_md
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4
set _md_num=%~5

call :echo -ri:CmdMd -rc:0F -ln:%VL_FALSE%
rem �������� ��������
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdMdDirs -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%" -v4:%_md_num%
set "i=0"
for /F "tokens=1" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -n "%g_pkg_cfg_file%"') do (
	set l_dir=%%~a

	call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" l_dir
	rem if not exist "!l_dir!" 1>nul MD "!l_dir!" & call :echo -ri:CmdCopyMoveObjects -v1:"!l_dir!"
	set /a "i+=1"
)
call :echo -ri:ResultCountOk -v1:%i% -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem ��������� ��������� �������
rem ---------------------------------------------
:cmd_batch
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _exec_name=%~4

call :echo -ri:CmdBatch -rc:0F
rem -ln:%VL_FALSE%
rem �������� �������
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCmdBatch -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%"
set "i=0"
for /F "tokens=*" %%a in ('%xml_sel_% "!res_val!" -v "./exec" -n "%g_pkg_cfg_file%"') do (
	set l_exec_cmd=%%~a
	call :binding_var "" "" "!l_exec_cmd!" l_exec_cmd
	if !ERRORLEVEL! EQU 0 (
		call :echo -ri:CmdBatchExec -v1:"!l_exec_cmd!" -ln:%VL_FALSE% -rl:5FINE
		call !l_exec_cmd!
		set l_exec_res=!ERRORLEVEL!
		if !l_exec_res! NEQ 0 (
			call :echo -ri:ResultFailNum -v1:"!l_exec_res!" -rl:5FINE
		) else (
			call :echo -ri:ResultOk -rc:0A -rl:5FINE
		)
		set /a "i+=1"
	)
)
call :echo -ri:ResultCountOk -v1:%i% -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� ������� ��������� ��� ����������
rem ��������� �������� (cmd-shell)
rem ---------------------------------------------
:get_cmd_objects
set _res_id=%~1
set _pkg_name=%~2
set _mod_name=%~3
set _mod_ver=%~4
set _exec_name=%~5
set _cmd_num=%~6

set "i=0"
rem set /a "%9=%i%-1"
call :get_res_val -rf:"%xpaths_file%" -ri:%_res_id% -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_exec_name%" -v4:%_cmd_num%
for /F "tokens=1,2" %%a in ('%xml_sel_% "!res_val!" -v "./directory" -o "	" -v "./includes/include" -n "%g_pkg_cfg_file%"') do (
	set l_dir=%%a
	set l_file=%%b

	if "!l_file!" EQU "" call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" %7 & exit /b 0
	if "!l_file!" EQU "*" call :binding_var "%_pkg_name%" "%_mod_name%" "!l_dir!" %7 & exit /b 0

	set "%8[!i!]=!l_dir!/!l_file!"
	set /a "i+=1"
)
set /a "%9=%i%-1"
for /l %%n in (0,1,%9) do call :binding_var "%_pkg_name%" "%_mod_name%" "!%8[%%n]!" %8[%%n]
exit /b 0

rem ---------------------------------------------
rem ��������� ������������ ���������� �������� ����������
rem � �������� ���������� �������� ������� (cmd-shell)
rem ---------------------------------------------
:validate_src_dst_cnts
setlocal
set _exec_name=%~1
set _src_cnt=%~2
set _dst_cnt=%~3

rem ���� �� ������� ����� ���������, �� ������� ����� ����������, �� ������
if %_src_cnt% EQU -1 if %_dst_cnt% NEQ -1 call :echo -ri:CmdSrcEmptyError -v1:%_dst_cnt% -v2:"%_exec_name%" & endlocal & exit /b 1
rem ���� ���-�� ���������� ���� � ����� (> -1) � �� ����� ���-�� ����������, ��� ���-�� ���������� > -1, �� ������
if %_src_cnt% GTR -1 if %_dst_cnt% GTR -1 if %_src_cnt% NEQ %_dst_cnt% call :echo -ri:CmdSrcNeqDstError -v1:%_src_cnt% -v2:%_dst_cnt% -v3:"%_exec_name%" & endlocal & exit /b 1
endlocal & exit /b 0

rem ---------------------------------------------
rem ��������� ��������� ����������������� �����
rem ---------------------------------------------
:goal_apply_cfg_prms
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _mod_ver=%~3
set _pkg_cfg_file=%~4
set _cfg_cmt=%~5

call :binding_var "%_pkg_name%" "%_mod_name%" "%_pkg_cfg_file%" l_mod_cfg_path
call :echo -ri:ApplyCfgParams -v1:"%l_mod_cfg_path%" -rc:0F -ln:%VL_FALSE%

rem ��������� ���� � ��������� ����� ����������������� ����� ������
for /f %%i in ("%l_mod_cfg_path%") do set l_cfg_file_name=%%~nxi
set l_tmp_file="%TMP%\%l_cfg_file_name%.tmp"
type NUL > "%l_tmp_file%"

call :echo -ri:CreatedCfgTmpFile -v1:"%l_tmp_file%"

if "%_cfg_cmt%" NEQ "" call :len "%_cfg_cmt%" l_cmt_len
rem �������� ��������� ����������������� ����� ������
set "i=0"
call :get_res_val -rf:"%xpaths_file%" -ri:XPathCfgParams -v1:"%_mod_name%" -v2:"%_mod_ver%" -v3:"%_pkg_cfg_file%"
rem for /F "tokens=1-8" %%a in ('%xml_sel_% "!xpath_cfg_prms!" -v "./name" -o "	" -v "./value" -o "	" -v "./description" -o "	" -v "./expression" -o "	" -v "./after" -o "	" -v "./before" -o "	" -v "./quotes" -o "	" -v "./entry" -n "%g_pkg_cfg_file%"') do (
for /F "tokens=1-6" %%a in ('%xml_sel_% "!res_val!" -v "concat(./name, substring('%EMPTY_NODE%', 1 div not(./name)))" -o "	" -v "./value" -o "	" -v "concat(./expression, substring('%EMPTY_NODE%', 1 div not(./expression)))" -o "	" -v "concat(./after, substring('%EMPTY_NODE%', 1 div not(./after)))" -o "	" -v "concat(./before, substring('%EMPTY_NODE%', 1 div not(./before)))" -o "	" -v "concat(./entry, substring('%EMPTY_NODE%', 1 div not(./entry)))" -n "%g_pkg_cfg_file%"') do (
	if "%%a" NEQ "%EMPTY_NODE%" set l_prms[!i!]#Name=%%~a
	set l_prms[!i!]#Val=%%b
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%a" 2^>nul`) DO set l_prms[!i!]#CaseName=%%A
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%b" 2^>nul`) DO set l_prms[!i!]#CaseVal=%%A
	rem set l_prms[!i!]#Descr=%%c
	if "%%c" NEQ "%EMPTY_NODE%" set l_prms[!i!]#Exp=%%~c
	if "%%d" NEQ "%EMPTY_NODE%" set l_prms[!i!]#After=%%~d
	if "%%e" NEQ "%EMPTY_NODE%" set l_prms[!i!]#Before=%%~e
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%e" 2^>nul`) DO set l_prms[!i!]#CaseAfter=%%A
	rem for /F "usebackq tokens=*" %%A IN (`%case_% %CM_LOWER% "%%f" 2^>nul`) DO set l_prms[!i!]#CaseBefore=%%A
	if "%%f" NEQ "%EMPTY_NODE%" (set l_prms[!i!]#Entry=%%~f) else (set l_prms[!i!]#Entry=1)
	set l_prms[!i!]#CurEntry=0
	set l_prms[!i!]#Applied=0
	set l_prms[!i!]#Multiple=0
	call :get_pval "%_pkg_name%" "%_mod_name%" !i!
	set l_prms[!i!]#PrmVal=!pval!
	set /a "i+=1"
	rem echo %%~a	%%b	%%~c	%%~d	%%~e	%%~f
)
set /a "prms_cnt=%i%-1"
call :echo -ri:NeedApplyParamsCnt -v1:%i%
rem �������� ������������� ���������
for /l %%j in (0,1,%prms_cnt%) do (
	if "!l_prms[%%j]#Name!" NEQ "" (
		if !l_prms[%%j]#Multiple! EQU 0 (
			for /l %%k in (0,1,%prms_cnt%) do (
				if %%j NEQ %%k (
					if !l_prms[%%k]#Multiple! EQU 0 if /i "!l_prms[%%j]#Name!" EQU "!l_prms[%%k]#Name!" (
						set l_prms[%%j]#Multiple=1
						set l_prms[%%k]#Multiple=1
					)
				)
			)
		)
	)
)
rem for /l %%j in (0,1,%prms_cnt%) do echo !l_prms[%%j]#PrmVal! - !l_prms[%%j]#Multiple!
rem exit
rem ���� ���� �������� ��� ����������, �� ���������� ������ ����������������� ����� ������
if %prms_cnt% GEQ 0 (
	set "i=-1"
	rem ��������� ����������
	for /F "usebackq eol= delims=" %%l in ("%l_mod_cfg_path%") do (
		set l_ln=%%l
		set is_applied=0
		set is_find=0
		rem ������ ���� ������ ���������� � ������
		for /l %%j in (0,1,%prms_cnt%) do (
			if !l_prms[%%j]#Applied! EQU 0 (
echo 1
				call :find_prm_in_ln "#Name" %%j "%_cfg_cmt%" %l_cmt_len%
				rem ���� ������ �������� ������� ��������
				if NOT ERRORLEVEL 3 (
echo 2
					rem ���� ��������� �������������� ��������, ��������� ������� ����� � �������� ���������
					if ERRORLEVEL 2 call :find_cmt_pval "%_pkg_name%" "%_mod_name%" %%j "%_cfg_cmt%"
echo 3
					rem ���� ����������� �������� �� "�����"-"��������"
					if NOT ERRORLEVEL 3 (
echo 3.5
						rem ���� ������ �������� ��� "�����" ��� � ������������������ ����, �� ��������� ���
						if ERRORLEVEL 1 (
							set /a "l_prms[%%j]#CurEntry+=1"
echo 4 entry: !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry!
							if !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry! (
echo 5
								call :apply_prm "%_pkg_name%" "%_mod_name%" "#Name" %%j "%l_tmp_file%"
								set l_prms[%%j]#Applied=1
								set is_applied=1
								set /a "i+=1"
							)
						)
						set is_find=1
					)
				)
			)
		)
echo 6
		rem ������ ���� ������ ���������� � ������
		rem ���� �������� ���������� � ������, �� �� ������� ��� ��������� �� ��������, �������� ����� �� �����
echo is_applied = !is_applied!; is_find = !is_find!
		if !is_applied! EQU 0 if !is_find! EQU 1 (
			for /l %%j in (0,1,%prms_cnt%) do (
				rem ���� �������� �� ������������� � �� ��������
				if !l_prms[%%j]#Multiple! EQU 0 if !is_applied! EQU 0 if !l_prms[%%j]#Applied! EQU 0 (
echo 7
					rem �� ������� ��� � ������������������ ������ �� �����
					call :find_cmt_pname %%j "%_cfg_cmt%"
					rem ���� ����� �� "�����"
					if NOT ERRORLEVEL 3 (
						rem ���� ������������������ ������ �������� ��� ���������
						if ERRORLEVEL 1 (
							set /a "l_prms[%%j]#CurEntry+=1"
echo 8 entry: !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry!
							if !l_prms[%%j]#CurEntry! EQU !l_prms[%%j]#Entry! (
echo 9
								call :apply_prm "%_pkg_name%" "%_mod_name%" "#Name" %%j "%l_tmp_file%"
								set l_prms[%%j]#Applied=1
								set is_applied=1
								set /a "i+=1"
							)
						)
					)
				)
			)
		)
echo 10
		rem ���� � ������� ������ �� �������� �� ���� ������� ��������, �� ����� � � ����
echo is_applied = !is_applied!
		if !is_applied! EQU 0 echo !l_ln!>>"%l_tmp_file%"
	)
echo 11
	echo %prms_cnt%  - !i!
	if !i! EQU %prms_cnt% goto all_prm_applied
	rem ���������� � ����� ���������� ����� ������������� ���������
echo 12
	set "k=0"
	for /l %%j in (0,1,%prms_cnt%) do (
		rem ���� � ��� �� ���������� ��������� "�����" ��� "�����"
		if !l_prms[%%j]#Applied! EQU 0 if "!l_prms[%%j]#After!" EQU "" if "!l_prms[%%j]#Before!" EQU "" (
echo 13
			call :get_pval "%_pkg_name%" "%_mod_name%" %%j
			echo !pval!>>"%l_tmp_file%"
			set l_prms[%%j]#Applied=1
			set /a "k+=1"
			set /a "i+=1"
		)
	)
	call :echo -ri:AddCfgParamsCnt -v1:!k!
	rem �������� ������� ���� ������������ ������ ��������� ������
	rem 1>nul copy "%l_tmp_file%" "%l_mod_cfg_path%"
	echo %prms_cnt%  - !i!
	rem ���� ���������� ������, ��� ��������� "� ���"
	if %prms_cnt% GTR !i! (
	exit
		rem type NUL > "%l_tmp_file%"
		rem ��������� ��������� ������ �������� �������� ���������� "�����" ��� "�����"
		for /F "usebackq eol= delims=" %%a in ("%l_mod_cfg_path%") do (
			set l_ln=%%a
			set is_applied=0
			for /l %%j in (0,1,%prms_cnt%) do (
				if !l_prms[%%j]#Applied! EQU 0 (
					call :find_prm_in_ln "#After" %%j "%_cfg_cmt%" %l_cmt_len%
					rem ���� ������ �������� ������� ��������
					if NOT ERRORLEVEL 2 (
						rem ���� �������� ��� "�����", �� ��������� ���
						if ERRORLEVEL 1 (
							call :apply_prm "%_pkg_name%" "%_mod_name%" "#After" %%j "%l_tmp_file%"
							set l_prms[%%j]#Applied=1
							set is_applied=1
							set /a "i+=1"
						)
					)
				)
			)
			
			rem ���� � ������ �� �������� �� ���� ������� ��������, �� ����� � � ����
			if !is_applied! EQU 0 echo !l_ln!>>"%l_tmp_file%"
		)
		rem �������� ������� ���� ������������ ������ ��������� ������
		rem 1>nul copy "%l_tmp_file%" "%l_mod_cfg_path%"
	)
	echo %prms_cnt%  - !i!
)
:all_prm_applied
exit
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� ������� ������� ��������� � ������
rem ---------------------------------------------
:find_prm_in_ln
setlocal
set _find=%~1
set _j=%~2
set _cfg_cmt=%~3
set _cmt_len=%~4

rem ���������� ����������� �� ������� ��������			
if "!l_prms[%_j%]%_find%!" NEQ "" (
	set l_chk_pname=!l_prms[%_j%]%_find%!
) else if "!l_prms[%_j%]#After!" NEQ "" (
	set l_chk_pname=!l_prms[%_j%]#After!
) else (
	set l_chk_pname=!l_prms[%_j%]#Before!
)
rem �������� �� ����� ��������� (� ������: ���������� ������� ����������� - %%a, ����� ��������� - %%b 
rem ������� "=" - %%c � ��� �������� - %%d). ��� ������� ������� ����������� ��� ���������
if "%_cfg_cmt%" NEQ "" set l_cmts=!CMT_SYMBS:%_cfg_cmt%=!
set l_cmts=%l_cmts:"=%
if "!l_ln:~0,%_cmt_len%!" EQU "%_cfg_cmt%" (
	if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
		for /F "eol= tokens=1-3 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b%%c"
	) else (
		for /F "eol= tokens=1-4 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b%%c%%d"
	)
) else (
	if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
		for /F "eol= tokens=1,2 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b"
	) else (
		for /F "eol= tokens=1-3 delims=%l_cmts%/,'\()*{}$~&?!<>| " %%a in ("!l_ln!") do set "l_ln_pname=%%a%%b%%c"
	)
)
set l_ln_pname=%l_ln_pname:"=%
set $ln=!l_ln_pname:%l_chk_pname%=!

echo "%$ln%" "%l_ln_pname%" "!l_chk_pname!"
rem ���� �� ������� �������� ��� ��������� �� ������ ��� ������ �� �������� ������� ��������, �� ���������� 3
if /i "%l_ln_pname%" EQU "" endlocal & exit /b 3
if /i "%$ln%" EQU "!l_ln_pname!" endlocal & exit /b 3

echo 14
rem ���� �� ������ ��� ���������, ��� ������ - �� �����������, ��� ������ ����������� �� �����, 
rem �� ������ "�����" �������� ������� �������� � ���������� - 1
if "!l_prms[%_j%]#Name!" EQU "" endlocal & exit /b 1
if "%_cfg_cmt%" EQU "" endlocal & exit /b 1
if "!l_ln_pname:~0,%_cmt_len%!" NEQ "%_cfg_cmt%" endlocal & exit /b 1

echo 15
rem ����� - ������� ���������� ��������, ���������� 2
endlocal & exit /b 2

rem ---------------------------------------------
rem ���������� ������� ������� ������������������� 
rem ��������� ("���"-"��������") � ������
rem ---------------------------------------------
:find_cmt_pval
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _j=%~3
set _cfg_cmt=%~4

echo 16
rem ��������� � ��������� ������� ��������� �� ���������
call :get_pval "%_pkg_name%" "%_mod_name%" %_j%
set pval=%pval:"=%
set pval=%pval: =%
echo 16.1 "%pval%"
rem �������� �������� �������� � ��� �������� �� ������������� ������ ����������������� ����� � ��������� "��������"-"��������"
for /F "eol= tokens=1,2 delims=%_cfg_cmt%= " %%a in ("!l_ln!") do (set "l_pname=%%~a" & set "l_pval=%%~b")
echo 16.2
if "%l_pname%" EQU "" endlocal & exit /b 3
rem if "%l_pval%" EQU "" endlocal & exit /b 3

if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
	set l_ln_pval=%l_pname% %l_pval%
) else (
	set l_ln_pval=%l_pname%=%l_pval%
)
if "%l_ln_pval%" EQU "" endlocal & exit /b 3
echo 16.5 "%l_ln_pval%"
set l_ln_pval=%l_ln_pval:"=%
echo 17 "%l_ln_pval%" "%pval%"

rem ���� ����������� �������� �������� �� ���������, �� ���������� 1
if /i "%l_ln_pval%" EQU "%pval%" endlocal & exit /b 1

echo 18
rem ����� - ������� ���������� ��������, ���������� 0
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� ������� ������� ������������������� 
rem ��������� ("���") � ������
rem ---------------------------------------------
:find_cmt_pname
setlocal
set _j=%~1
set _cfg_cmt=%~2

echo 19
rem �������� �������� �������� �� ������������� ������ ����������������� �����
for /F "eol= tokens=1 delims=%_cfg_cmt%= " %%a in ("!l_ln!") do set "l_pname=%%~a"

if /i "%l_pname%" EQU "" endlocal & exit /b 3
echo 20 "%l_pname%" "!l_prms[%_j%]#Name!"
rem ���� ����������� �������� ������ ��� ���������, �� ���������� 1
if /i "%l_pname%" EQU "!l_prms[%_j%]#Name!" endlocal & exit /b 1
echo 21

rem ����� - ��������� ��������, ���������� 0
endlocal & exit /b 0

rem ---------------------------------------------
rem ��������� �������� �������� � ������ � 
rem ���������� ��� � ����
rem ---------------------------------------------
:apply_prm
setlocal
set _pkg_name=%~1
set _mod_name=%~2
set _find=%~3
set _j=%~4
set _tmp_file=%~5

rem ��������� ������ "��������"-"��������"
call :get_pval "%_pkg_name%" "%_mod_name%" %_j%
rem � ����� �
if /i "%_find%" EQU "#Name" echo %pval%>>"%_tmp_file%" & endlocal & exit /b 0
if "!l_prms[%_j%]#After!" NEQ "" (
	echo !l_ln!>>"%_tmp_file%"
	echo %pval%>>"%_tmp_file%"
) else "!l_prms[%_j%]#Before!" NEQ "" (
	echo %pval%>>"%_tmp_file%"
	echo !l_ln!>>"%_tmp_file%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� ������ "��������"-"��������"
rem ---------------------------------------------
:get_pval
setlocal
set _proc_name=%~0
set _pkg_name=%~1
set _mod_name=%~2
set _j=%~3

if defined l_prms[%_j%]#PrmVal endlocal & set "%_proc_name:~5%=!l_prms[%_j%]#PrmVal!" & exit /b 0

set l_val=!l_prms[%_j%]#Val!

rem ������� �������, ��������� � ���������� �������� ���������
set $quot_val=%l_val:"=%
call :binding_var "%_pkg_name%" "%_mod_name%" "%$quot_val%" l_bind_val

rem ���� � �������� �� ���� �������, �� ���������� ��� �������, ����� - ������ ��
if /i "%$quot_val%" EQU "%l_val%" (
	set l_val=%l_bind_val%
) else (
	set l_val="%l_bind_val%"
)
if "!l_prms[%_j%]#Name!" EQU "" endlocal & set "%_proc_name:~5%=%l_val%" & exit /b 0

if /i "!l_prms[%_j%]#Exp!" EQU "%VL_FALSE%" (
	set l_pval=!l_prms[%_j%]#Name! %l_val%
) else (
	set l_pval=!l_prms[%_j%]#Name!=%l_val%
)
endlocal & set %_proc_name:~5%=%l_pval%
exit /b 0

rem ---------------------------------------------
rem ����������� ���������������� ����� ������
rem ---------------------------------------------
:goal_backup_config
setlocal
set _mod_name=%~1
set _mod_ver=%~2

call :echo -ri:DefFuncNotImpl -v1:"%~0" & endlocal & exit /b 0

call :echo -ri:AddPathEnv -v1:%_dir% -rc:0F -ln:%VL_FALSE%
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem ��������������� ���������������� ����� ������
rem �� ��������� �����
rem ---------------------------------------------
:goal_restore_config
setlocal
set _mod_name=%~1
set _mod_ver=%~2

call :echo -ri:DefFuncNotImpl -v1:"%~0" & endlocal & exit /b 0

call :echo -ri:AddPathEnv -v1:%_dir% -rc:0F -ln:%VL_FALSE%
call :echo -ri:ResultOk -rc:0A
endlocal & exit /b 0

rem ---------------------------------------------
rem ��������� �������������� ����������
rem https://www.robvanderwoude.com/battech_inputvalidation_setp.php
rem ---------------------------------------------
:binding_var
setlocal
set _proc_name=%~0
set _pkg_name=%~1
set _mod_name=%~2
set _var=%~3

rem echo 1. "%_var%"
if "%_var%" EQU "" endlocal & set "%4=" & exit /b 0
set $bind_var=%_var:${=%
rem ���� �� ����� ��������� ����������, �� ���������� � "��� ����"
if /i "%$bind_var%" EQU "%_var%" endlocal & set "%4=%_var%" & exit /b 0

call :convert_case %CM_LOWER% "%_var%" conv_str & set "_var=!conv_str!"

rem echo 2. "%_var%"
rem ����� �������� � �������� ������:
rem ������� ������� BIS
set _var=!_var:${bisdir}=%CUR_DIR%!

rem ������� ��������� ������ � ��
set _var=!_var:${windir}=%WINDIR%!

rem echo 3. "%_var%"
if not defined _pkg_name goto is_mod_name
rem ���������� ���������� ������:
rem ��� ������
set _var=!_var:${package.name}=%g_pkg_name%!

set l_pkg_setup_dir=!pkgs[%_pkg_name%]#SetupDir!
set _var=!_var:${setupdir}=%l_pkg_setup_dir%!

rem echo 4. "!pkgs[%_pkg_name%]#SetupDir!" "%_var%"
:is_mod_name
if not defined _mod_name goto input_bind_var
rem �������� �������� ������:
rem ${webprojectdir} ${hosts} ${hosts.ip} ${hosts.directory} ${hosts.name} ${logdir} ${module.name} ${servicename}
rem ������� ��������� ������
set l_mod_setup_dir=!mods[%_mod_name%]#SetupDir!
rem echo "%_mod_name%" - "%l_mod_setup_dir%"
set _var=!_var:${modsetupdir}=%l_mod_setup_dir%!

rem ������� ������������ ������
set l_mod_distrib_dir=!mods[%_mod_name%]#DistribDir!
set _var=!_var:${moddestribdir}=%l_mod_distrib_dir%!

rem echo 5. "%_var%"
rem �������� ������ �������:
for /f "tokens=1-4 delims=${.}" %%j in ("%_var%") do (
	set l_mod_name=%%j
	
rem 	set l_mod_setup_dir=%mods[!l_mod_name!]#SetupDir%
rem	set _var=!_var:${!l_mod_name!.setupdir}=%l_mod_setup_dir%!

rem	set l_mod_distrib_dir=%mods[!l_mod_name!]#DistribDir!%
rem	set _var=!_var:${moddestribdir}=%l_mod_distrib_dir%!
) 

rem echo 6. "%_var%"
:input_bind_var
set $bind_var=%_var:${=%
rem ���� �� ����� ��������� ����������, �� ���������� � "��� ����"
if /i "%$bind_var%" EQU "%_var%" endlocal & set "%4=%_var%" & exit /b 0
rem ����� - �������� ��������� � ������������ � ��������
call :get_res_val -rf:"%menus_file%" -ri:InputBindVarsValues -v1:"%_var%"
call :choice_process "" "" %SHORT_DELAY% N "!res_val!"
if %choice% EQU %NO% call :echo -ri:InputBindVarsAbort -v1:"%_var%" & endlocal & exit /b 1

set l_vars=%_var%
:bind_vars_loop
for /f "tokens=1* delims=$}" %%i in ("!l_vars!") do (
	set l_input_var=%%i
	set $check_input_var=!l_input_var:~0,1!
	if /i "!$check_input_var!" EQU "{" (
		set l_input_var=!l_input_var:~1!
		call :get_res_val -ri:InputBindVarValue -v1:!l_input_var!
		set /p l_input_val="!res_val!"
		set l_input_val=!l_input_val:"=!
		call :binding_input_var "%_var%" "!l_input_var!" "!l_input_val!" _var
	)
	set l_vars=%%j
)
if defined l_vars goto bind_vars_loop
endlocal & set %4=%_var%
exit /b 0

rem ---------------------------------------------
rem ��������� �������������� ���������� � ���������
rem ������������� ����������
rem ---------------------------------------------
:binding_input_var
setlocal
set _var=%~1
set _input_var=%~2
set _input_val=%~3
endlocal & set %4=!_var:${%_input_var%}=%l_input_val%!
exit /b 0

rem ---------------------------------------------
rem ������� ������������ ������� ���� ����������
rem ---------------------------------------------
:print_exec_name
setlocal
set _proc_name=%~1

call :get_exec_name %_proc_name%
set $exec=%_proc_name:goal=%
if /i "%$exec%" NEQ "%_proc_name%" (
	call :echo -ri:ExecGoal -v1:"%exec_name%" -ae:1
) else (
	call :echo -ri:ExecPhaseId -v1:"%exec_name%" -ae:1
)
endlocal & exit /b 0

rem ---------------------------------------------
rem ���������� ������������ ����� ���������� ����/����
rem (�� ������������ ���������)
rem ---------------------------------------------
:get_exec_name
setlocal
set _exec_name=%~0
set _proc_name=%~1

set $exec=%_proc_name:goal=%
if /i "%$exec%" NEQ "%_proc_name%" (
	set l_exec_name=%_proc_name:~6%
) else (
	set $exec=%_proc_name:phase=%
	if /i "!$exec!" NEQ "%_proc_name%" (
		set l_exec_name=%_proc_name:~7%
	) else (
		set l_exec_name=%_proc_name:~5%
	)
)
set l_exec_name=%l_exec_name:_=-%
endlocal & set %_exec_name:~5%=%l_exec_name%
exit /b 0

rem ---------------------------------------------
rem ����������� ������������� ���������� ��������
rem ---------------------------------------------
:choice_process
setlocal
set _proc_name=%~0
set _exec_name=%~1
set _res_id=%~2
set _delay=%~3
set _def_choice=%~4
set _res_val=%~5
set _choice=%~6

if not defined _res_id if not defined _res_val set _res_id=ProcessingChoice
if not defined _delay set _delay=%DEF_DELAY%
if not defined _def_choice set _def_choice=Y
if not defined _choice set _choice=%YN_CHOICE%

if defined _exec_name (
	set l_exec_name=%_exec_name:~0,1%
	if "%l_exec_name%" EQU ":" (
		call :get_exec_name "%l_exec_name%"
	) else (
		set exec_name=%_exec_name%
	)
)
if defined _res_id (
	call :get_res_val -rf:"%menus_file%" -ri:%_res_id% -v1:%_delay% -v2:"%exec_name%"
) else (
	set res_val=%_res_val%
)
rem ChangeColor 15 0
%ChangeColor_15_0%
1>nul chcp 1251
Choice /C %_choice% /T %_delay% /D %_def_choice% /M "%res_val%"
set l_result=%ERRORLEVEL%
rem echo l_result="%l_result%"
endlocal & (set "%_proc_name:~8%=%exec_name%" & set "%_proc_name:~1,6%=%l_result%" & exit /b %l_result%)

rem ---------------------------------------------
rem ���������� � ERRORLEVEL ��� ������ ����������
rem ---------------------------------------------
:get_exec_code
setlocal
set _proc_name=%~0

if /i "%EXEC_MODE%" EQU "%EM_EML%" endlocal & set "%_proc_name:~5%=%CODE_EML%" & exit /b %CODE_EML%
if /i "%EXEC_MODE%" EQU "%EM_TST%" endlocal & set "%_proc_name:~5%=%CODE_TST%" & exit /b %CODE_TST%
if /i "%EXEC_MODE%" EQU "%EM_RUN%" endlocal & set "%_proc_name:~5%=%CODE_RUN%" & exit /b %CODE_RUN%
if /i "%EXEC_MODE%" EQU "%EM_DBG%" endlocal & set "%_proc_name:~5%=%CODE_DBG%" & exit /b %CODE_DBG%

endlocal & set %_proc_name:~5%=%EM_EML%
exit /b %EM_EML%

rem ---------------------------------------------
rem ������������� ��� ����������� ���������
rem � ������� ��� ������ �������
rem ---------------------------------------------
:bis_setup
rem ��������� � ����������� �������� �� ���������:
rem ���������� ������� �������
for %%a in ("%CD%") do set "CUR_DIR=%%~fa"
rem ������ ������� xml-����
set EMPTY_NODE=~
rem ��������� ������� ������������ � �������� �������
set CMT_SYMBS=";:#"

rem �������� �� ���������:
rem ��������� (�� ��������)
set DEF_MOD_DIR=%CUR_DIR%/modules
set DEF_CFG_DIR=%CUR_DIR%/config
set DEF_RES_DIR=%CUR_DIR%/resources
set DEF_UTL_DIR=%CUR_DIR%/utils
rem �������� (�������� � ����������� �� �������� ����������� ������)
set DEF_BAK_DAT_DIR=%CUR_DIR%/backup/data
set DEF_BAK_CFG_DIR=%CUR_DIR%/backup/config
set DEF_LOG_DIR=%CUR_DIR%/logs
set DEF_DISTRIB_DIR=%CUR_DIR%/distrib

rem ���������� ���� � �������� ������� ��������� �����
call :chgcolor_setup "%DEF_UTL_DIR%/%PA_X86%/"
if ERRORLEVEL 1 call :chgcolor_setup "%DEF_UTL_DIR%/%PA_X64%/"

rem ���� (������� ��� � ���������������� ����� ������)
set PH_DOWNLOAD=download
set PH_INSTALL=install
set PH_CONFIG=config
set PH_BACKUP=backup
set PH_UNINSTALL=uninstall

rem ����
set GL_SILENT=SILENT
set GL_CMD_SHELL=CMD-SHELL
set GL_UNPACK_ZIP=UNPACK-ZIP
set GL_UNPACK_7Z_SFX=UNPACK-7Z-SFX
set GL_UNINSTALL_PORTABLE=UNINSTALL-PORTABLE

rem ���������� ����������� ������� 
call :get_proc_arch
if not defined proc_arch set proc_arch=%PA_X86%

rem ������ ���������� �������:
set bis_param_defs="-ul,p_use_log;-ll,p_log_level;-pa,proc_arch,%proc_arch%;-lc,locale;-ld,bis_log_dir,%DEF_LOG_DIR%;-dd,bis_distrib_dir,%DEF_DISTRIB_DIR%/windows/%proc_arch%;-ud,bis_utils_dir,%DEF_UTL_DIR%/%proc_arch%;-bd,bis_backup_data_dir,%DEF_BAK_DAT_DIR%;-bc,bis_backup_config_dir,%DEF_BAK_CFG_DIR%;-md,bis_modules_dir,%DEF_MOD_DIR%;-cd,bis_config_dir,%DEF_CFG_DIR%;-rd,bis_res_dir,%DEF_RES_DIR%;-lf,p_license_file;-em,EXEC_MODE,#,%EM_RUN%;-pc,p_pkg_choice;-mc,p_mod_choice;-ec,p_exec_choice;-pn,p_pkg_name;-mn,p_mod_name"
call :parse_params %~0 %bis_param_defs% %*
rem ������ ������� ����������� ����������
rem if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem ����� �������
if ERRORLEVEL 1 call :bis_help & endlocal & exit /b 0
if /i "%EXEC_MODE%" EQU "%EM_DBG%" (
	call :print_params %~0
) else if %p_log_level% GTR %LL_INF% call :print_params %~0

rem ���������� ������� ������������
set g_log_level=%p_log_level%
rem ���-���� ������� BIS
if /i "%p_use_log%" EQU "%VL_TRUE%" set g_log_file=%bis_log_dir%/BIS.log

rem ���������� ������ �������
if not defined locale call :get_locale 1>nul 2>&1

rem ����� ��������
set g_res_file=%bis_res_dir%/strings_%locale%.txt
set menus_file=%bis_res_dir%/menus_%locale%.txt
set help_file=%bis_res_dir%/helps_%locale%.txt
set xpaths_file=%bis_res_dir%/xpaths.txt

call :echo -ri:LocaleInfo -v1:%locale%

rem ������� ��������� ���������
call :echo -rv:"%g_script_header% " -rc:08 -ln:%VL_FALSE%
rem ������� ���������� � ������ ������� � �������� ��� ������� ������ ������������
call :echo -rv:"[" -rc:08 -ln:%VL_FALSE%
call :echo -rv:"MODE: %EXEC_MODE%" -rc:0F -ln:%VL_FALSE%
if defined p_use_log call :echo -rv:"; LOG_LEVEL: %p_log_level%" -rc:0F -ln:%VL_FALSE%
rem call :echo -rv:""
call :echo -rv:"]" -rc:08
rem ���� �� ������ ���� ��������
if not exist "%p_license_file%" call :echo -ri:ProgramLicenseMsg -rc:0F
call :echo -ri:InitSetupParams -ln:%VL_FALSE% -be:1
rem call :echo -ri:ProcArchDefError -be:1
call :echo -ri:ProcArchInfo -v1:%proc_arch%

rem �������
set z7_=%bis_utils_dir%/7-zip/7za.exe
set copy_=robocopy.exe
set xml_=%bis_utils_dir%/xml.exe
set xml_sel_=%bis_utils_dir%/xml.exe sel -T -t -m
set curl_=%bis_utils_dir%/curl/bin/curl.exe
set wget_=%bis_utils_dir%/wget/wget.exe

rem ��������� ���� �� ������ �������� ����� (http://www.rsdn.ru/forum/setup/2810022.hot)
for /f %%i in ("%bis_log_dir%") do set bis_log_dir=%%~dpnxi
for /f %%i in ("%bis_distrib_dir%") do set bis_distrib_dir=%%~dpnxi
for /f %%i in ("%bis_utils_dir%") do set bis_utils_dir=%%~dpnxi
for /f %%i in ("%bis_config_dir%") do set bis_config_dir=%%~dpnxi
for /f %%i in ("%bis_backup_data_dir%") do set bis_backup_data_dir=%%~dpnxi
for /f %%i in ("%bis_res_dir%") do set bis_res_dir=%%~dpnxi

call :echo -ri:ResultOk -rc:0A

exit /b 0

rem ---------------------------------------------
rem ��������� ��������� ���� ����������� ����������
rem � �������� �������
rem ---------------------------------------------
:bis_check_setup
setlocal
call :echo -ri:CheckSetupParams -ln:%VL_FALSE%
rem ��������:
rem ������� ���������
if not exist "%bis_log_dir%" call :echo -ri:LogDirExistError -v1:"%bis_log_dir%" & endlocal & exit /b 1
if not exist "%bis_modules_dir%" call :echo -ri:ModulesDirExistError -v1:"%bis_modules_dir%" & endlocal & exit /b 1
if not exist "%bis_res_dir%" call :echo -ri:ResDirExistError -v1:"%bis_res_dir%" & endlocal & exit /b 1
rem ������� ��������
if not exist "%g_res_file%" call :echo -ri:ResFileExistError -v1:"%g_res_file%" & endlocal & exit /b 1
if not exist "%menus_file%" call :echo -ri:ResFileExistError -v1:"%menus_file%" & endlocal & exit /b 1
if not exist "%help_file%" call :echo -ri:ResFileExistError -v1:"%help_file%" & endlocal & exit /b 1
if not exist "%xpaths_file%" call :echo -ri:ResFileExistError -v1:"%xpaths_file%" & endlocal & exit /b 1
rem ������� ������
if not exist "%z7_%" call :echo -ri:UtilExistError -v1:"%z7_%" & endlocal & exit /b 1
if not exist "%xml_%" call :echo -ri:UtilExistError -v1:"%xml_%" & endlocal & exit /b 1
if not exist "%curl_%" call :echo -ri:UtilExistError -v1:"%curl_%" & endlocal & exit /b 1
if not exist "%wget_%" call :echo -ri:UtilExistError -v1:"%wget_%" & endlocal & exit /b 1
rem ������� ���������
if not exist "%bis_distrib_dir%" call :echo -ri:DistribDirExistError -v1:"%bis_distrib_dir%" & endlocal & exit /b 1
if not exist "%bis_utils_dir%" call :echo -ri:UtilsDirExistError -v1:"%bis_utils_dir%" & endlocal & exit /b 1
if not exist "%bis_config_dir%" call :echo -ri:ConfigDirExistError -v1:"%bis_config_dir%" & endlocal & exit /b 1
if not exist "%bis_backup_data_dir%" call :echo -ri:BackupDirExistError -v1:"%bis_backup_data_dir%" & endlocal & exit /b 1

call :echo -ri:ResultOk -rc:0A

call :echo -ri:LogDir -v1:"%bis_log_dir%"
call :echo -ri:DistribDir -v1:"%bis_distrib_dir%"
call :echo -ri:UtilsDir -v1:"%bis_utils_dir%"
call :echo -ri:ModulesDir -v1:"%bis_modules_dir%"
call :echo -ri:BackupDir -v1:"%bis_backup_data_dir%"
call :echo -ri:ConfigDir -v1:"%bis_config_dir%"
endlocal & exit /b 0

rem ---------------------------------------------
rem ������ ������� ����������� �������
rem ---------------------------------------------
:bis_help
echo.
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo %g_script_header%
rem ChangeColor 8 0 
%ChangeColor_8_0%
echo ������ ������� ��������� ������:
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo %g_script_name% [^<�����^>...]
echo.
rem ChangeColor 8 0
%ChangeColor_8_0%
echo �����:
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -cf"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :����������������_����_������
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -sd"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:�������_���������_������ ("
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=���������� ���� �� ����� �����"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ld"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:�������_����� (�� ��������� "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=%DEF_LOG_DIR%"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -dd"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:�������_������������� (�� ��������� "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=%DEF_DISTRIB_DIR%"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ud"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:�������_�������_������ (�� ��������� "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=%DEF_UTL_DIR%"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -md"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:�������_���������������_������� (�� ��������� "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=%DEF_MOD_DIR%"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=)"
rem ChangeColor 15 0
%ChangeColor_15_0%
echo - � ����������� �������� ������ '\'
echo.
rem ChangeColor 8 0 
%ChangeColor_8_0%
echo ���� �� ������� �����, �� ��� ���� ����������� �� �������� ��������� ������� Victory BIS.
endlocal & exit /b 1

rem ---------------- EOF bis.cmd ----------------
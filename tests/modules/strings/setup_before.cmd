@Echo Off
rem ��������� ��������� ��������� (��������) ������������ �������� ����������� �������� �������� ������
set src_script=%~1
set src_dir=%~2

if not exist "%src_script%" endlocal & exit /b 3

rem ������������� �������, ����������� ��� ������ ������
echo PREPEND=%src_dir%..\..\..\src\modules\definitions.cmd
echo APPEND=%src_dir%..\..\..\src\modules\params.cmd
echo APPEND=%src_dir%..\..\..\src\modules\echo.cmd

exit /b 0
rem ---------------- EOF setup_before.cmd ----------------

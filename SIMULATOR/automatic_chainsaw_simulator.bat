@ECHO OFF

SET OLDPATH=%cd%
SET SIM_PATH=%~dp0
SET ASM_PATH=..\ASM\CPUAssembler\bin\Debug\CPUAssembler.exe
SET CPU_FILES=..\CPU\
SET IVERILOG_PATH=c:\iverilog\bin\
SET CC_PATH=..\COMPILER\node compiler.js
SET INPUT_EXT=%~x1
SET TMP_PATH=tmp

CD %SIM_PATH%
MKDIR %TMP_PATH% 2> nul
IF /I %INPUT_EXT%==.C GOTO compilec
IF /I %INPUT_EXT%==.ASM GOTO assemble

ECHO Wrong file extension
RD /S /Q %TMP_PATH%
CD %OLDPATH%
EXIT /B 1

:compilec
%CC_PATH% %1 -o %TMP_PATH%\program.asm 1>nul
IF %ERRORLEVEL% NEQ 0 GOTO error
%ASM_PATH% -ram %TMP_PATH%\ram.v %TMP_PATH%\program.asm 1>nul
IF %ERRORLEVEL% NEQ 0 GOTO error
SearchReplace %CPU_FILES%CPU.v //(SIM)DONOTREMOVE// %TMP_PATH%\ram.v %TMP_PATH%\CPU_modified.v
%IVERILOG_PATH%iverilog -Wall -g2012 -s testbench -o %TMP_PATH%\compiled.vvp %CPU_FILES%ALU.v %CPU_FILES%Buff.v %CPU_FILES%SDCard.v %TMP_PATH%\CPU_modified.v testbench.v 2>nul
IF %ERRORLEVEL% NEQ 0 GOTO error
%IVERILOG_PATH%vvp %TMP_PATH%\compiled.vvp

SET /P CLEARTMP=Remove temporary files?(y/n)
IF /I %CLEARTMP%==n GOTO :cend

RD /S /Q %TMP_PATH%
:cend
CD %OLDPATH%
EXIT /B 0

:assemble
%ASM_PATH% -ram %TMP_PATH%\ram.v %1% 1>nul
IF %ERRORLEVEL% NEQ 0 GOTO error
SearchReplace %CPU_FILES%CPU.v //(SIM)DONOTREMOVE// %TMP_PATH%\ram.v %TMP_PATH%\CPU_modified.v
%IVERILOG_PATH%iverilog -Wall -g2012 -s testbench -o %TMP_PATH%\compiled.vvp %CPU_FILES%ALU.v %CPU_FILES%Buff.v %CPU_FILES%SDCard.v %TMP_PATH%\CPU_modified.v testbench.v 2>nul
IF %ERRORLEVEL% NEQ 0 GOTO error
%IVERILOG_PATH%vvp %TMP_PATH%\compiled.vvp

SET /P CLEARTMP=Remove temporary files?(y/n)
IF /I %CLEARTMP%==n GOTO :aend

RD /S /Q %TMP_PATH%

:aend
CD %OLDPATH%
EXIT /B 0

:error
ECHO Error.
CD %OLDPATH%
EXIT /B 2

@ECHO OFF

SET OLDPATH=%cd%
SET SIM_PATH=%~dp0
SET ASM_PATH=..\ASM\CPUAssembler\bin\Debug\CPUAssembler.exe
SET CPU_FILES=..\CPU\
SET GPU_FILES=..\GPU\
SET IVERILOG_PATH=c:\iverilog\bin\
SET GTKWAVE_PATH=C:\Users\Karol\Downloads\gtkwave-3.3.80-bin-win32\gtkwave\bin\
SET CC_PATH=node ..\COMPILER\compile.js
SET INPUT_EXT=%~x1
SET TMP_PATH=tmp\

CD %SIM_PATH%
MKDIR %TMP_PATH% 2> nul
IF /I %INPUT_EXT%==.C GOTO compilec
IF /I %INPUT_EXT%==.ASM GOTO assemble

ECHO Wrong file extension
RD /S /Q %TMP_PATH%
CD %OLDPATH%
EXIT /B 1

:compilec
%CC_PATH% %1 -o %TMP_PATH%program.asm
IF %ERRORLEVEL% NEQ 0 GOTO error
%ASM_PATH% -ram %TMP_PATH%ram.v %TMP_PATH%program.asm
IF %ERRORLEVEL% NEQ 0 GOTO error
SearchReplace %CPU_FILES%debugging\RAM_sim.v //(SIM)DONOTREMOVE// %TMP_PATH%ram.v %TMP_PATH%RAM_modified.v
%IVERILOG_PATH%iverilog -g2012 -s testbench -o %TMP_PATH%compiled.vvp %CPU_FILES%ALU.v %CPU_FILES%CPU.v %GPU_FILES%Font_ROM.v %GPU_FILES%disp_RAM.v  %GPU_FILES%GPU.v %GPU_FILES%TXT.v %GPU_FILES%VGA.v %TMP_PATH%RAM_modified.v %CPU_FILES%debugging\cpu_testbench.v
IF %ERRORLEVEL% NEQ 0 GOTO error
cd %TMP_PATH%
%IVERILOG_PATH%vvp compiled.vvp -lxt2
IF %ERRORLEVEL% NEQ 0 GOTO error
%GTKWAVE_PATH%gtkwave CPU_dump.lxt
cd ..

SET /P CLEARTMP=Remove temporary files?(y/n)
IF /I %CLEARTMP%==n GOTO :cend

RD /S /Q %TMP_PATH%
:cend
CD %OLDPATH%
EXIT /B 0

:assemble
%ASM_PATH% -ram %TMP_PATH%ram.v %1% 
IF %ERRORLEVEL% NEQ 0 GOTO error
SearchReplace %CPU_FILES%debugging\RAM_sim.v //(SIM)DONOTREMOVE// %TMP_PATH%ram.v %TMP_PATH%RAM_modified.v
%IVERILOG_PATH%iverilog -g2012 -s testbench -o %TMP_PATH%compiled.vvp %CPU_FILES%ALU.v %CPU_FILES%CPU.v %GPU_FILES%Font_ROM.v %GPU_FILES%disp_RAM.v %GPU_FILES%GPU.v %GPU_FILES%TXT.v %GPU_FILES%VGA.v %TMP_PATH%RAM_modified.v %CPU_FILES%debugging\cpu_testbench.v
IF %ERRORLEVEL% NEQ 0 GOTO error
cd %TMP_PATH%
%IVERILOG_PATH%vvp compiled.vvp -lxt2
IF %ERRORLEVEL% NEQ 0 GOTO error
%GTKWAVE_PATH%gtkwave CPU_dump.lxt
cd ..

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

::记得保存为ASNI编码

@echo off & setlocal enabledelayedexpansion

::开始
Title N_m3u8DL-CLI_v3.0.2.exe下载调用 by Lenno 2023.7.31经过修改

::界面颜色大小，Cols为宽，Lines为高
::0黑色1蓝色2绿色3浅绿色4红色5紫色6黄色7白色8灰色9淡蓝色
::A淡绿色B淡浅绿色C淡红色D淡紫色E淡黄色F亮白色
::mode con cols=100 lines=200
color 0b
::cls

:: 切换到脚本所在目录
set "SCRIPT_DIR=%~dp0"
cd /d "!SCRIPT_DIR!"

:: 初始化设置
call :initialize_settings

:: 主菜单
:main_menu
::cls
echo.
echo  N_m3u8DL-CLI 下载工具
echo.                   
echo. ***********************************************************
echo. *                                                         *
echo. *         1、m3u8视频单个下载(需要粘贴地址)               *
echo. *                                                         *
echo. *         2、m3u8视频批量下载(先设置好input.txt)          *
echo. *                                                         *
echo. *         3、直播录制(需要粘贴地址)                       *
echo. *                                                         *
echo. *         4、转换Downloads文件中的视频为.mp4              *
echo. *                                                         *
echo. *         5、打开下载目录                                 *
echo. *                                                         *
echo. *         6、退出程序                                     *
echo. *                                                         *
echo. ***********************************************************
echo 当前工作目录: !SCRIPT_DIR!
echo.
:menu_input
set /p "choice=请输入操作序号(1-6): "
if "!choice!"=="" goto menu_input
if not "!choice!"=="1" if not "!choice!"=="2" if not "!choice!"=="3" if not "!choice!"=="4" if not "!choice!"=="5" if not "!choice!"=="6" (
    echo 输入错误，请重新输入！
    goto menu_input
)

if "!choice!"=="1" goto m3u8_download
if "!choice!"=="2" goto m3u8_batch_download
if "!choice!"=="3" goto live_record
if "!choice!"=="4" goto video_to_mp4
if "!choice!"=="5" goto open_download_folder
if "!choice!"=="6" goto exit_program

:: =============== 初始化设置 ===============
:initialize_settings
:: 创建必要目录
if not exist "Downloads" mkdir "Downloads"
if not exist "Logs" mkdir "Logs"

:: 设置路径 - 使用相对路径避免长度问题
set TempDir=./Downloads/
set SaveDir=./Downloads/
set "OutputDIR=Downloads\"
set "LogDir=Logs\"

:: 设置程序路径
set "m3u8dl=N_m3u8DL-CLI_v3.0.2.exe"
set "ffmpeg=ffmpeg.exe"

::设置输入文件input.txt，和输出的批量下载批处理output.bat
::input.txt格式为 要保存的文件名,m3u8下载链接
::input示例
::蜘蛛侠1,http://xx.xx.m3u8
::蜘蛛侠2,http://xx.xx.m3u8
:: 设置输入输出文件
set "input=input.txt"
set "output=output.bat"

:: 设置日志文件
set "LOG_FILE=!LogDir!download_log_%date:~0,4%%date:~5,2%%date:~8,2%.txt"

:: 初始化日志
echo ===== 程序启动 %date% %time% ===== >> "!LOG_FILE!"







::设置m3u8下载参数
set m3u8_params=--headers "Cookie:MQGUID" --maxThreads "32" --minThreads "1" --retryCount "10" --timeOut "15" --enableBinaryMerge

::设置直播录制参数
set live_record_params=%live_record_limit%

goto :eof
::---------------设置部分end---------------

:: =============== 主要功能 ===============

::开始下载
:m3u8_download
cls
echo [单个下载模式]
call :check_m3u8dl_exe
call :common_input
::call :initialize_settings
call :m3u8_download_print
call :m3u8_downloading
call :when_done
goto main_menu

:m3u8_batch_download
::cls
echo [批量下载模式]
call :check_m3u8dl_exe
::call :initialize_settings
call :batch_input
call :batch_excute
call :when_done
goto main_menu

:live_record
cls
echo [直播录制模式]
call :check_m3u8dl_exe
call :common_input
call :live_record_input
::call :initialize_settings
call :live_record_print
call :live_recording
call :when_done
goto main_menu

:video_to_mp4
cls
echo [视频转换模式]
call :check_ffmpeg_exe
call :convert_video
goto main_menu

:open_download_folder
echo [信息] 正在打开下载目录...
if exist "!OutputDIR!" (
    start "" "!OutputDIR!"
) else (
    echo 下载目录不存在: !OutputDIR!
)
goto main_menu

:exit_program
echo 感谢使用，再见！
timeout /t 2 /nobreak >nul
exit

:: =============== 输入部分 ===============
:common_input
::输入链接 和 文件名
:set_link
set "link="
set /p "link=请输入链接: "
if "!link!"=="" (
    echo 错误：输入不能为空！
    goto set_link
)

:set_filename 
set "filename="
set /p "filename=请输入保存文件名: "
if "!filename!"=="" (
    echo 错误：输入不能为空！
    goto set_filename
)

::子标签中加上goto :eof命令即可退出子标签，不继续执行它下面的其它命令
goto :eof

::批量下载部分
::读取文件，合成参数，写入新文件并执行
:batch_input
::批量下载的输入输出,如不设定，默认为当前目录的input.txt，输出output.bat
:set_batchfile_input
set "batchfile_input="
echo.set /p "batchfile_input=请输入批量下载文件的文件名或完整路径(**.txt,留空确认则默认设置): "
if "!batchfile_input!" neq "" (
    set input=!batchfile_input!
)
:set_batchfile_output
set "batchfile_output="
echo.set /p "batchfile_output=请输入输出批量下载的文件名(留空确认则默认设置): "
if "!batchfile_output!" neq "" (
    set output=!batchfile_output!.bat
)
goto :eof

:: =============== 批量下载执行 ===============
:batch_excute
::拼接命令
set string2=--workDir "%SaveDir%" --headers "Cookie:MQGUID" --maxThreads "32" --minThreads "1" --retryCount "10" --timeOut "15" --enableBinaryMerge
::预先清理可能重名的文件
echo on>%output%

::获取总行数=待下载任务数
set /a count=0
for /F "delims=" %%i in (%input%) do (
	set /a count+=1	
)

set /a cur_line=0
for /F "tokens=1-2 delims=," %%a in (%input%) do (
	set /a cur_line+=1
	set filename=%%a
	set link=%%b
	set title=TITLE "!cur_line!/%count% - !filename!"
	set outstring=N_m3u8DL-CLI_v3.0.2 "!link!" --saveName "!filename!"  %string2%
	
	echo !title! >> %output%
	echo !outstring! >> %output%
)
::调用生成的文件进行下载
::cls
call %output%
echo off
goto :eof

:live_record_input
:set_record_limit
set "record_limit="
set /p "record_limit=请输入录制时长限制(格式：HH:mm:ss, 可为空): "
if "!record_limit!"=="" (
    set live_record_limit=
) else (
    set live_record_limit=--live-record-limit %record_limit%
    )

goto :eof


:: =============== 下载命令执行 ===============
:m3u8_download_print
echo 下载命令：

echo.下载命令：N_m3u8DL-CLI_v3.0.2 "%link%"   --workDir "%SaveDir%" --saveName "!filename!" %m3u8_params%
echo.
goto :eof

::下载命令
:m3u8_downloading
echo [%date% %time%] 开始下载: !filename! >> "!LOG_FILE!"
echo 开始下载，请稍候...
::将%filename%加引号，防止文件名带有某些符号导致路径识別失败
N_m3u8DL-CLI_v3.0.2 "%link%"  --workDir "%SaveDir%" --saveName "!filename!" %m3u8_params%
goto :eof

:live_record_print
echo.下载命令：N_m3u8DL-CLI_v3.0.2 "%link%"  --workDir "%SaveDir%" --saveName "!filename!"  %live_record_params%
goto :eof

:live_recording
echo [%date% %time%] 开始录制: !filename! >> "!LOG_FILE!"
echo 开始录制，按Ctrl+C可停止录制...
N_m3u8DL-CLI_v3.0.2 "%link%"  --workDir "%SaveDir%" --saveName "!filename!"  %live_record_params%
goto :eof

:: =============== 视频转换 ===============
:convert_video
echo 正在扫描视频文件...

set "VIDEO_DIR=!OutputDIR!"
set "converted_count=0"

if not exist "!VIDEO_DIR!*.*" (
    echo 错误：!VIDEO_DIR! 目录为空或不存在
    pause
    goto :eof
)

for %%i in ("!VIDEO_DIR!"*.mp4 "!VIDEO_DIR!"*.mkv "!VIDEO_DIR!"*.flv "!VIDEO_DIR!"*.avi "!VIDEO_DIR!"*.ts "!VIDEO_DIR!"*.mov "!VIDEO_DIR!"*.wmv) do (
    if exist "%%i" (
        set /a converted_count+=1
        echo [!converted_count!] 转换: %%~nxi
        
        :: 创建临时文件
        set "temp_output=!VIDEO_DIR!temp_!converted_count!.mp4"
        !ffmpeg! -i "%%i" -c copy "!temp_output!" -y -hide_banner -loglevel error
        
        if !errorlevel! equ 0 (
            :: 重命名为最终文件名
            set "final_name=!VIDEO_DIR!%%~ni.mp4"
            if exist "!final_name!" del "!final_name!" >nul 2>&1
            ren "!temp_output!" "%%~ni.mp4" >nul 2>&1
            echo     成功: %%~ni.mp4
        ) else (
            echo     失败: %%~nxi
            if exist "!temp_output!" del "!temp_output!" >nul 2>&1
        )
    )
)

if !converted_count! equ 0 (
    echo 未找到可转换的视频文件
) else (
    echo.
    echo 转换完成！共处理 !converted_count! 个文件
)
pause
goto :eof
:: =============== 工具函数 ===============
:check_m3u8dl_exe
if not exist "!m3u8dl!" (
    echo 错误：未找到 !m3u8dl!
    echo 请确保程序文件存在于当前目录
    pause
    goto main_menu
)
goto :eof

:check_ffmpeg_exe
if not exist "!ffmpeg!" (
    echo 错误：未找到 !ffmpeg!
    echo 请确保ffmpeg.exe存在于当前目录
    pause
    goto main_menu
)
goto :eof
:when_done
echo.
set /p "open_folder=是否打开下载目录？(Y/N，默认Y): "
if /i "!open_folder!"=="" set "open_folder=Y"
if /i "!open_folder!"=="Y" (
    echo [信息] 正在打开下载目录...
    if exist "!OutputDIR!" (
        start "" "!OutputDIR!"
    ) else (
        echo 下载目录不存在: !OutputDIR!
    )
)

set /p "return_menu=是否返回主菜单？(Y/N，默认Y): "
if /i "!return_menu!"=="" set "return_menu=Y"
if /i "!return_menu!"=="Y" (
    goto main_menu
) else (
    echo 程序将在3秒后退出...
    timeout /t 3 /nobreak >nul
    exit
)
goto :eof

:: =============== 程序结束 ===============
:end
echo 程序执行完毕
pause
exit

::---------------参数说明---------------

echo E:\本地磁盘G\电视\N_m3u8DL\N_m3u8DL-CLI_v3.0.2>N_m3u8DL-CLI_v3.0.2.exe -h
echo N_m3u8DL-CLI 3.0.2.0
echo 
echo USAGE:
echo 
echo   N_m3u8DL-CLI <URL|JSON|FILE> [OPTIONS]
echo 
echo OPTIONS:
echo 
echo ERROR(S):
echo   Option 'h' is unknown.
echo 
echo   --workDir                  设定程序工作目录
echo   --saveName                 设定存储文件名(不包括后缀)
echo   --baseUrl                  设定Baseurl
echo   --headers                  设定请求头，格式 key:value 使用|分割不同的key&value
echo   --maxThreads               (Default: 32) 设定程序的最大线程数
echo   --minThreads               (Default: 16) 设定程序的最小线程数
echo   --retryCount               (Default: 15) 设定程序的重试次数
echo   --timeOut                  (Default: 10) 设定程序网络请求的超时时间(单位为秒)
echo   --muxSetJson               使用外部json文件定义混流选项
echo   --useKeyFile               使用外部16字节文件定义AES-128解密KEY
echo   --useKeyBase64             使用Base64字符串定义AES-128解密KEY
echo   --useKeyIV                 使用HEX字符串定义AES-128解密IV
echo   --downloadRange            仅下载视频的一部分分片或长度
echo   --liveRecDur               直播录制时，达到此长度自动退出软件(HH:MM:SS)
echo   --stopSpeed                当速度低于此值时，重试(单位为KB/s)
echo   --maxSpeed                 设置下载速度上限(单位为KB/s)
echo   --proxyAddress             设置HTTP/SOCKS5代理, 如 http://127.0.0.1:8080
echo   --enableDelAfterDone       开启下载后删除临时文件夹的功能
echo   --enableMuxFastStart       开启混流mp4的FastStart特性
echo   --enableBinaryMerge        开启二进制合并分片
echo   --enableParseOnly          开启仅解析模式(程序只进行到meta.json)
echo   --enableAudioOnly          合并时仅封装音频轨道
echo   --disableDateInfo          关闭混流中的日期写入
echo   --disableIntegrityCheck    不检测分片数量是否完整
echo   --noMerge                  禁用自动合并
echo   --noProxy                  不自动使用系统代理
echo   --registerUrlProtocol      注册m3u8dl链接协议
echo   --unregisterUrlProtocol    取消注册m3u8dl链接协议
echo   --enableChaCha20           enableChaCha20
echo   --chaCha20KeyBase64        ChaCha20KeyBase64
echo   --chaCha20NonceBase64      ChaCha20NonceBase64
echo   --help                     Display this help screen.
echo   --version                  Display version information.
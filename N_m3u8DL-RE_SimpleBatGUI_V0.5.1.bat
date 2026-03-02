::记得保存为ASNI编码

@echo off & setlocal enabledelayedexpansion

::开始
Title N_m3u8DL-RE_x64_v0.5.1下载调用 by Lenno 2023.7.31经过修改

::界面颜色大小，Cols为宽，Lines为高
::0黑色1蓝色2绿色3浅绿色4红色5紫色6黄色7白色8灰色9淡蓝色
::A淡绿色B淡浅绿色C淡红色D淡紫色E淡黄色F亮白色
::mode con cols=100 lines=200
color 0b
cls

:: 切换到脚本所在目录
set "SCRIPT_DIR=%~dp0"
cd /d "!SCRIPT_DIR!"

:: 初始化设置
call :initialize_settings

:: 主菜单
:main_menu
::cls
echo.
echo  N_m3u8DL-RE 下载工具
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
set "m3u8dl=N_m3u8DL-RE_x64_v0.5.1.exe"
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
set m3u8_params=--download-retry-count:9 --log-level "INFO" --auto-select:true --check-segments-count:true --no-log:False --append-url-params:true -mt:true --mp4-real-time-decryption:true --ui-language:zh-CN --binary-merge:true --del-after-done:false --write-meta-json:true -M format=mp4



::设置直播录制参数
set live_record_params=--no-log:False -mt:true --mp4-real-time-decryption:true --ui-language:zh-CN -sv best -sa best --live-pipe-mux:true --live-keep-segments:false --live-fix-vtt-by-audio:true %live_record_limit% -M format=mp4:bin_path="%ffmpeg%"

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
cls
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
set string2=--tmp-dir "%TempDir%" --save-dir "%SaveDir%" --ffmpeg-binary-path "%ffmpeg%" %m3u8_params%
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
	set outstring=N_m3u8DL-RE_x64_v0.5.1 "!link!" --save-name "!filename!" %string2%
	
	echo !title! >> %output%
	echo !outstring! >> %output%
)
::调用生成的文件进行下载
cls
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
echo.下载命令：N_m3u8DL-RE_x64_v0.5.1 "%link%" %m3u8_params% --ffmpeg-binary-path %ffmpeg% --tmp-dir %TempDir% --save-dir %SaveDir% --save-name "%filename%"
echo.
goto :eof

::下载命令
:m3u8_downloading
echo [%date% %time%] 开始下载: !filename! >> "!LOG_FILE!"
echo 开始下载，请稍候...
::将%filename%加引号，防止文件名带有某些符号导致路径识別失败
N_m3u8DL-RE_x64_v0.5.1 "%link%" %m3u8_params% --ffmpeg-binary-path %ffmpeg% --tmp-dir %TempDir% --save-dir %SaveDir% --save-name "%filename%"
goto :eof

:live_record_print
echo.下载命令：N_m3u8DL-RE_x64_v0.5.1 "%link%" %live_record_params% --tmp-dir %TempDir% --save-dir %SaveDir% --save-name "%filename%"
goto :eof

:live_recording
echo [%date% %time%] 开始录制: !filename! >> "!LOG_FILE!"
echo 开始录制，按Ctrl+C可停止录制...



N_m3u8DL-RE_x64_v0.5.1 "%link%" %live_record_params% --tmp-dir %TempDir% --save-dir %SaveDir% --save-name "%filename%"
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
endlocal
exit

::---------------参数说明---------------

echo E:\本地磁盘G\电视\N_m3u8DL\N_m3u8DL-RE_Beta_win_x64>N_m3u8DL-RE_x64_v0.5.1.exe -h
echo Description:
echo   N_m3u8DL-RE (Beta version) 20251029
echo 
echo Usage:
echo   N_m3u8DL-RE_x64_v0.5.1 <input> [options]
echo 
echo Arguments:
echo   <input>  链接或文件
echo 
echo Options:
echo   --tmp-dir <tmp-dir>                                     设置临时文件存储目录
echo   --save-dir <save-dir>                                   设置输出目录
echo   --save-name <save-name>                                 设置保存文件名
echo   --save-pattern <save-pattern>                           设置保存文件命名模板, 支持使用变量:
echo                                                           <SaveName>, <Id>, <Codecs>, <Language>, <Resolution>,
echo                                                           <Bandwidth>, <MediaType>, <Channels>, <FrameRate>,
echo                                                           <VideoRange>, <GroupId>, <Ext>
echo                                                           示例: --save-pattern "<SaveName>_<Resolution>_<Bandwidth>"
echo   --log-file-path <log-file-path>                         设置日志文件路径, 例如 C:\Logs\log.txt
echo   --base-url <base-url>                                   设置BaseURL
echo   --thread-count <number>                                 设置下载线程数 [default: 8]
echo   --download-retry-count <number>                         每个分片下载异常时的重试次数 [default: 3]
echo   --http-request-timeout <seconds>                        HTTP请求的超时时间(秒) [default: 100]
echo   --force-ansi-console                                    强制认定终端为支持ANSI且可交互的终端
echo   --no-ansi-color                                         去除ANSI颜色
echo   --auto-select                                           自动选择所有类型的最佳轨道 [default: False]
echo   --skip-merge                                            跳过合并分片 [default: False]
echo   --skip-download                                         跳过下载 [default: False]
echo   --check-segments-count                                  检测实际下载的分片数量和预期数量是否匹配 [default: True]
echo   --binary-merge                                          二进制合并 [default: False]
echo   --use-ffmpeg-concat-demuxer                             使用 ffmpeg 合并时，使用 concat 分离器而非 concat 协议 [default: False]
echo   --del-after-done                                        完成后删除临时文件 [default: True]
echo   --no-date-info                                          混流时不写入日期信息 [default: False]
echo   --no-log                                                关闭日志文件输出 [default: False]
echo   --write-meta-json                                       解析后的信息是否输出json文件 [default: True]
echo   --append-url-params                                     将输入Url的Params添加至分片, 对某些网站很有用, 例如 kakao.com [default: False]
echo   -mt, --concurrent-download                              并发下载已选择的音频、视频和字幕 [default: False]
echo   -H, --header <header>                                   为HTTP请求设置特定的请求头, 例如:
echo                                                           -H "Cookie: mycookie" -H "User-Agent: iOS"
echo   --sub-only                                              只选取字幕轨道 [default: False]
echo   --sub-format <SRT|VTT>                                  字幕输出类型 [default: SRT]
echo   --auto-subtitle-fix                                     自动修正字幕 [default: True]
echo   --ffmpeg-binary-path <PATH>                             ffmpeg可执行程序全路径, 例如 C:\Tools\ffmpeg.exe
echo   --log-level <DEBUG|ERROR|INFO|OFF|WARN>                 设置日志级别 [default: INFO]
echo   --ui-language <en-US|zh-CN|zh-TW>                       设置UI语言
echo   --urlprocessor-args <urlprocessor-args>                 此字符串将直接传递给URL Processor
echo   --key <key>                                             设置解密密钥, 程序调用mp4decrpyt/shaka-packager/ffmpeg进行解密. 格式:
echo                                                           --key KID1:KEY1 --key KID2:KEY2
echo                                                           对于KEY相同的情况可以直接输入 --key KEY
echo   --key-text-file <key-text-file>                         设置密钥文件,程序将从文件中按KID搜寻KEY以解密.(不建议使用特大文件)
echo   --decryption-engine <FFMPEG|MP4DECRYPT|SHAKA_PACKAGER>  设置解密时使用的第三方程序 [default: MP4DECRYPT]
echo   --decryption-binary-path <PATH>                         MP4解密所用工具的全路径, 例如 C:\Tools\mp4decrypt.exe
echo   --mp4-real-time-decryption                              实时解密MP4分片 [default: False]
echo   -R, --max-speed <SPEED>                                 设置限速，单位支持 Mbps 或 Kbps，如：15M 100K
echo   -M, --mux-after-done <OPTIONS>                          所有工作完成时尝试混流分离的音视频. 输入 "--morehelp mux-after-done" 以查看详细信息
echo   --custom-hls-method <METHOD>                            指定HLS加密方式 (AES_128|AES_128_ECB|CENC|CHACHA20|NONE|SAMPLE_AES|SAMPLE_AES_CTR|UNKNOWN)
echo   --custom-hls-key <FILE|HEX|BASE64>                      指定HLS解密KEY. 可以是文件, HEX或Base64
echo   --custom-hls-iv <FILE|HEX|BASE64>                       指定HLS解密IV. 可以是文件, HEX或Base64
echo   --use-system-proxy                                      使用系统默认代理 [default: True]
echo   --custom-proxy <URL>                                    设置请求代理, 如 http://127.0.0.1:8888
echo   --custom-range <RANGE>                                  仅下载部分分片. 输入 "--morehelp custom-range" 以查看详细信息
echo   --task-start-at <yyyyMMddHHmmss>                        在此时间之前不会开始执行任务
echo   --live-perform-as-vod                                   以点播方式下载直播流 [default: False]
echo   --live-real-time-merge                                  录制直播时实时合并 [default: False]
echo   --live-keep-segments                                    录制直播并开启实时合并时依然保留分片 [default: True]
echo   --live-pipe-mux                                         录制直播并开启实时合并时通过管道+ffmpeg实时混流到TS文件 [default: False]
echo   --live-fix-vtt-by-audio                                 通过读取音频文件的起始时间修正VTT字幕 [default: False]
echo   --live-record-limit <HH:mm:ss>                          录制直播时的录制时长限制
echo   --live-wait-time <SEC>                                  手动设置直播列表刷新间隔
echo   --live-take-count <NUM>                                 手动设置录制直播时首次获取分片的数量 [default: 16]
echo   --mux-import <OPTIONS>                                  混流时引入外部媒体文件. 输入 "--morehelp mux-import" 以查看详细信息
echo   -sv, --select-video <OPTIONS>                           通过正则表达式选择符合要求的视频流. 输入 "--morehelp select-video" 以查看详细信息
echo   -sa, --select-audio <OPTIONS>                           通过正则表达式选择符合要求的音频流. 输入 "--morehelp select-audio" 以查看详细信息
echo   -ss, --select-subtitle <OPTIONS>                        通过正则表达式选择符合要求的字幕流. 输入 "--morehelp select-subtitle" 以查看详细信息
echo   -dv, --drop-video <OPTIONS>                             通过正则表达式去除符合要求的视频流.
echo   -da, --drop-audio <OPTIONS>                             通过正则表达式去除符合要求的音频流.
echo   -ds, --drop-subtitle <OPTIONS>                          通过正则表达式去除符合要求的字幕流.
echo   --ad-keyword <REG>                                      设置广告分片的URL关键字(正则表达式)
echo   --disable-update-check                                  禁用版本更新检测 [default: False]
echo   --allow-hls-multi-ext-map                               允许HLS中的多个#EXT-X-MAP(实验性) [default: False]
echo   --morehelp <OPTION>                                     查看某个选项的详细帮助信息
echo   -?, -h, --help                                          Show help and usage information
echo   --version                                               Show version information

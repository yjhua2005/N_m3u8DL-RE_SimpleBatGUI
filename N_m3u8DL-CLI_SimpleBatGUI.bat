
::记得保存为ASNI编码

@echo off & setlocal enabledelayedexpansion

::开始
Title N_m3u8DL-CLI_v3.0.2.exe下载调用 by Lenno 2023.7.31经过修改

::界面颜色大小，Cols为宽，Lines为高
::0黑色1蓝色2绿色3浅绿色4红色5紫色6黄色7白色8灰色9淡蓝色
::A淡绿色B淡浅绿色C淡红色D淡紫色E淡黄色F亮白色
mode con cols=80 lines=200
color 0a
::cls

::切换回当前目录
cd /d %~dp0

::菜单部分
:menu
::cls
ECHO.
ECHO  下载选项
echo.                   
ECHO. ***********************************************************
echo. *                                                         *
ECHO  *         1、m3u8视频单个下载                             *
echo. *                                                         *
ECHO  *         2、m3u8视频批量下载(先设置好input.txt)          *
echo. *                                                         *
ECHO  *         3、直播录制                                     *
echo. *                                                         *
ECHO. ***********************************************************
echo.
set /p a=请输入操作序号并回车输入2回车直接进入下载（1、2、3）：
::cls

if %a%==1 goto m3u8_download
if %a%==2 goto m3u8_batch_download
if %a%==3 goto live_record

::---------------设置部分start---------------
:setting_path
::设置临时文件存储目录
set TempDir=./Downloads/

::设置输出目录
set SaveDir=./Downloads

::设置ffmpeg.exe路徑。从批处理所在文件夹到Program Files共3层。
set ffmpeg=ffmpeg.exe

::设置输入文件input.txt，和输出的批量下载批处理output.bat
::input.txt格式为 要保存的文件名,m3u8下载链接
::input示例
::蜘蛛侠1,http://xx.xx.m3u8
::蜘蛛侠2,http://xx.xx.m3u8
set input=input.txt
set output=output.bat
goto :eof


:setting_m3u8_params
::设置m3u8下载参数
set m3u8_params=--headers "Cookie:MQGUID" --maxThreads "1" --minThreads "1" --retryCount "10" --timeOut "15" --enableBinaryMerge

goto :eof


:setting_live_record_params
::设置直播录制参数
set live_record_params=%live_record_limit%

goto :eof
::---------------设置部分end---------------

::开始下载
:m3u8_download
::cls
call :common_input
call :setting_path
call :setting_m3u8_params
call :m3u8_download_print
call :m3u8_downloading
call :when_done
goto :eof

:m3u8_batch_download
::cls
call :setting_path
call :batch_input
call :setting_m3u8_params
call :batch_excute
call :when_done
goto :eof

:live_record
call :common_input
call :live_record_input
call :setting_path
call :setting_live_record_params
call :live_record_print
call :live_recording
call :when_done
goto :eof


::---------------输入部分---------------
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

:batch_excute
::拼接命令
set string2=--workDir "%SaveDir%" --headers "Cookie:MQGUID" --maxThreads "1" --minThreads "1" --retryCount "10" --timeOut "15" --enableBinaryMerge
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

::---------------参数说明---------------
::--更多请参考作者的项目 https://github.com/nilaoda/N_m3u8DL-RE
::--tmp-dir <tmp-dir>                      设置临时文件存储目录
::--save-name <save-name>                  设置保存文件名
::--save-dir <save-dir>                    设置输出目录
::--download-retry-count <number>          每个分片下载异常时的重试次数 [default: 3]
::--auto-select                            自动选择所有类型的最佳轨道 [default: False]
::--ad-keyword                             选项过滤广告URL
::--check-segments-count                   检测实际下载的分片数量和预期数量是否匹配 [default: True]
::--no-log                                 关闭日志文件输出 [default: False]
::--append-url-params                      将输入Url的Params添加至分片, 对某些网站很有用 [default: False]
::-mt, --concurrent-download               并发下载已选择的音频、视频和字幕 [default: False]
::--mp4-real-time-decryption               实时解密MP4分片 [default: False]
::-M, --mux-after-done <OPTIONS>           所有工作完成时尝试混流分离的音视频
::--custom-range <RANGE>                   仅下载部分分片. 输入 "--morehelp custom-range" 以查看详细信息
::--ffmpeg-binary-path <PATH>              ffmpeg可执行程序全路径, 例如 C:\Tools\ffmpeg.exe
::--ui-language <en-US|zh-CN|zh-TW>        设置UI语言
::--live-keep-segments                     录制直播并开启实时合并时依然保留分片 [default: True]
::--live-pipe-mux                          录制直播并开启实时合并时通过管道+ffmpeg实时混流到TS文件 [default: False]
::--live-fix-vtt-by-audio                  通过读取音频文件的起始时间修正VTT字幕 [default: False]
::--live-record-limit <HH:mm:ss>           录制直播时的录制时长限制
::-sv, --select-video <OPTIONS>            通过正则表达式选择符合要求的视频流. 输入 "--morehelp select-video" 以查看详细信息
::-sa, --select-audio <OPTIONS>            通过正则表达式选择符合要求的音频流. 输入 "--morehelp select-audio" 以查看详细信息
::-ss, --select-subtitle <OPTIONS>         通过正则表达式选择符合要求的字幕流. 输入 "--morehelp select-subtitle" 以查看详细信息
::-dv, --drop-video <OPTIONS>              通过正则表达式去除符合要求的视频流.
::-da, --drop-audio <OPTIONS>              通过正则表达式去除符合要求的音频流.
::-ds, --drop-subtitle <OPTIONS>           通过正则表达式去除符合要求的字幕流.

::N_m3u8DL-CLI
::USAGE:
::  N_m3u8DL-CLI <URL|JSON|FILE> [OPTIONS]
::OPTIONS:
::  --workDir                  设定程序工作目录
::  --saveName                 设定存储文件名(不包括后缀)
::  --baseUrl                  设定Baseurl
::  --headers                  设定请求头，格式 key:value 使用|分割不同的key&value
::  --maxThreads               (Default: 32) 设定程序的最大线程数
::  --minThreads               (Default: 16) 设定程序的最小线程数
::  --retryCount               (Default: 15) 设定程序的重试次数
::  --timeOut                  (Default: 10) 设定程序网络请求的超时时间(单位为秒)
::  --muxSetJson               使用外部json文件定义混流选项
::  --useKeyFile               使用外部16字节文件定义AES-128解密KEY
::  --useKeyBase64             使用Base64字符串定义AES-128解密KEY
::  --useKeyIV                 使用HEX字符串定义AES-128解密IV
::  --downloadRange            仅下载视频的一部分分片或长度
::  --liveRecDur               直播录制时，达到此长度自动退出软件(HH:MM:SS)
::  --stopSpeed                当速度低于此值时，重试(单位为KB/s)
::  --maxSpeed                 设置下载速度上限(单位为KB/s)
::  --proxyAddress             设置HTTP/SOCKS5代理, 如 http://127.0.0.1:8080
::  --enableDelAfterDone       开启下载后删除临时文件夹的功能
::  --enableMuxFastStart       开启混流mp4的FastStart特性
::  --enableBinaryMerge        开启二进制合并分片
::  --enableParseOnly          开启仅解析模式(程序只进行到meta.json)
::  --enableAudioOnly          合并时仅封装音频轨道
::  --disableDateInfo          关闭混流中的日期写入
::  --disableIntegrityCheck    不检测分片数量是否完整
::  --noMerge                  禁用自动合并
::  --noProxy                  不自动使用系统代理
::  --registerUrlProtocol      注册m3u8dl链接协议
::  --unregisterUrlProtocol    取消注册m3u8dl链接协议
::  --enableChaCha20           enableChaCha20
::  --chaCha20KeyBase64        ChaCha20KeyBase64
::  --chaCha20NonceBase64      ChaCha20NonceBase64
::  --help                     Display this help screen.
::  --version                  Display version information.

::---------------输出部分---------------
:m3u8_download_print
echo.下载命令：N_m3u8DL-CLI_v3.0.2 "%link%"   --workDir "%SaveDir%" --saveName "!filename!" %m3u8_params%
::空一行
echo.
goto :eof

:live_record_print
echo.下载命令：N_m3u8DL-CLI_v3.0.2 "%link%"  --workDir "%SaveDir%" --saveName "!filename!"  %live_record_params%
::空一行
echo.
goto :eof


::下载命令
:m3u8_downloading
::将%filename%加引号，防止文件名带有某些符号导致路径识別失败
N_m3u8DL-CLI_v3.0.2 "%link%"  --workDir "%SaveDir%" --saveName "!filename!" %m3u8_params%
goto :eof

:live_recording
N_m3u8DL-CLI_v3.0.2 "%link%"  --workDir "%SaveDir%" --saveName "!filename!"  %live_record_params%
goto :eof

::下载完成暂停一段时间关闭窗口，防止运行报错时直接关闭窗口。
:when_done

timeout /t 100 /nobreak
exit
goto :eof


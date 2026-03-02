@echo off
chcp 936 >nul
cd /d "G:\LocalA\电视\N_m3u8DL\N_m3u8DL-RE_Beta_win_x64"
if not exist "Downloads" mkdir "Downloads"
if not exist "Logs" mkdir "Logs"
powershell -ExecutionPolicy Bypass -File "G:\LocalA\电视\N_m3u8DL\N_m3u8DL-RE_Beta_win_x64\m3u8dl-handler.ps1" "%1"
pause

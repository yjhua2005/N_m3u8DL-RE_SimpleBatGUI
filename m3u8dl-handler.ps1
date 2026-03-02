param([string]$RawArgument)

# 去除外层可能存在的引号，并去掉 "m3u8dl:" 前缀
if ($RawArgument -match '^"?(?:m3u8dl:)?(.*)"?$') {
    $encoded = $matches[1]
} else {
    $encoded = $RawArgument
}
$encoded = $encoded.Trim('"')
Write-Host "原始编码字符串: $encoded"

# URL解码
$decoded = [System.Uri]::UnescapeDataString($encoded)
Write-Host "解码后的命令行: $decoded"

# N_m3u8DL-RE 可执行文件路径
$exe = 'G:\LocalA\电视\N_m3u8DL\N_m3u8DL-RE_Beta_win_x64\m3u8dlre.exe'

# 解析参数列表（保留引号内的内容）
function Parse-Arguments {
    param([string]$cmdline)
    $argsList = @()
    $current = ""
    $inQuotes = $false
    $i = 0
    while ($i -lt $cmdline.Length) {
        $c = $cmdline[$i]
        if ($c -eq '"') {
            $inQuotes = -not $inQuotes
            $i++
        } elseif ($c -eq ' ' -and -not $inQuotes) {
            if ($current.Length -gt 0) {
                $argsList += $current
                $current = ""
            }
            $i++
        } else {
            $current += $c
            $i++
        }
    }
    if ($current.Length -gt 0) {
        $argsList += $current
    }
    return $argsList
}

$arguments = Parse-Arguments $decoded
# Write-Host "参数列表: $arguments"

cd G:\LocalA\电视\N_m3u8DL\N_m3u8DL-RE_Beta_win_x64\
Get-Location

# 启动进程并等待
Write-Host "正在执行: $exe $decoded"
$process = Start-Process -FilePath $exe -ArgumentList $arguments -Wait -NoNewWindow -PassThru
Write-Host "程序执行完毕，退出代码: $($process.ExitCode)"

Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
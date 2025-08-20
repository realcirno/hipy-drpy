# ����Ƿ��Թ���ԱȨ������
function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Host "��ǰû�й���ԱȨ�ޣ����ڳ����Թ���ԱȨ�����������ű�..."
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `$PSCommandPath" -Verb RunAs
        Wait-Process
        Exit
    }
}

# ������ԱȨ��
Check-Admin

# ������ļ�
Remove-Item -Path "ips_ports.txt" -ErrorAction SilentlyContinue
Clear-Host

# ��ӭ����
function Show-Welcome {
    Write-Host "###############################################"
    Write-Host "#                                             #"
    Write-Host "#       ��ӭʹ�� Cloudflare IP ������ѯ����   #"
    Write-Host "#               Blog: jhb.ovh                 #"
    Write-Host "#    Telegram: https://t.me/+ft-zI76oovgwNmRh #"
    Write-Host "#               ����bug���Ⱥ                 #"
    Write-Host "###############################################"
    Write-Host ""
}

# ��ʾ��ӭ����
Show-Welcome

# �������� CloudflareSpeedTest
function Install-CloudflareST {
    if (-not (Test-Path "./CloudflareSpeedTest.exe")) {
        Write-Host "δ��⵽ CloudflareSpeedTest����������..."
        
        $ARCH = (Get-CimInstance Win32_Processor).Architecture
        $URL = ""

        switch ($ARCH) {
            9 { $URL = "https://github.com/ShadowObj/CloudflareSpeedTest/releases/download/v2.2.6/CloudflareSpeedtest_win_amd64.exe" }
            12 { $URL = "https://github.com/ShadowObj/CloudflareSpeedTest/releases/download/v2.2.6/CloudflareSpeedtest_win_arm64.exe" }
            default {
                Write-Host "��֧�ֵļܹ�: $ARCH"
                Exit
            }
        }

        Invoke-WebRequest -Uri $URL -OutFile "CloudflareSpeedTest.exe"
    } else {
        Write-Host "CloudflareSpeedTest �Ѵ��ڣ��������ء�"
    }
}

# ��װ CloudflareSpeedTest
Install-CloudflareST

# ��ȡ����Ŀ¼�µ� *.csv �ļ�
$csvFiles = Get-ChildItem -Path . -Filter "*.csv"
if ($csvFiles.Count -eq 0) {
    Write-Host "δ��⵽ CSV �ļ�����ȷ������Ŀ¼�а�����Ч�� CSV �ļ���"
    Exit
}

# ���� CSV �ļ�����
Write-Host "��⵽���� CSV �ļ�:"
$csvFiles | ForEach-Object { Write-Host $_.Name }

foreach ($file in $csvFiles) {
    Write-Host "���ڴ����ļ�: $($file.Name)"
    try {
        # ��ȡ CSV �ļ�����
        $data = Import-Csv -Path $file.FullName -Delimiter ","  # ����ʹ�ö��ŷָ�

        foreach ($entry in $data) {
            if ($entry.ip -and $entry.port) {
                $output = "{0}:{1}" -f $entry.ip, $entry.port
                $output | Out-File -FilePath "ips_ports.txt" -Append -Encoding Ascii
            } else {
                Write-Host "�ļ� $($file.Name) �д�����Ч��Ŀ���������С�"
            }
        }

    } catch {
        Write-Host "�����ļ� $($file.Name) ʱ��������: $_"
    }
}

Write-Host "�����ļ�������ɣ�����ѱ��浽 ips_ports.txt��"

# ��ȡ CloudflareSpeedTest ����
$DN_COUNT = Read-Host "������ -dn ������Ҫ�����ٶȵ� IP ������[Ĭ��ֵ: 100]"
if (-not $DN_COUNT) { $DN_COUNT = 100 }

# ���� CloudflareSpeedTest ����
Write-Host "�������� CloudflareSpeedTest..."
./CloudflareSpeedTest.exe -f "ips_ports.txt" -dn $DN_COUNT -p 99999 -url "https://speed.cloudflare.com/__down?bytes=200000000" -sl 1 -tl 1000

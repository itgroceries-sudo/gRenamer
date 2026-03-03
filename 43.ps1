<# : hybrid batch + powershell script
@echo off
chcp 65001 >nul
mode con:cols=85 lines=20
title gRenam Remover by IT Groceries Shop

:: บังคับอ่านเป็น UTF8 เพื่อรองรับไฟล์ที่เกิดจากการกด Save
powershell -noprofile -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content -LiteralPath '%~f0' -Encoding UTF8 -Raw))"
exit /b
#>

# =========================================================
#  GRENAM REMOVER ULTIMATE
#  Version: 4.3 Build 04.03.2026 (The PS1 Transformation)
#  Framework: IT Groceries Shop (Layout Master)
# =========================================================

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$AppVersion = "4.3 Build 04.03.2026"
$InstallDir = "$env:LOCALAPPDATA\ITG_gRenamer"

# ลิงก์ต้นฉบับบน GitHub
$SelfURL    = "https://raw.githubusercontent.com/itgroceries-sudo/gRenamer/main/43.ps1"

$LangDict = @{
    "EN" = @{ 
        "Title"="gRenam Remover"; "Dev"="Developed by IT Groceries Shop™ ♥ ♥ ♥"; 
        "Facebook"="Facebook"; "GitHub"="GitHub"; "About"="About"; "Exit"="EXIT"; 
        "Processing"="Scanning..."; "Finished"="Completed"; "Start"="START SCAN";
        "LangLabel"="Language"; "Refresh"="REFRESH"; "SaveCMD"="SAVE .CMD";
        "AdvMode"="Advance Mode: Recover hidden orphaned files"
    }
    "TH" = @{ 
        "Title"="กำจัดไวรัส Grenam"; "Dev"="พัฒนาโดย IT Groceries Shop™ ♥ ♥ ♥"; 
        "Facebook"="Facebook"; "GitHub"="GitHub"; "About"="เกี่ยวกับ"; "Exit"="ออก"; 
        "Processing"="กำลังสแกน..."; "Finished"="เสร็จสิ้น"; "Start"="เริ่มการสแกน";
        "LangLabel"="ภาษา"; "Refresh"="รีเฟรช"; "SaveCMD"="สร้างไฟล์ .cmd";
        "AdvMode"="โหมดขั้นสูง: กู้คืนไฟล์ซ่อนที่ไม่มีตัวปลอม (Orphaned)"
    }
}

function Load-ScanTargets {
    $IconSys = "M4,6H20V16H4M20,18A2,2 0 0,0 22,16V6C22,4.89 21.1,4 20,4H4C2.89,4 2,4.89 2,6V16A2,2 0 0,0 4,18H0V20H24V18H20Z"
    $IconUSB = "M15,7V11H16V13H13V5L15,3V1H9V3L11,5V13H8V11H9V7H4V11H5V15L9,19V21H15V19L19,15V11H20V7H15Z"
    $IconCus = "M10,4H4C2.89,4 2,4.89 2,6V18A2,2 0 0,0 4,20H20A2,2 0 0,0 22,18V8C22,6.89 21.1,6 20,6H12L10,4Z"

    $arr = @()
    $arr += @{ ID="SYS"; Path="$env:SystemDrive\"; Icon=$IconSys; DescEN="Scan System Drive ($env:SystemDrive\)"; DescTH="สแกนไดรฟ์ระบบ ($env:SystemDrive\)" }

    $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Removable' -and $_.IsReady }
    foreach ($d in $drives) {
        $dl = $d.Name.Substring(0,2)
        $vl = $d.VolumeLabel
        $arr += @{ ID="USB_$dl"; Path="$dl\"; Icon=$IconUSB; DescEN="Scan USB Drive ($dl $vl)"; DescTH="สแกนแฟลชไดรฟ์ ($dl $vl)" }
    }

    $cusPath = ""
    if ($Global:ScanTargets) {
        $existingCUS = $Global:ScanTargets | Where-Object { $_.ID -eq "CUS" }
        if ($existingCUS) { $cusPath = $existingCUS.Path }
    }
    $arr += @{ ID="CUS"; Path=$cusPath; Icon=$IconCus; DescEN="Select Custom Folder..."; DescTH="เลือกโฟลเดอร์ที่ต้องการสแกน..." }
    
    $Global:ScanTargets = $arr
}

Load-ScanTargets

$SysRegion = (Get-Culture).TwoLetterISOLanguageName
$script:CurrentLang = if ($SysRegion -eq "th") { "TH" } else { "EN" }

$Silent = $false
$AllArgs = @(); if ($args) { $AllArgs += $args }; if ($param) { $AllArgs += $param.Split(" ") }
for ($i = 0; $i -lt $AllArgs.Count; $i++) { if ($AllArgs[$i] -eq "-Silent") { $Silent = $true } }

try {
    $User32 = Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags); [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad); [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int msg, int wParam, IntPtr lParam);' -Name "User32" -Namespace Win32 -PassThru
    $ConsoleHandle = [Win32.User32]::GetConsoleWindow()
} catch {}

# ---------------------------------------------------------
# [1] ELEVATION LOGIC: หลบการด่าของ CMD ด้วยการแปลงร่างเป็น .PS1 
# ---------------------------------------------------------
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]$Identity
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $Silent -and -not $IsAdmin) {
    if ($ConsoleHandle) { [Win32.User32]::ShowWindow($ConsoleHandle, 5) | Out-Null }
    try { $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(85, 20) } catch {} 

    $host.UI.RawUI.BackgroundColor = "DarkBlue"; $host.UI.RawUI.ForegroundColor = "White"; Clear-Host
    Write-Host "`n====================================================================================" -ForegroundColor DarkGray
    Write-Host "                    gRenam Remover [ Cloud Edition ]                                " -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host "                         Powered by IT Groceries Shop                               " -ForegroundColor DarkCyan -BackgroundColor DarkBlue
    Write-Host "====================================================================================" -ForegroundColor DarkGray
    Write-Host ""; Write-Host "         [ PERMISSION CHECK ] Press Enter, then click 'Yes' to continue: " -NoNewline -ForegroundColor White
    $null = Read-Host
    
    try {
        # ดึง Path ต้นฉบับมาให้ชัวร์
        $SourcePath = if ($ScriptPath -and (Test-Path -LiteralPath $ScriptPath)) { $ScriptPath } elseif ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) { $PSCommandPath } else { $null }
        
        if ($SourcePath) {
            $ScriptContent = Get-Content -LiteralPath $SourcePath -Raw
        } else {
            Write-Host "`n [INFO] Memory Execution Detected. Downloading..." -ForegroundColor Yellow
            $WebClient = New-Object System.Net.WebClient
            $WebClient.Encoding = [System.Text.Encoding]::UTF8
            $ScriptContent = $WebClient.DownloadString($SelfURL)
        }

        # ท่าไม้ตาย: ไม่ว่ารันมาจากไหน จับยัดลง Temp เปลี่ยนนามสกุลเป็น .ps1 ซะ!
        $TempScript = "$env:TEMP\gRenamer_Elevate.ps1"
        $Utf8WithBom = New-Object System.Text.UTF8Encoding($True)
        [System.IO.File]::WriteAllText($TempScript, $ScriptContent, $Utf8WithBom)
        
        # สั่งรัน PowerShell ตรงๆ โบกมือลาปัญหาหน้าต่างดำดับวับ 100%
        Start-Process "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs
        
    } catch { 
        Write-Host "`n [ERROR] Failed to elevate: $_" -ForegroundColor Red
        Start-Sleep 5
    }
    exit 
}

# ---------------------------------------------------------
# [2] MAIN EXECUTION BLOCK
# ---------------------------------------------------------
try {
    Add-Type -AssemblyName PresentationFramework, System.Windows.Forms, System.Drawing
    $Graphics = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $Scale = $Graphics.DpiX / 96.0; $Graphics.Dispose()

    $BaseW = 600; $BaseH = 750 
    $ConsoleW_Px = [int]($BaseW * $Scale); $ConsoleH_Px = [int]($BaseH * $Scale)
    $Scr = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $StartX_Px = ($Scr.Width - $ConsoleW_Px * 2) / 2; $StartY_Px = ($Scr.Height - $ConsoleH_Px) / 2
    $WindowX_WPF = ($StartX_Px + $ConsoleW_Px) / $Scale; $WindowY_WPF = $StartY_Px / $Scale

    if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null }
    $ConsoleIcon = "$InstallDir\ConsoleIcon.ico"
    if (-not (Test-Path $ConsoleIcon) -or (Get-Item $ConsoleIcon).Length -lt 100) {
        try { (New-Object Net.WebClient).DownloadFile("https://itgroceries.blogspot.com/favicon.ico", $ConsoleIcon) } catch {}
    }

    if ($Silent) { if ($ConsoleHandle) { [Win32.User32]::ShowWindow($ConsoleHandle, 0) | Out-Null } } else {
        try { $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(85, 9999) } catch {}
        if ($ConsoleHandle) { 
            [Win32.User32]::ShowWindow($ConsoleHandle, 5) | Out-Null
            [Win32.User32]::SetWindowPos($ConsoleHandle, [IntPtr]0, [int]$StartX_Px, [int]$StartY_Px, [int]$ConsoleW_Px, [int]$ConsoleH_Px, 0x0040) | Out-Null
            if (Test-Path $ConsoleIcon) {
                $h = [Win32.User32]::LoadImage([IntPtr]::Zero, $ConsoleIcon, 1, 0, 0, 0x10)
                if ($h) {
                    [Win32.User32]::SendMessage($ConsoleHandle, 0x80, [IntPtr]0, $h) | Out-Null
                    [Win32.User32]::SendMessage($ConsoleHandle, 0x80, [IntPtr]1, $h) | Out-Null
                }
            }
        }
    }

    $host.UI.RawUI.BackgroundColor = "Black"; $host.UI.RawUI.ForegroundColor = "Gray"; Clear-Host
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host "   (V.4.3 Build 04.03.2026 : INIT)      " -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host " [INFO] Loading Modules and Layout..." -ForegroundColor Green

    function Play-Sound($Type) { try { switch ($Type) { "Click" { [System.Media.SystemSounds]::Beep.Play() } "Tick" { [System.Console]::Beep(2000, 20) } "Warn" { [System.Media.SystemSounds]::Hand.Play() } "Done" { [System.Media.SystemSounds]::Asterisk.Play() } } } catch {} }

    if(!$Silent){ Write-Host " [INFO] Launching WPF GUI..." -ForegroundColor Yellow }

    $xamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="gRenam Remover by IT Groceries Shop" Height="750" Width="650" WindowStartupLocation="Manual" ResizeMode="NoResize" Background="#181818" WindowStyle="None" BorderBrush="#4CAF50" BorderThickness="2" FontFamily="Tahoma">
    <Window.Resources>
        <Style x:Key="BlueSwitch" TargetType="{x:Type CheckBox}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type CheckBox}">
                        <Border x:Name="T" Width="44" Height="24" Background="#3E3E3E" CornerRadius="22" Cursor="Hand">
                            <Border x:Name="D" Width="20" Height="20" Background="White" CornerRadius="20" HorizontalAlignment="Left" Margin="2,0,0,0">
                                <Border.RenderTransform><TranslateTransform x:Name="Tr" X="0"/></Border.RenderTransform>
                            </Border>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Trigger.EnterActions>
                                    <BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tr" Storyboard.TargetProperty="X" To="20" Duration="0:0:0.2"/><ColorAnimation Storyboard.TargetName="T" Storyboard.TargetProperty="Background.Color" To="#4CAF50" Duration="0:0:0.2"/></Storyboard></BeginStoryboard>
                                </Trigger.EnterActions>
                                <Trigger.ExitActions>
                                    <BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tr" Storyboard.TargetProperty="X" To="0" Duration="0:0:0.2"/><ColorAnimation Storyboard.TargetName="T" Storyboard.TargetProperty="Background.Color" To="#3E3E3E" Duration="0:0:0.2"/></Storyboard></BeginStoryboard>
                                </Trigger.ExitActions>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.5"/></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="Btn" TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="22">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.FontWeight="Bold"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.8"/></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="LabeledBtn" TargetType="Button">
            <Setter Property="Background" Value="#333333"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="50"/><Setter Property="Margin" Value="0,0,5,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="5" Padding="15,0,15,0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.FontWeight="Bold" TextElement.FontSize="16"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.8"/></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    
    <Grid Margin="25">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="20"/><RowDefinition Height="*"/><RowDefinition Height="120"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <Viewbox Grid.Column="0" Width="70" Height="70" Margin="0,0,15,0"><Path Fill="#4CAF50" Data="M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1M12,11.99H19C18.47,16.11 15.72,19.78 12,20.92V11.99H5V6.3L12,3.19M12,5.5A2.5,2.5 0 0,1 14.5,8A2.5,2.5 0 0,1 12,10.5A2.5,2.5 0 0,1 9.5,8A2.5,2.5 0 0,1 12,5.5Z"/></Viewbox>
            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="5,0,0,0">
                <TextBlock x:Name="T_Title" Text="gRenam Remover" Foreground="White" FontSize="26" FontWeight="Bold"><TextBlock.Effect><DropShadowEffect Color="#4CAF50" BlurRadius="15" Opacity="0.6"/></TextBlock.Effect></TextBlock>
                <StackPanel Orientation="Horizontal" Margin="2,5,0,0"><TextBlock x:Name="T_Dev" Text="Developed by IT Groceries Shop" Foreground="#4CAF50" FontSize="14" FontWeight="Bold"/></StackPanel>
            </StackPanel>
            <StackPanel Grid.Column="2" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,10,0,0">
                <Button x:Name="BFollow" Style="{StaticResource LabeledBtn}" Height="35" Background="#CC0000" Padding="10,0,10,0"><StackPanel Orientation="Horizontal"><Viewbox Width="18" Height="18" Margin="0,0,6,0"><Path Fill="White" Data="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></Viewbox><TextBlock Text="Follow" Foreground="White" VerticalAlignment="Center" FontWeight="Bold" FontSize="14"/></StackPanel></Button>
            </StackPanel>
        </Grid>
        <Border Grid.Row="2" Background="#1E1E1E" CornerRadius="5"><ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="List"/></ScrollViewer></Border>
        
        <Grid Grid.Row="3" Margin="0,15,0,8">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <Grid Grid.Row="0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center">
                    <Button x:Name="BA" Content="START SCAN" Width="260" Height="50" Background="#2E7D32" Foreground="White" Style="{StaticResource Btn}" Cursor="Hand" FontSize="18" Margin="0,0,10,0"/>
                    <Button x:Name="BSave" Content="SAVE .CMD" Width="100" Height="50" Background="#F57C00" Foreground="White" Style="{StaticResource Btn}" Cursor="Hand" FontSize="14" Margin="0,0,10,0"/>
                    <Button x:Name="BRefresh" Width="100" Height="50" Background="#1976D2" Foreground="White" Style="{StaticResource Btn}" Cursor="Hand"><StackPanel Orientation="Horizontal"><Path Fill="White" Data="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" Width="18" Height="18" Stretch="Uniform" Margin="0,0,5,0"/><TextBlock x:Name="T_Refresh" Text="REFRESH" VerticalAlignment="Center" FontWeight="Bold" FontSize="14"/></StackPanel></Button>
                </StackPanel>
            </Grid>
            <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,15,0,0">
                <CheckBox x:Name="ChkAdv" Foreground="#FFCCCCCC" Cursor="Hand"><TextBlock x:Name="T_Adv" Text="Advance Mode: Recover hidden orphaned files" FontSize="13" Margin="5,-2,0,0" Padding="0,0,0,5"/></CheckBox>
            </StackPanel>
        </Grid>
        
        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" Grid.Column="0">
                 <Button x:Name="BF" Style="{StaticResource LabeledBtn}"><StackPanel Orientation="Horizontal"><TextBlock Text="f" Foreground="#1877F2" FontSize="28" FontWeight="Bold" Margin="0,-4,8,0" VerticalAlignment="Center"/><TextBlock x:Name="T_FB" Text="Facebook" Foreground="White" VerticalAlignment="Center"/></StackPanel></Button>
                 <Button x:Name="BG" Style="{StaticResource LabeledBtn}"><StackPanel Orientation="Horizontal"><Viewbox Width="26" Height="26" Margin="0,0,8,0"><Path Fill="White" Data="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></Viewbox><TextBlock x:Name="T_Git" Text="GitHub" Foreground="White" VerticalAlignment="Center"/></StackPanel></Button>
                 <Button x:Name="BAbt" Style="{StaticResource LabeledBtn}" Background="#607D8B"><StackPanel Orientation="Horizontal"><Viewbox Width="26" Height="26" Margin="0,0,8,0"><Path Fill="White" Data="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 17h-2v-2h2v2zm2.07-7.75l-.9.92C13.45 12.9 13 13.5 13 15h-2v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-9-2-2-2s-2 .9-2 2H8c0-2.21 1.79-4 4-4s4 1.79 4 4c0 .88-.36 1.68-.93 2.25z"/></Viewbox><TextBlock x:Name="T_Abt" Text="About" Foreground="White" VerticalAlignment="Center"/></StackPanel></Button>
                 <Button x:Name="BLang" Style="{StaticResource LabeledBtn}" Background="#444"><StackPanel Orientation="Horizontal"><Viewbox Width="26" Height="26" Margin="0,0,8,0"><Path Fill="White" Data="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></Viewbox><TextBlock x:Name="T_Lang" Text="TH / EN" Foreground="White" VerticalAlignment="Center"/></StackPanel></Button>
            </StackPanel>
            <StackPanel Orientation="Horizontal" Grid.Column="2" HorizontalAlignment="Right">
                <Button x:Name="BC" Content="EXIT" Width="80" Height="50" Background="#D32F2F" Foreground="White" Style="{StaticResource Btn}" Cursor="Hand" FontSize="16"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlStr))
    $Window = [Windows.Markup.XamlReader]::Load($reader)
    try { $Window.Left = $WindowX_WPF; $Window.Top = $WindowY_WPF } catch {}

    $Stack=$Window.FindName("List"); $BA=$Window.FindName("BA"); $BC=$Window.FindName("BC"); 
    $BF=$Window.FindName("BF"); $BG=$Window.FindName("BG"); $BAbt=$Window.FindName("BAbt"); 
    $BLang=$Window.FindName("BLang"); $BFollow=$Window.FindName("BFollow"); $BRefresh=$Window.FindName("BRefresh")
    $ChkAdv=$Window.FindName("ChkAdv"); $T_Adv=$Window.FindName("T_Adv"); $BSave=$Window.FindName("BSave")

    $script:CurrentVal = "SYS"

    function Set-RadioLogic($SenderTag) {
        $script:CurrentVal = $SenderTag
        $bc = New-Object System.Windows.Media.BrushConverter
        foreach ($item in $Stack.Children) {
            $itemChk = $item.Child.Children[2]
            $itemIcon = $item.Child.Children[0].Child 
            if ($itemChk.Tag -ne $SenderTag) {
                $itemChk.IsChecked = $false
                $item.BorderBrush = $bc.ConvertFromString("#333333")
                $itemIcon.Fill = $bc.ConvertFromString("White")
            } else {
                $itemChk.IsChecked = $true
                $item.BorderBrush = $bc.ConvertFromString("#4CAF50")
                $itemIcon.Fill = $bc.ConvertFromString("#4CAF50")
            }
        }
        Update-StartButton
    }

    function Render-ModeList {
        $Stack.Children.Clear(); $D = $LangDict[$script:CurrentLang]
        $bc = New-Object System.Windows.Media.BrushConverter
        foreach ($m in $Global:ScanTargets) {
            $Row = New-Object System.Windows.Controls.Grid; $Row.Height = 42; $Row.Margin = "0,1,0,1"
            $col1 = New-Object System.Windows.Controls.ColumnDefinition; $col1.Width = [System.Windows.GridLength]::Auto
            $col2 = New-Object System.Windows.Controls.ColumnDefinition; $col2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
            $col3 = New-Object System.Windows.Controls.ColumnDefinition; $col3.Width = [System.Windows.GridLength]::Auto
            $Row.ColumnDefinitions.Add($col1); $Row.ColumnDefinitions.Add($col2); $Row.ColumnDefinitions.Add($col3)
            
            $Bor = New-Object System.Windows.Controls.Border; $Bor.CornerRadius = 5; $Bor.Background = $bc.ConvertFromString("#252526"); $Bor.Padding = "10,5,10,5"; $Bor.Child = $Row; $Bor.Cursor = "Hand"; $Bor.Tag = $m.ID
            $Bor.Margin = "0,0,0,4"; $Bor.BorderThickness = "1"; $Bor.BorderBrush = $bc.ConvertFromString("#333333")
            
            $IconViewbox = New-Object System.Windows.Controls.Viewbox; $IconViewbox.Width = 24; $IconViewbox.Height = 24; $IconViewbox.Margin = "5,0,10,0"
            $IconPath = New-Object System.Windows.Shapes.Path; $IconPath.Fill = $bc.ConvertFromString("White"); $IconPath.Data = [System.Windows.Media.Geometry]::Parse($m.Icon)
            $IconViewbox.Child = $IconPath
            
            $Txt = New-Object System.Windows.Controls.TextBlock; 
            $descText = if ($script:CurrentLang -eq "TH") { $m.DescTH } else { $m.DescEN }
            if ($m.ID -eq "CUS" -and $m.Path -ne "") { $descText = "[Path] " + $m.Path }
            $Txt.Text = $descText
            $Txt.Foreground="White"; $Txt.FontSize=16; $Txt.FontWeight="SemiBold"; $Txt.VerticalAlignment="Center"; $Txt.Margin="5,0,0,0"; $Txt.Padding="0,0,0,5"
            
            $Chk = New-Object System.Windows.Controls.CheckBox; $Chk.Style=$Window.Resources["BlueSwitch"]; $Chk.VerticalAlignment="Center"; $Chk.Tag = $m.ID 
            
            if ($m.ID -eq $script:CurrentVal) { 
                $Chk.IsChecked = $true
                $Bor.BorderBrush = $bc.ConvertFromString("#4CAF50")
                $IconPath.Fill = $bc.ConvertFromString("#4CAF50")
            }
            
            [System.Windows.Controls.Grid]::SetColumn($IconViewbox,0); $Row.Children.Add($IconViewbox)|Out-Null
            [System.Windows.Controls.Grid]::SetColumn($Txt,1); $Row.Children.Add($Txt)|Out-Null
            [System.Windows.Controls.Grid]::SetColumn($Chk,2); $Row.Children.Add($Chk)|Out-Null
            $Stack.Children.Add($Bor)|Out-Null
            
            $ClickAction = {
                param($sender, $e)
                Play-Sound "Tick"
                if ($sender.Tag -eq "CUS") {
                    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                    $dialog.Description = "Select target folder to scan"
                    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                        $target = $Global:ScanTargets | Where-Object { $_.ID -eq "CUS" }
                        $target.Path = $dialog.SelectedPath
                        Render-ModeList; Set-RadioLogic "CUS"
                    } else { Set-RadioLogic "SYS" }
                } else { Set-RadioLogic $sender.Tag }
            }
            $Chk.Add_Click($ClickAction); $Bor.Add_MouseLeftButtonUp($ClickAction)
        }
    }

    function Update-Language {
        $D = $LangDict[$script:CurrentLang]
        $Window.FindName("T_Title").Text = $D["Title"]; $Window.FindName("T_Dev").Text = $D["Dev"]
        $Window.FindName("T_FB").Text = $D["Facebook"]; $Window.FindName("T_Git").Text = $D["GitHub"]
        $Window.FindName("T_Abt").Text = $D["About"]; $BC.Content = $D["Exit"]; $BA.Content = $D["Start"]
        $Window.FindName("T_Refresh").Text = $D["Refresh"]; $T_Adv.Text = $D["AdvMode"]
        $Window.FindName("T_Lang").Text = $D["LangLabel"]; $BSave.Content = $D["SaveCMD"]
        Render-ModeList
    }

    function Update-StartButton {
        $HasTarget = @($Stack.Children | Where-Object { $_.Child.Children[2].IsChecked }).Count -gt 0
        if ($HasTarget) { $BA.IsEnabled = $true; $BA.Opacity = 1.0; $BA.Cursor = "Hand" } else { $BA.IsEnabled = $false; $BA.Opacity = 0.5; $BA.Cursor = "No" }
    }

    Update-Language; Update-StartButton

    # =========================================================
    # ระบบ SAVE โคตรฉลาด: ดึงตัวล่าสุด และบันทึกเป็น BOM ป้องกันเอ๋อ
    # =========================================================
    $BSave.Add_Click({
        Play-Sound "Click"
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "Command Script (*.cmd)|*.cmd"
        $sfd.FileName = "gRenam_Remover_V5.cmd"
        $sfd.Title = "Save Offline Version"
        
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $SourcePath = if ($ScriptPath -and (Test-Path -LiteralPath $ScriptPath)) { $ScriptPath }
                              elseif ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) { $PSCommandPath }
                              else { $null }

                if ($SourcePath) {
                    $ScriptContent = Get-Content -LiteralPath $SourcePath -Encoding UTF8 -Raw
                } else {
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.Encoding = [System.Text.Encoding]::UTF8
                    $ScriptContent = $WebClient.DownloadString($SelfURL)
                }

                $Utf8WithBom = New-Object System.Text.UTF8Encoding($True)
                [System.IO.File]::WriteAllText($sfd.FileName, $ScriptContent, $Utf8WithBom)
                
                [System.Windows.MessageBox]::Show("Offline file successfully generated at:`n" + $sfd.FileName, "Success", 0, 64) | Out-Null
            } catch {
                [System.Windows.MessageBox]::Show("Failed to save file: $_", "Error", 0, 16) | Out-Null
            }
        }
    })

    $BRefresh.Add_Click({
        Play-Sound "Click"; Load-ScanTargets
        $stillExists = $Global:ScanTargets | Where-Object { $_.ID -eq $script:CurrentVal }
        if (-not $stillExists) { $script:CurrentVal = "SYS" }
        Render-ModeList
        if(!$Silent){ Write-Host "`n [INFO] Drive List Refreshed." -ForegroundColor Yellow }
    })

    $BFollow.Add_Click({ Start-Process "https://www.youtube.com/c/itgroceries?sub_confirmation=1"; Play-Sound "Click" })
    $BF.Add_Click({ Start-Process "https://www.facebook.com/Adm1n1straTOE"; Play-Sound "Click" })
    $BG.Add_Click({ Start-Process "https://github.com/itgroceries-sudo/gRenamer"; Play-Sound "Click" }) 
    $BAbt.Add_Click({ Play-Sound "Click"; [System.Windows.MessageBox]::Show("gRenam Remover`nVersion: $AppVersion`n`nDeveloped by IT Groceries Shop", "About", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })
    $BLang.Add_Click({ if ($script:CurrentLang -eq "EN") { $script:CurrentLang = "TH" } else { $script:CurrentLang = "EN" }; Play-Sound "Click"; Update-Language })
    $BC.Add_Click({ Play-Sound "Click"; if(!$Silent){ Write-Host "`n [EXIT] Clean & Bye !!" -ForegroundColor Cyan }; [System.Windows.Forms.Application]::DoEvents(); Start-Sleep 1; if ($PSCommandPath -eq $TempScript) { Start-Process "cmd.exe" -ArgumentList "/c timeout /t 2 >nul & del `"$TempScript`"" -WindowStyle Hidden }; $Window.Close(); [Environment]::Exit(0) })
    
    $BA.Add_Click({ 
        Play-Sound "Click"
        $Sel = @($Stack.Children | Where-Object { $_.Child.Children[2].IsChecked })
        if ($Sel.Count -eq 0) { return }
        
        $BA.IsEnabled = $false; $BA.Content = $LangDict[$script:CurrentLang]["Processing"]
        $SelectedID = $Sel[0].Tag
        $TargetObj = $Global:ScanTargets | Where-Object { $_.ID -eq $SelectedID }
        $TargetPath = $TargetObj.Path
        $IsAdvance = $ChkAdv.IsChecked
        
        if(!$Silent){ 
            Write-Host "`n========================================================" -ForegroundColor Cyan
            Write-Host " [SCANNING] Target: $TargetPath" -ForegroundColor Yellow 
            if ($IsAdvance) { Write-Host " [MODE] Advance Mode Enabled" -ForegroundColor Magenta }
            Write-Host "========================================================" -ForegroundColor Cyan
        }
        
        try {
            $foundCount = 0
            $files = Get-ChildItem -Path $TargetPath -Filter "g*.exe" -Recurse -Force -ErrorAction SilentlyContinue

            if ($files -eq $null -or @($files).Count -eq 0) {
                if(!$Silent){ Write-Host " [OK] System clean. No suspicious files found." -ForegroundColor Green }
            } else {
                foreach ($hiddenFile in $files) {
                    if ($hiddenFile.PSIsContainer) { continue }
                    $hiddenName = $hiddenFile.Name
                    if ($hiddenName[0] -cne 'g') { continue }
                    $realNameClean = $hiddenName.Substring(1)
                    if ([string]::IsNullOrEmpty($realNameClean)) { continue }
                    $virusFullPath = Join-Path -Path $hiddenFile.DirectoryName -ChildPath $realNameClean
                    $isHidden = (($hiddenFile.Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden)
                    
                    if ($IsAdvance) {
                        if ($isHidden) {
                            if(!$Silent){ Write-Host "`n [ADVANCE] Location: $($hiddenFile.DirectoryName)`n    -> Hidden Orphan : $hiddenName" -ForegroundColor Magenta }
                            if (Test-Path $virusFullPath) { Remove-Item -Path $virusFullPath -Force -ErrorAction SilentlyContinue; if(!$Silent){ Write-Host "    -> [DELETE] Fake Virus Removed." -ForegroundColor Green } }
                            $hiddenFile.Attributes = $hiddenFile.Attributes -band -bnot [System.IO.FileAttributes]::Hidden -band -bnot [System.IO.FileAttributes]::System -band -bnot [System.IO.FileAttributes]::ReadOnly
                            Rename-Item -Path $hiddenFile.FullName -NewName $realNameClean -Force -ErrorAction SilentlyContinue
                            if (Test-Path $virusFullPath) { if(!$Silent){ Write-Host "    -> [RESTORE] SUCCESS" -ForegroundColor Cyan }; $foundCount++ }
                        }
                    } else {
                        if (Test-Path $virusFullPath) {
                            if(!$Silent){ Write-Host "`n [MATCH] Location: $($hiddenFile.DirectoryName)`n    -> Hidden File : $hiddenName`n    -> Virus File  : $realNameClean" -ForegroundColor Yellow }
                            Remove-Item -Path $virusFullPath -Force -ErrorAction SilentlyContinue
                            if(!$Silent){ Write-Host "    -> [DELETE] Fake Virus Removed." -ForegroundColor Green }
                            $hiddenFile.Attributes = $hiddenFile.Attributes -band -bnot [System.IO.FileAttributes]::Hidden -band -bnot [System.IO.FileAttributes]::System -band -bnot [System.IO.FileAttributes]::ReadOnly
                            Rename-Item -Path $hiddenFile.FullName -NewName $realNameClean -Force -ErrorAction SilentlyContinue
                            if (Test-Path $virusFullPath) { if(!$Silent){ Write-Host "    -> [RESTORE] SUCCESS" -ForegroundColor Cyan }; $foundCount++ }
                        }
                    }
                }
            }
            if(!$Silent){ Write-Host "========================================================`n [DONE] Scan finished. Total fixed: $foundCount item(s).`n========================================================" -ForegroundColor White }
        } catch { if(!$Silent){ Write-Host " [ERROR] $_" -ForegroundColor Red } }

        $BA.Content = $LangDict[$script:CurrentLang]["Finished"]; Play-Sound "Done"; Start-Sleep 2
        $BA.IsEnabled = $true; $BA.Content = $LangDict[$script:CurrentLang]["Start"]
    })
    $Window.ShowDialog() | Out-Null
} catch {
    Write-Host "`n [FATAL ERROR] The application crashed:" -ForegroundColor Red
    Write-Host " $_" -ForegroundColor Red
    Write-Host "`n Press Enter to exit..." -ForegroundColor Gray
    Read-Host
}

<# : hybrid batch + powershell script
@echo off
chcp 65001 >nul
mode con:cols=85 lines=20
title gRenam Remover by IT Groceries Shop

:: Auto-Admin Elevation (Same logic as WinUpdate Fixer)
powershell -noprofile -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"
exit /b
#>

# =========================================================
#  GRENAM REMOVER ULTIMATE
#  Version: 2.8 Build 03.03.2026 (IEX/IRM Optimized)
#  Framework: IT Groceries Shop (Layout Master)
# =========================================================

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ---------------------------------------------------------
# [1] CONFIG & LANGUAGE
# ---------------------------------------------------------
$AppVersion = "2.8 Build 03.03.2026"
$InstallDir = "$env:LOCALAPPDATA\ITG_gRenamer"
$TempScript = "$env:TEMP\gRenamer_Temp.ps1"
$SelfURL    = "https://raw.githubusercontent.com/itgroceries-sudo/gRenamer/main/gRenamer.ps1"
$TargetFile = if ($ScriptPath) { $ScriptPath } elseif ($PSScriptRoot) { $PSCommandPath } else { $null }

function Write-SafeTempScript {
    param([string]$FilePath, [string]$Content)
    [System.IO.File]::WriteAllText($FilePath, $Content, (New-Object System.Text.UTF8Encoding($True)))
}

$LangDict = @{
    "EN" = @{ 
        "Title"="gRenam Remover"; "Dev"="Developed by IT Groceries Shop™ ♥ ♥ ♥"; 
        "Facebook"="Facebook"; "GitHub"="GitHub"; "About"="About"; "Exit"="EXIT"; 
        "Processing"="Scanning..."; "Finished"="Completed"; "Start"="START SCAN";
        "LangLabel"="Language"; "Refresh"="REFRESH";
        "AdvMode"="Advance Mode: Recover hidden orphaned files"
    }
    "TH" = @{ 
        "Title"="กำจัดไวรัส Grenam"; "Dev"="พัฒนาโดย IT Groceries Shop™ ♥ ♥ ♥"; 
        "Facebook"="Facebook"; "GitHub"="GitHub"; "About"="เกี่ยวกับ"; "Exit"="ออก"; 
        "Processing"="กำลังสแกน..."; "Finished"="เสร็จสิ้น"; "Start"="เริ่มการสแกน";
        "LangLabel"="ภาษา"; "Refresh"="รีเฟรช";
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

# ---------------------------------------------------------
# [2] API IMPORTS
# ---------------------------------------------------------
try {
    $User32 = Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags); [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad); [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int msg, int wParam, IntPtr lParam);' -Name "User32" -Namespace Win32 -PassThru
    $ConsoleHandle = [Win32.User32]::GetConsoleWindow()
} catch {}

# ---------------------------------------------------------
# [3] ELEVATION LOGIC (Proven WinUpdateFix Style)
# ---------------------------------------------------------
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]$Identity
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    if ($ConsoleHandle) { [Win32.User32]::ShowWindow($ConsoleHandle, 5) | Out-Null }
    try { $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(85, 20) } catch {} 

    $host.UI.RawUI.BackgroundColor = "DarkBlue"; $host.UI.RawUI.ForegroundColor = "White"; Clear-Host
    Write-Host "`n====================================================================================" -ForegroundColor DarkGray
    Write-Host "                    gRenam Remover [ Cloud Edition ]                              " -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host "                         Powered by IT Groceries Shop                               " -ForegroundColor DarkCyan -BackgroundColor DarkBlue
    Write-Host "====================================================================================" -ForegroundColor DarkGray
    Write-Host ""; Write-Host "         [ PERMISSION CHECK ] Press Enter, then click 'Yes' to continue: " -NoNewline -ForegroundColor White
    $null = Read-Host
    
    try {
        if ($TargetFile -and (Test-Path $TargetFile)) {
            if ($TargetFile -match '\.(cmd|bat)$') { Start-Process -FilePath "$TargetFile" -Verb RunAs }
            else { Start-Process "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TargetFile`"" -Verb RunAs }
        } else {
            $WebClient = New-Object System.Net.WebClient; $WebClient.Encoding = [System.Text.Encoding]::UTF8
            $ScriptContent = $WebClient.DownloadString($SelfURL)
            [System.IO.File]::WriteAllText($TempScript, $ScriptContent, (New-Object System.Text.UTF8Encoding($True)))
            Start-Process "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs
        }
    } catch { Write-Host "`n [ERROR] Failed to elevate: $_" -ForegroundColor Red; Read-Host }
    exit 
}

# ---------------------------------------------------------
# [4] GUI PREP & CONSOLE LAYOUT
# ---------------------------------------------------------
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
$Graphics = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $Scale = $Graphics.DpiX / 96.0; $Graphics.Dispose()

$BaseW = 600; $BaseH = 750 
$ConsoleW_Px = [int]($BaseW * $Scale); $ConsoleH_Px = [int]($BaseH * $Scale)
$Scr = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$StartX_Px = ($Scr.Width - ($ConsoleW_Px * 2)) / 2; $StartY_Px = ($Scr.Height - $ConsoleH_Px) / 2
$WindowX_WPF = ($StartX_Px + $ConsoleW_Px) / $Scale; $WindowY_WPF = $StartY_Px / $Scale

if ($ConsoleHandle) { 
    [Win32.User32]::ShowWindow($ConsoleHandle, 5) | Out-Null
    [Win32.User32]::SetWindowPos($ConsoleHandle, [IntPtr]0, [int]$StartX_Px, [int]$StartY_Px, [int]$ConsoleW_Px, [int]$ConsoleH_Px, 0x0040) | Out-Null
}

Clear-Host
Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "   (V.2.8 Build 03.03.2026 : INIT)      " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host " [INFO] Loading Modules and Layout..." -ForegroundColor Green

function Play-Sound($Type) { try { switch ($Type) { "Click" { [System.Media.SystemSounds]::Beep.Play() } "Tick" { [System.Console]::Beep(2000, 20) } "Done" { [System.Media.SystemSounds]::Asterisk.Play() } } } catch {} }

# ---------------------------------------------------------
# [5] XAML UI
# ---------------------------------------------------------
try {
    [xml]$xaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
Title="gRenam Remover" Height="750" Width="650" WindowStartupLocation="Manual" ResizeMode="NoResize" Background="#181818" WindowStyle="None" BorderBrush="#4CAF50" BorderThickness="2" FontFamily="Tahoma">
    <Window.Resources>
        <Style x:Key="BlueSwitch" TargetType="CheckBox">
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="CheckBox"><Border x:Name="T" Width="44" Height="24" Background="#3E3E3E" CornerRadius="22" Cursor="Hand"><Border x:Name="D" Width="20" Height="20" Background="White" CornerRadius="20" HorizontalAlignment="Left" Margin="2,0,0,0"><Border.RenderTransform><TranslateTransform x:Name="Tr" X="0"/></Border.RenderTransform></Border></Border><ControlTemplate.Triggers><Trigger Property="IsChecked" Value="True"><Trigger.EnterActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tr" Storyboard.TargetProperty="X" To="20" Duration="0:0:0.2"/><ColorAnimation Storyboard.TargetName="T" Storyboard.TargetProperty="Background.Color" To="#4CAF50" Duration="0:0:0.2"/></Storyboard></BeginStoryboard></Trigger.EnterActions><Trigger.ExitActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tr" Storyboard.TargetProperty="X" To="0" Duration="0:0:0.2"/><ColorAnimation Storyboard.TargetName="T" Storyboard.TargetProperty="Background.Color" To="#3E3E3E" Duration="0:0:0.2"/></Storyboard></BeginStoryboard></Trigger.ExitActions></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
        </Style>
        <Style x:Key="Btn" TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="22"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.FontWeight="Bold"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.8"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
        <Style x:Key="LabeledBtn" TargetType="Button"><Setter Property="Background" Value="#333333"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="50"/><Setter Property="Margin" Value="0,0,5,0"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="5" Padding="15,0,15,0"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.FontWeight="Bold" TextElement.FontSize="16"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.8"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    </Window.Resources>
    <Grid Margin="25">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="20"/><RowDefinition Height="*"/><RowDefinition Height="100"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <Viewbox Grid.Column="0" Width="70" Height="70" Margin="0,0,15,0"><Path Fill="#4CAF50" Data="M12,1L3,5V11C3,16.55 6.84,21.74 12,23C17.16,21.74 21,16.55 21,11V5L12,1M12,11.99H19C18.47,16.11 15.72,19.78 12,20.92V11.99H5V6.3L12,3.19M12,5.5A2.5,2.5 0 0,1 14.5,8A2.5,2.5 0 0,1 12,10.5A2.5,2.5 0 0,1 9.5,8A2.5,2.5 0 0,1 12,5.5Z"/></Viewbox>
            <StackPanel Grid.Column="1" VerticalAlignment="Center">
                <TextBlock x:Name="T_Title" Text="gRenam Remover" Foreground="White" FontSize="26" FontWeight="Bold"><TextBlock.Effect><DropShadowEffect Color="#4CAF50" BlurRadius="15" Opacity="0.6"/></TextBlock.Effect></TextBlock>
                <TextBlock x:Name="T_Dev" Text="Developed by IT Groceries Shop" Foreground="#4CAF50" FontSize="14" FontWeight="Bold" Margin="0,5,0,0"/>
            </StackPanel>
            <Button Grid.Column="2" x:Name="BFollow" Style="{StaticResource LabeledBtn}" Height="35" Background="#CC0000"><StackPanel Orientation="Horizontal"><Viewbox Width="18" Height="18" Margin="0,0,6,0"><Path Fill="White" Data="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></Viewbox><TextBlock Text="Follow" Foreground="White" VerticalAlignment="Center" FontWeight="Bold" FontSize="14"/></StackPanel></Button>
        </Grid>
        <Border Grid.Row="2" Background="#1E1E1E" CornerRadius="5"><ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="List"/></ScrollViewer></Border>
        <Grid Grid.Row="3" Margin="0,15,0,8">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <StackPanel Grid.Column="1" HorizontalAlignment="Center">
                <Button x:Name="BA" Content="START SCAN" Width="300" Height="55" Background="#2E7D32" Foreground="White" Style="{StaticResource Btn}" FontSize="18"/>
                <CheckBox x:Name="ChkAdv" Foreground="#FFCCCCCC" HorizontalAlignment="Center" Margin="0,10,0,0"><TextBlock x:Name="T_Adv" FontSize="13" Margin="5,0,0,0" Padding="0,0,0,8"/></CheckBox>
            </StackPanel>
            <Button Grid.Column="2" x:Name="BRefresh" Width="100" Height="50" Background="#1976D2" Foreground="White" Style="{StaticResource Btn}" HorizontalAlignment="Right" VerticalAlignment="Top"><StackPanel Orientation="Horizontal"><Path Fill="White" Data="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" Width="18" Height="18" Stretch="Uniform" Margin="0,0,5,0"/><TextBlock x:Name="T_Refresh" VerticalAlignment="Center" FontWeight="Bold" FontSize="14"/></StackPanel></Button>
        </Grid>
        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" Grid.Column="0">
                 <Button x:Name="BF" Style="{StaticResource LabeledBtn}"><TextBlock Text="f" Foreground="#1877F2" FontSize="28" FontWeight="Bold" Margin="0,-4,8,0"/></Button>
                 <Button x:Name="BG" Style="{StaticResource LabeledBtn}"><Viewbox Width="26" Height="26"><Path Fill="White" Data="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></Viewbox></Button>
                 <Button x:Name="BLang" Style="{StaticResource LabeledBtn}" Background="#444"><TextBlock x:Name="T_Lang_Btn" Foreground="White" VerticalAlignment="Center"/></Button>
            </StackPanel>
            <Button Grid.Column="2" x:Name="BC" Content="EXIT" Width="100" Height="50" Background="#D32F2F" Foreground="White" Style="{StaticResource Btn}" FontSize="16"/>
        </Grid>
    </Grid>
</Window>'

    $reader = (New-Object System.Xml.XmlNodeReader $xaml); $Window = [Windows.Markup.XamlReader]::Load($reader)
    if ($WindowX_WPF) { $Window.Left = $WindowX_WPF; $Window.Top = $WindowY_WPF }

    $Stack=$Window.FindName("List"); $BA=$Window.FindName("BA"); $BC=$Window.FindName("BC"); 
    $BF=$Window.FindName("BF"); $BG=$Window.FindName("BG"); $BLang=$Window.FindName("BLang")
    $BFollow=$Window.FindName("BFollow"); $BRefresh=$Window.FindName("BRefresh")
    $ChkAdv=$Window.FindName("ChkAdv"); $T_Adv=$Window.FindName("T_Adv")
    $T_Lang_Btn=$Window.FindName("T_Lang_Btn")

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
    }

    function Render-ModeList {
        $Stack.Children.Clear(); $bc = New-Object System.Windows.Media.BrushConverter
        foreach ($m in $Global:ScanTargets) {
            $Row = New-Object System.Windows.Controls.Grid; $Row.Height = 42; $Row.Margin = "0,1,0,1"
            $Row.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width=[System.Windows.GridLength]::Auto}))
            $Row.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width=[System.Windows.GridLength]::new(1, "Star")}))
            $Row.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width=[System.Windows.GridLength]::Auto}))
            $Bor = New-Object System.Windows.Controls.Border; $Bor.CornerRadius = 5; $Bor.Background = $bc.ConvertFromString("#252526"); $Bor.Padding = "10,5,10,5"
            $Bor.Margin = "0,0,0,4"; $Bor.BorderThickness = 1; $Bor.BorderBrush = $bc.ConvertFromString("#333333")
            $IconViewbox = New-Object System.Windows.Controls.Viewbox; $IconViewbox.Width = 24; $IconViewbox.Height = 24; $IconViewbox.Margin = "5,0,10,0"
            $IconPath = New-Object System.Windows.Shapes.Path; $IconPath.Fill = $bc.ConvertFromString("White"); $IconPath.Data = [System.Windows.Media.Geometry]::Parse($m.Icon)
            $IconViewbox.Child = $IconPath
            $Txt = New-Object System.Windows.Controls.TextBlock; $Txt.VerticalAlignment="Center"; $Txt.Foreground="White"; $Txt.FontSize=16
            $Txt.Text = if ($script:CurrentLang -eq "TH") { $m.DescTH } else { $m.DescEN }
            if ($m.ID -eq "CUS" -and $m.Path -ne "") { $Txt.Text = "[Path] " + $m.Path }
            $Chk = New-Object System.Windows.Controls.CheckBox; $Chk.Style=$Window.Resources["BlueSwitch"]; $Chk.VerticalAlignment="Center"; $Chk.Tag = $m.ID 
            if ($m.ID -eq $script:CurrentVal) { $Chk.IsChecked = $true; $Bor.BorderBrush = $bc.ConvertFromString("#4CAF50"); $IconPath.Fill = $bc.ConvertFromString("#4CAF50") }
            [System.Windows.Controls.Grid]::SetColumn($IconViewbox,0); $Row.Children.Add($IconViewbox)|Out-Null
            [System.Windows.Controls.Grid]::SetColumn($Txt,1); $Row.Children.Add($Txt)|Out-Null
            [System.Windows.Controls.Grid]::SetColumn($Chk,2); $Row.Children.Add($Chk)|Out-Null
            $Bor.Child = $Row; $Stack.Children.Add($Bor)|Out-Null
            $Bor.Add_MouseLeftButtonUp({ param($s,$e) Play-Sound "Tick"; Set-RadioLogic $s.Tag; if($s.Tag -eq "CUS") { 
                $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; if($dialog.ShowDialog() -eq "OK") { 
                    ($Global:ScanTargets | ?{$_.ID -eq "CUS"}).Path = $dialog.SelectedPath; Render-ModeList; Set-RadioLogic "CUS"
                }
            }})
        }
    }

    function Update-Language {
        $D = $LangDict[$script:CurrentLang]
        $Window.FindName("T_Title").Text = $D["Title"]; $Window.FindName("T_Dev").Text = $D["Dev"]
        $BC.Content = $D["Exit"]; $BA.Content = $D["Start"]; $T_Refresh = $Window.FindName("T_Refresh"); if($T_Refresh){$T_Refresh.Text = $D["Refresh"]}
        $T_Adv.Text = $D["AdvMode"]; $T_Lang_Btn.Text = if($script:CurrentLang -eq "TH"){"ภาษา: ไทย"}else{"LANG: EN"}
        Render-ModeList
    }

    Update-Language
    $BRefresh.Add_Click({ Play-Sound "Tick"; Load-ScanTargets; Render-ModeList })
    $BFollow.Add_Click({ Start-Process "https://www.youtube.com/c/itgroceries?sub_confirmation=1" })
    $BF.Add_Click({ Start-Process "https://www.facebook.com/Adm1n1straTOE" })
    $BG.Add_Click({ Start-Process "https://github.com/itgroceries-sudo/gRenamer" }) 
    $BLang.Add_Click({ $script:CurrentLang = if($script:CurrentLang -eq "EN"){"TH"}else{"EN"}; Update-Language })
    $BC.Add_Click({ $Window.Close() })

    $BA.Add_Click({ 
        Play-Sound "Tick"; $SelectedID = $script:CurrentVal; $TargetObj = $Global:ScanTargets | ?{$_.ID -eq $SelectedID}; $TargetPath = $TargetObj.Path
        if ([string]::IsNullOrEmpty($TargetPath)) { return }; $BA.IsEnabled = $false; $IsAdvance = $ChkAdv.IsChecked
        Write-Host "`n========================================================" -ForegroundColor Cyan
        Write-Host " [SCANNING] Target: $TargetPath" -ForegroundColor Yellow 
        try {
            $foundCount = 0; $files = Get-ChildItem -Path $TargetPath -Filter "g*.exe" -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($hF in $files) {
                if ($hF.PSIsContainer -or $hF.Name[0] -cne "g") { continue }
                $rN = $hF.Name.Substring(1); if (!$rN) { continue }; $vP = Join-Path $hF.DirectoryName $rN
                $isH = (($hF.Attributes -band [System.IO.FileAttributes]::Hidden) -eq [System.IO.FileAttributes]::Hidden)
                if (($IsAdvance -and $isH) -or (Test-Path $vP)) {
                    if (Test-Path $vP) { Remove-Item $vP -Force -ErrorAction SilentlyContinue }
                    $hF.Attributes = $hF.Attributes -band -bnot [System.IO.FileAttributes]::Hidden
                    $hF.Attributes = $hF.Attributes -band -bnot [System.IO.FileAttributes]::System
                    $hF.Attributes = $hF.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly
                    Rename-Item $hF.FullName -NewName $rN -Force -ErrorAction SilentlyContinue
                    Write-Host " -> Restored: $rN" -ForegroundColor Green; $foundCount++
                }
            }
            Write-Host " [DONE] Total fixed: $foundCount" -ForegroundColor White
        } catch { Write-Host " [ERROR] $_" -ForegroundColor Red }
        Play-Sound "Done"; $BA.IsEnabled = $true
    })

    $Window.ShowDialog() | Out-Null

} catch {
    Write-Host "`n [FATAL ERROR] The application crashed: $_" -ForegroundColor Red
    Start-Sleep 5
}

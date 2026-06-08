# Registers the OAuth callback URL scheme for Windows desktop development.
# Run once per machine (or after moving the built .exe):
#   powershell -ExecutionPolicy Bypass -File scripts/register_auth_protocol.ps1

$scheme = "com.schoolmgmt.app"
$exePath = Join-Path $PSScriptRoot "..\build\windows\x64\runner\Debug\school_management.exe"

if (-not (Test-Path $exePath)) {
    $exePath = Join-Path $PSScriptRoot "..\build\windows\x64\runner\Release\school_management.exe"
}

if (-not (Test-Path $exePath)) {
    Write-Error "Build the Windows app first: flutter build windows"
    exit 1
}

$exePath = (Resolve-Path $exePath).Path
$classesKey = "Registry::HKEY_CURRENT_USER\Software\Classes\$scheme"

New-Item -Path $classesKey -Force | Out-Null
Set-ItemProperty -Path $classesKey -Name "(default)" -Value "URL:School Management Auth"
New-ItemProperty -Path $classesKey -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null

$commandKey = "$classesKey\shell\open\command"
New-Item -Path $commandKey -Force | Out-Null
Set-ItemProperty -Path $commandKey -Name "(default)" -Value "`"$exePath`" `"%1`""

Write-Host "Registered $scheme -> $exePath"
Write-Host "Add this redirect URL in Supabase: ${scheme}://login-callback/"

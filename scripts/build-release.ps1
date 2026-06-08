param(
  [Parameter(Mandatory = $true)]
  [string]$Version,
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY,
  [string]$AppBaseUrl = $env:APP_BASE_URL,
  [string]$PublicWebsiteUrl = $env:PUBLIC_WEBSITE_URL
)

$ErrorActionPreference = "Stop"
$defines = @(
  "SUPABASE_URL=$SupabaseUrl",
  "SUPABASE_ANON_KEY=$SupabaseAnonKey",
  "APP_BASE_URL=$AppBaseUrl",
  "PUBLIC_WEBSITE_URL=$PublicWebsiteUrl"
) | ForEach-Object { "--dart-define=$_" }

Write-Host "Building v$Version ..." -ForegroundColor Cyan
flutter pub get

flutter build windows --release @defines
$winZip = "school-management-$Version-windows.zip"
if (Test-Path $winZip) { Remove-Item $winZip }
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath $winZip

flutter build apk --release @defines
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "school-management-$Version-android.apk" -Force

flutter build web --release @defines
Copy-Item "deploy\flutter-web-vercel.json" "build\web\vercel.json" -Force

Write-Host ""
Write-Host "Done:" -ForegroundColor Green
Write-Host "  $winZip"
Write-Host "  school-management-$Version-android.apk"
Write-Host "  build\web\  (deploy to Vercel)"
Write-Host ""
Write-Host "Tag and push for GitHub Actions:" -ForegroundColor Yellow
Write-Host "  git tag v$Version"
Write-Host "  git push origin v$Version"

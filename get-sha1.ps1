## Quick SHA-1 Retrieval Script

# Method 1: Using keytool directly (fastest)
Write-Host "`n=== GETTING SHA-1 CERTIFICATE FOR GOOGLE SIGN-IN ===" -ForegroundColor Cyan
Write-Host "`nThis is needed to configure Google Sign-In on Android" -ForegroundColor Yellow
Write-Host "`n--- Debug Certificate SHA-1 ---`n" -ForegroundColor Green

$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

if (Test-Path $debugKeystore) {
    Write-Host "Found debug keystore at: $debugKeystore`n" -ForegroundColor White
    
    $output = keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android 2>&1
    
    $sha1 = $output | Select-String "SHA1:" | ForEach-Object { $_.ToString().Trim() }
    $sha256 = $output | Select-String "SHA256:" | ForEach-Object { $_.ToString().Trim() }
    
    if ($sha1) {
        Write-Host "✅ SHA-1: " -ForegroundColor Green -NoNewline
        Write-Host $sha1.Replace("SHA1:", "").Trim() -ForegroundColor Yellow
        Write-Host ""
        Write-Host "✅ SHA-256: " -ForegroundColor Green -NoNewline
        Write-Host $sha256.Replace("SHA256:", "").Trim() -ForegroundColor Yellow
        
        Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
        Write-Host "1. Copy the SHA-1 value above" -ForegroundColor White
        Write-Host "2. Go to: https://console.firebase.google.com" -ForegroundColor White
        Write-Host "3. Select your project" -ForegroundColor White
        Write-Host "4. Go to: Settings (⚙️) → Project Settings" -ForegroundColor White
        Write-Host "5. Scroll to 'Your apps' section" -ForegroundColor White
        Write-Host "6. Find Android app: com.example.komunidadapp" -ForegroundColor White
        Write-Host "7. Click 'Add fingerprint'" -ForegroundColor White
        Write-Host "8. Paste the SHA-1 value" -ForegroundColor White
        Write-Host "9. Click Save" -ForegroundColor White
        Write-Host "10. Download new google-services.json" -ForegroundColor White
        Write-Host "11. Replace android/app/google-services.json" -ForegroundColor White
        Write-Host "12. Run: flutter clean && flutter run" -ForegroundColor White
    } else {
        Write-Host "❌ Could not extract SHA-1" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Debug keystore not found at: $debugKeystore" -ForegroundColor Red
    Write-Host "`nTo create it, run an Android app once from Android Studio or:" -ForegroundColor Yellow
    Write-Host "flutter run" -ForegroundColor White
}

Write-Host "`n"

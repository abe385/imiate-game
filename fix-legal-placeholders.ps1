$privacyPath = "C:\word-chain-worker\imiate-game\privacy.html"
$termsPath = "C:\word-chain-worker\imiate-game\terms.html"

foreach ($p in @($privacyPath, $termsPath)) {
    $backup = "$p.backup"
    Copy-Item $p $backup -Force
    Write-Host "バックアップを作成しました: $backup"
}

function ReplaceOnce($content, $find, $replaceWith, $label) {
    $idx = $content.IndexOf($find)
    if ($idx -lt 0) {
        Write-Host "エラー: 置換対象が見つかりませんでした ($label)" -ForegroundColor Red
        return $null
    }
    Write-Host "$label : OK" -ForegroundColor Green
    return $content.Substring(0, $idx) + $replaceWith + $content.Substring($idx + $find.Length)
}

$today = "2026年8月27日"

# ---- privacy.html の公開日 ----
$content = Get-Content -Raw -Encoding UTF8 $privacyPath
$find = '<span class="placeholder">[公開日を記入]</span>'
$replace = $today
$result = ReplaceOnce $content $find $replace "① privacy.html の公開日"
if ($result) {
    Set-Content -Path $privacyPath -Value $result -Encoding UTF8 -NoNewline
}

# ---- terms.html の公開日・管轄裁判所 ----
$content = Get-Content -Raw -Encoding UTF8 $termsPath
$find2 = '<span class="placeholder">[公開日を記入]</span>'
$replace2 = $today
$result = ReplaceOnce $content $find2 $replace2 "② terms.html の公開日"
if ($result) { $content = $result }

$find3 = '<span class="placeholder">[管轄裁判所を記入。通常はご自身の住所地を管轄する裁判所]</span>'
$replace3 = "神戸地方裁判所"
$result = ReplaceOnce $content $find3 $replace3 "③ terms.html の管轄裁判所"
if ($result) { $content = $result }

Set-Content -Path $termsPath -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup8"

if (-not (Test-Path $path)) {
    Write-Host "エラー: imiate.html が見つかりません: $path" -ForegroundColor Red
    exit 1
}

Copy-Item $path $backup -Force
Write-Host "バックアップを作成しました: $backup"

$content = Get-Content -Raw -Encoding UTF8 $path

function ReplaceOnce($content, $find, $replaceWith, $label) {
    $idx = $content.IndexOf($find)
    if ($idx -lt 0) {
        Write-Host "エラー: 置換対象が見つかりませんでした ($label)" -ForegroundColor Red
        return $null
    }
    Write-Host "$label : OK" -ForegroundColor Green
    return $content.Substring(0, $idx) + $replaceWith + $content.Substring($idx + $find.Length)
}

# ---- ① accountBar 全体の文字を大きく、明るい色に ----
$find1 = @'
  .accountBar{
    font-size:12px; color:#c9d2e8; margin-top:8px; display:flex;
    gap:8px; justify-content:center; flex-wrap:wrap;
  }
'@
$replace1 = @'
  .accountBar{
    font-size:16px; color:#eef1fb; margin-top:12px; display:flex;
    gap:10px; justify-content:center; flex-wrap:wrap; align-items:center;
    padding:8px 12px; background:rgba(255,255,255,0.08); border-radius:10px;
  }
'@
$result = ReplaceOnce $content $find1 $replace1 "① accountBar本体"
if ($result) { $content = $result }

# ---- ② accountBar内のボタン(アップグレード・ログアウト・契約管理)専用の見やすい色を追加 ----
$find2 = @'
  .linkBtn{
    background:none; border:none; color:#c99a1f; font-size:15px; font-weight:700;
    text-decoration:underline; cursor:pointer; padding:0; font-family:inherit;
  }
'@
$replace2 = @'
  .linkBtn{
    background:none; border:none; color:#c99a1f; font-size:15px; font-weight:700;
    text-decoration:underline; cursor:pointer; padding:0; font-family:inherit;
  }
  .accountBar .linkBtn{
    color:#ffe08a; font-size:16px; font-weight:900; text-decoration:underline;
    text-underline-offset:3px;
  }
'@
$result = ReplaceOnce $content $find2 $replace2 "② accountBar内ボタンの色"
if ($result) { $content = $result }

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


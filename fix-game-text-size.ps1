$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup6"

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

# ---- ① ヘッダー下の「今日のお題の単語を...」を大きく ----
$find1 = @'
  .header .sub{ font-size:13px; color:#c9d2e8; }
'@
$replace1 = @'
  .header .sub{ font-size:16px; color:#e4e9f7; line-height:1.6; }
'@
$result = ReplaceOnce $content $find1 $replace1 "① ヘッダー説明文"
if ($result) { $content = $result }

# ---- ② ルール説明文(単語を1つ入力すると...)を大きく ----
$find2 = @'
  .rule{ font-size:16px; color:#000000; font-weight:500; text-align:center; margin-bottom:14px; line-height:1.7; }
'@
$replace2 = @'
  .rule{ font-size:19px; color:#000000; font-weight:600; text-align:center; margin-bottom:16px; line-height:1.8; }
'@
$result = ReplaceOnce $content $find2 $replace2 "② ルール説明文"
if ($result) { $content = $result }

# ---- ③ 補足の小さい注意書き(※ 順位はAIが...)も少し大きく ----
$find3 = @'
    <span style="font-size:14px; color:#000000;">※ 順位はAIが「文章での使われ方の似ている度合い」で計算しています。生き物の分類など、人の直感とズレることもあります。それも含めて楽しんでください。</span>
'@
$replace3 = @'
    <span style="font-size:16px; color:#000000;">※ 順位はAIが「文章での使われ方の似ている度合い」で計算しています。生き物の分類など、人の直感とズレることもあります。それも含めて楽しんでください。</span>
'@
$result = ReplaceOnce $content $find3 $replace3 "③ 補足注意書き"
if ($result) { $content = $result }

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


$path = "C:\word-chain-worker\imiate-game\imiate.html"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup_$timestamp"

if (-not (Test-Path $path)) {
    Write-Host "エラー: imiate.html が見つかりません: $path" -ForegroundColor Red
    exit 1
}

Copy-Item $path $backup -Force
Write-Host "バックアップを作成しました: $backup"

$content = Get-Content -Raw -Encoding UTF8 $path

if ($content.Contains("function formatDate(")) {
    Write-Host "すでに formatDate が追加済みのようです。二重適用防止のため中止します。" -ForegroundColor Yellow
    exit 0
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

# ---- ① formatDate関数を追加(daysLeft関数の直後)----
$find1 = @'
  function daysLeft(unixSec){
    if(!unixSec) return 0;
    return Math.max(0, Math.ceil((unixSec - Math.floor(Date.now() / 1000)) / 86400));
  }
'@
$replace1 = @'
  function daysLeft(unixSec){
    if(!unixSec) return 0;
    return Math.max(0, Math.ceil((unixSec - Math.floor(Date.now() / 1000)) / 86400));
  }

  function formatDate(unixSec){
    if(!unixSec) return '';
    const d = new Date(unixSec * 1000);
    return `${d.getMonth() + 1}月${d.getDate()}日`;
  }
'@
$result = ReplaceOnce $content $find1 $replace1 "① formatDate関数の追加"
if ($result) { $content = $result } else { exit 1 }

# ---- ② 表示文言を「残り○日」から「無料期限終了日:○月○日」に変更 ----
$find2 = '🎁 無料期間中(残り${daysLeft(authStatus.trialEndsAt)}日)'
$replace2 = '🎁 無料期間中(無料期限終了日:${formatDate(authStatus.trialEndsAt)})'
$result = ReplaceOnce $content $find2 $replace2 "② 表示文言の変更"
if ($result) { $content = $result } else { exit 1 }

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


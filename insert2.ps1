# ============================================================
# imiate.html の els オブジェクト拡張・イベント登録・ペイウォール連携
# ============================================================

$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup2"

if (-not (Test-Path $path)) {
    Write-Host "エラー: imiate.html が見つかりません: $path" -ForegroundColor Red
    exit 1
}

Copy-Item $path $backup -Force
Write-Host "バックアップを作成しました: $backup"

$content = Get-Content -Raw -Encoding UTF8 $path

function ReplaceOnce($content, $find, $replaceWith) {
    $idx = $content.IndexOf($find)
    if ($idx -lt 0) { throw "置換対象が見つかりませんでした: $find" }
    return $content.Substring(0, $idx) + $replaceWith + $content.Substring($idx + $find.Length)
}

try {
    # ---- ① els オブジェクトに新しい要素を追加 ----
    $find1 = @'
    round2: document.getElementById('round2Btn'),
  };
'@
    $replace1 = @'
    round2: document.getElementById('round2Btn'),
    accountBar: document.getElementById('accountBar'),
    loginOverlay: document.getElementById('loginOverlay'),
    paywallOverlay: document.getElementById('paywallOverlay'),
    authEmail: document.getElementById('authEmail'),
    authPassword: document.getElementById('authPassword'),
    authError: document.getElementById('authError'),
    authSubmitBtn: document.getElementById('authSubmitBtn'),
    authSwitchBtn: document.getElementById('authSwitchBtn'),
  };
'@
    $content = ReplaceOnce $content $find1 $replace1
    Write-Host "① els オブジェクトへの追加: OK" -ForegroundColor Green

    # ---- ② submitGuess() の冒頭にペイウォールチェックを追加 ----
    $find2 = @'
  function submitGuess(){
    if(won) return;
'@
    $replace2 = @'
  function submitGuess(){
    if(authStatus && authStatus.status === 'expired'){ showPaywall(true); return; }
    if(won) return;
'@
    $content = ReplaceOnce $content $find2 $replace2
    Write-Host "② submitGuess() へのチェック追加: OK" -ForegroundColor Green

    # ---- ③ giveUpNow() の冒頭にペイウォールチェックを追加 ----
    $find3 = @'
  function giveUpNow(){
    if(won) return;
'@
    $replace3 = @'
  function giveUpNow(){
    if(authStatus && authStatus.status === 'expired'){ showPaywall(true); return; }
    if(won) return;
'@
    $content = ReplaceOnce $content $find3 $replace3
    Write-Host "③ giveUpNow() へのチェック追加: OK" -ForegroundColor Green

    # ---- ④ </script> の直前に、ログイン・課金関連のイベント登録を追加 ----
    $eventCode = @'

  els.authSubmitBtn.addEventListener('click', handleAuthSubmit);
  els.authSwitchBtn.addEventListener('click', toggleAuthMode);
  els.authPassword.addEventListener('keydown', e => { if(e.key === 'Enter') handleAuthSubmit(); });
  document.getElementById('paywallUpgradeBtn').addEventListener('click', startCheckout);
  document.getElementById('paywallLogoutBtn').addEventListener('click', logout);
  refreshAuthStatus().then(checkBillingReturn);
'@
    $lastScriptIdx = $content.LastIndexOf('</script>')
    if ($lastScriptIdx -lt 0) { throw "</script> タグが見つかりませんでした" }
    $content = $content.Substring(0, $lastScriptIdx) + $eventCode + "`n" + $content.Substring($lastScriptIdx)
    Write-Host "④ イベント登録の追加: OK" -ForegroundColor Green

    Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host ""
    Write-Host "✅ すべての修正が完了しました!" -ForegroundColor Green
} catch {
    Write-Host "❌ エラーが発生しました: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "ファイルは変更されていません。" -ForegroundColor Yellow
}


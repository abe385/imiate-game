$path = "C:\word-chain-worker\imiate-game\imiate.html"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup_$timestamp"

Copy-Item $path $backup -Force
Write-Host "バックアップを作成しました: $backup"

$content = Get-Content -Raw -Encoding UTF8 $path

$find = @'
  function toggleAuthMode(){
    isSignupMode = !isSignupMode;
    document.getElementById('authTitle').textContent = isSignupMode ? 'はじめまして' : 'おかえりなさい';
    els.authSubmitBtn.textContent = isSignupMode ? '無料で始める' : 'ログイン';
    els.authSwitchBtn.textContent = isSignupMode ? 'ログインする' : '新規登録する';
    els.authError.textContent = '';
    els.authPasswordConfirm.style.display = isSignupMode ? 'block' : 'none';
    els.authPasswordConfirm.value = '';
  }
'@
$replace = @'
  function toggleAuthMode(){
    isSignupMode = !isSignupMode;
    document.getElementById('authTitle').textContent = isSignupMode ? 'はじめまして' : 'おかえりなさい';
    els.authSubmitBtn.textContent = isSignupMode ? '無料で始める' : 'ログイン';
    els.authSwitchBtn.textContent = isSignupMode ? 'ログインする' : '新規登録する';
    els.authError.textContent = '';
    els.authPasswordConfirm.style.display = isSignupMode ? 'block' : 'none';
    els.authPasswordConfirm.value = '';
    els.forgotPasswordWrap.style.display = isSignupMode ? 'none' : 'block';
  }
'@

$idx = $content.IndexOf($find)
if ($idx -lt 0) {
    Write-Host "エラー: 挿入位置が見つかりませんでした" -ForegroundColor Red
    exit 1
}
$content = $content.Substring(0, $idx) + $replace + $content.Substring($idx + $find.Length)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host "追加しました" -ForegroundColor Green


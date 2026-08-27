$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup11"

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

# ---- ① CSS: タブ切り替えボタンのスタイルを追加 ----
$find1 = @'
  .modalBox h2{
    font-family:'Shippori Mincho', serif; font-size:28px; margin:0 0 10px;
  }
'@
$replace1 = @'
  .authTabs{
    display:flex; gap:8px; margin-bottom:18px; background:var(--paper-dim);
    border-radius:12px; padding:4px;
  }
  .authTabs button{
    flex:1; padding:12px 8px; border:none; border-radius:9px; font-size:16px;
    font-weight:700; cursor:pointer; background:none; color:#5a5647; font-family:inherit;
  }
  .authTabs button.activeTab{
    background:var(--accent); color:#fff;
  }
  .modalBox h2{
    font-family:'Shippori Mincho', serif; font-size:28px; margin:0 0 10px;
  }
'@
$result = ReplaceOnce $content $find1 $replace1 "① CSS: タブスタイルの追加"
if ($result) { $content = $result }

# ---- ② HTML: 小さいリンクをタブに差し替え ----
$find2 = @'
<div class="modalOverlay" id="loginOverlay">
  <div class="modalBox">
    <h2 id="authTitle">はじめまして</h2>
    <p>メールアドレスと、お好きなパスワード(8文字以上)を決めるだけで始められます。メール認証は不要です。<br>登録すると7日間無料でお試しいただけます。</p>
    <div class="authError" id="authError"></div>
    <input type="email" id="authEmail" placeholder="メールアドレス" autocomplete="email">
    <input type="password" id="authPassword" placeholder="パスワード(8文字以上)" autocomplete="new-password">
    <input type="password" id="authPasswordConfirm" placeholder="パスワード(確認用・もう一度入力)" autocomplete="new-password">
    <button class="primaryBtn" id="authSubmitBtn">無料で始める</button>
    <div class="switchText">
      すでにアカウントをお持ちですか?
      <button class="linkBtn" id="authSwitchBtn">ログインする</button>
    </div>
  </div>
</div>
'@
$replace2 = @'
<div class="modalOverlay" id="loginOverlay">
  <div class="modalBox">
    <div class="authTabs">
      <button id="tabSignup" class="activeTab">🆕 はじめての方</button>
      <button id="tabLogin">🔑 2回目以降の方(ログイン)</button>
    </div>
    <h2 id="authTitle">はじめまして</h2>
    <p id="authDesc">メールアドレスと、お好きなパスワード(8文字以上)を決めるだけで始められます。メール認証は不要です。<br>登録すると7日間無料でお試しいただけます。</p>
    <div class="authError" id="authError"></div>
    <input type="email" id="authEmail" placeholder="メールアドレス" autocomplete="email">
    <input type="password" id="authPassword" placeholder="パスワード(8文字以上)" autocomplete="new-password">
    <input type="password" id="authPasswordConfirm" placeholder="パスワード(確認用・もう一度入力)" autocomplete="new-password">
    <button class="primaryBtn" id="authSubmitBtn">無料で始める</button>
    <div class="switchText" id="switchTextWrap" style="display:none;">
      <button class="linkBtn" id="authSwitchBtn">新規登録する</button>
    </div>
  </div>
</div>
'@
$result = ReplaceOnce $content $find2 $replace2 "② HTML: タブへの差し替え"
if ($result) { $content = $result }

# ---- ③ JS: toggleAuthMode をタブのON/OFF切り替えに対応させる ----
$find3 = @'
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
$replace3 = @'
  function setAuthMode(signup){
    isSignupMode = signup;
    document.getElementById('authTitle').textContent = isSignupMode ? 'はじめまして' : 'おかえりなさい';
    document.getElementById('authDesc').textContent = isSignupMode
      ? 'メールアドレスと、お好きなパスワード(8文字以上)を決めるだけで始められます。メール認証は不要です。登録すると7日間無料でお試しいただけます。'
      : '登録済みのメールアドレスとパスワードでログインしてください。';
    els.authSubmitBtn.textContent = isSignupMode ? '無料で始める' : 'ログイン';
    els.authError.textContent = '';
    els.authPasswordConfirm.style.display = isSignupMode ? 'block' : 'none';
    els.authPasswordConfirm.value = '';
    document.getElementById('tabSignup').classList.toggle('activeTab', isSignupMode);
    document.getElementById('tabLogin').classList.toggle('activeTab', !isSignupMode);
  }
  function toggleAuthMode(){
    setAuthMode(!isSignupMode);
  }
'@
$result = ReplaceOnce $content $find3 $replace3 "③ JS: setAuthMode関数への変更"
if ($result) { $content = $result }

# ---- ④ JS: タブのクリックイベントを登録(</script>の直前に追加)----
$eventCode = @'

  document.getElementById('tabSignup').addEventListener('click', () => setAuthMode(true));
  document.getElementById('tabLogin').addEventListener('click', () => setAuthMode(false));
'@
$lastScriptIdx = $content.LastIndexOf('</script>')
if ($lastScriptIdx -lt 0) {
    Write-Host "エラー: </script> タグが見つかりませんでした" -ForegroundColor Red
} else {
    $content = $content.Substring(0, $lastScriptIdx) + $eventCode + "`n" + $content.Substring($lastScriptIdx)
    Write-Host "④ タブのクリックイベント登録 : OK" -ForegroundColor Green
}

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


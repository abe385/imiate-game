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

function ReplaceOnce($content, $find, $replaceWith, $label) {
    $idx = $content.IndexOf($find)
    if ($idx -lt 0) {
        Write-Host "エラー: 置換対象が見つかりませんでした ($label)" -ForegroundColor Red
        return $null
    }
    Write-Host "$label : OK" -ForegroundColor Green
    return $content.Substring(0, $idx) + $replaceWith + $content.Substring($idx + $find.Length)
}

# ---- ① 「パスワードを忘れた方はこちら」リンクを追加 ----
$find1 = @'
    <div class="switchText">
      すでにアカウントをお持ちですか?
      <button class="linkBtn" id="authSwitchBtn">ログインする</button>
    </div>
'@
$replace1 = @'
    <div class="switchText">
      すでにアカウントをお持ちですか?
      <button class="linkBtn" id="authSwitchBtn">ログインする</button>
    </div>
    <div style="text-align:center; margin-top:10px; display:none;" id="forgotPasswordWrap">
      <button class="linkBtn" id="forgotPasswordLink">パスワードを忘れた方はこちら</button>
    </div>
'@
$result = ReplaceOnce $content $find1 $replace1 "① パスワードを忘れたリンクの追加"
if ($result) { $content = $result }

# ---- ② パスワード再設定用の2つのモーダルを追加 ----
$find2 = '<div class="paywallOverlay" id="paywallOverlay">'
$replace2 = @'
<div class="modalOverlay" id="forgotOverlay">
  <div class="modalBox">
    <h2>🔑 パスワード再設定</h2>
    <p>登録済みのメールアドレスを入力してください。再設定用のリンクをメールでお送りします。</p>
    <div class="authError" id="forgotError"></div>
    <input type="email" id="forgotEmail" placeholder="メールアドレス" autocomplete="email">
    <button class="primaryBtn" id="forgotSubmitBtn">再設定メールを送る</button>
    <button class="linkBtn" id="forgotBackBtn">ログイン画面に戻る</button>
  </div>
</div>

<div class="modalOverlay" id="resetOverlay">
  <div class="modalBox">
    <h2>🔑 新しいパスワードを設定</h2>
    <p>新しいパスワード(8文字以上)を入力してください。</p>
    <div class="authError" id="resetError"></div>
    <input type="password" id="resetPassword" placeholder="新しいパスワード(8文字以上)" autocomplete="new-password">
    <input type="password" id="resetPasswordConfirm" placeholder="新しいパスワード(確認用)" autocomplete="new-password">
    <button class="primaryBtn" id="resetSubmitBtn">パスワードを更新する</button>
  </div>
</div>

<div class="paywallOverlay" id="paywallOverlay">
'@
$result = ReplaceOnce $content $find2 $replace2 "② パスワード再設定モーダルの追加"
if ($result) { $content = $result }

# ---- ③ els オブジェクトに新しい要素を追加 ----
$find3 = @'
    installIosCloseBtn: document.getElementById('installIosCloseBtn'),
  };
'@
$replace3 = @'
    installIosCloseBtn: document.getElementById('installIosCloseBtn'),
    forgotPasswordWrap: document.getElementById('forgotPasswordWrap'),
    forgotPasswordLink: document.getElementById('forgotPasswordLink'),
    forgotOverlay: document.getElementById('forgotOverlay'),
    forgotEmail: document.getElementById('forgotEmail'),
    forgotError: document.getElementById('forgotError'),
    forgotSubmitBtn: document.getElementById('forgotSubmitBtn'),
    forgotBackBtn: document.getElementById('forgotBackBtn'),
    resetOverlay: document.getElementById('resetOverlay'),
    resetPassword: document.getElementById('resetPassword'),
    resetPasswordConfirm: document.getElementById('resetPasswordConfirm'),
    resetError: document.getElementById('resetError'),
    resetSubmitBtn: document.getElementById('resetSubmitBtn'),
  };
'@
$result = ReplaceOnce $content $find3 $replace3 "③ els への追加"
if ($result) { $content = $result }

# ---- ④ toggleAuthMode() で、ログインモード時だけ「パスワードを忘れた方」リンクを表示 ----
$find4 = @'
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
$replace4 = @'
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
$result = ReplaceOnce $content $find4 $replace4 "④ toggleAuthMode の修正"
if ($result) { $content = $result }

# ---- ⑤ パスワード再設定用の関数を追加(startCheckout関数の直前に挿入)----
$find5 = @'
  function openUpgradeFlow(){
'@
$replace5 = @'
  let resetTokenValue = null;

  function openForgotPassword(){
    els.loginOverlay.style.display = 'none';
    els.forgotOverlay.style.display = 'flex';
    els.forgotError.textContent = '';
    els.forgotError.style.color = '';
    els.forgotEmail.value = els.authEmail.value || '';
  }

  function closeForgotPassword(){
    els.forgotOverlay.style.display = 'none';
    els.loginOverlay.style.display = 'flex';
  }

  async function handleForgotSubmit(){
    const email = els.forgotEmail.value.trim();
    els.forgotError.style.color = '';
    els.forgotError.textContent = '';
    if(!email){
      els.forgotError.textContent = 'メールアドレスを入力してください';
      return;
    }
    try{
      await apiFetch('/auth/request-reset', { method: 'POST', body: JSON.stringify({ email }) });
      els.forgotError.style.color = 'var(--good)';
      els.forgotError.textContent = '再設定用のメールを送信しました(登録されている場合)。メールをご確認ください。';
    } catch(e){
      els.forgotError.textContent = e.message;
    }
  }

  function checkResetTokenInUrl(){
    const params = new URLSearchParams(window.location.search);
    const token = params.get('reset_token');
    if(token){
      resetTokenValue = token;
      els.loginOverlay.style.display = 'none';
      els.resetOverlay.style.display = 'flex';
      return true;
    }
    return false;
  }

  async function handleResetSubmit(){
    const password = els.resetPassword.value;
    const confirmPw = els.resetPasswordConfirm.value;
    els.resetError.textContent = '';
    if(password.length < 8){
      els.resetError.textContent = 'パスワードは8文字以上にしてください';
      return;
    }
    if(password !== confirmPw){
      els.resetError.textContent = 'パスワードが一致しません';
      return;
    }
    try{
      await apiFetch('/auth/reset-password', { method: 'POST', body: JSON.stringify({ token: resetTokenValue, password }) });
      els.resetOverlay.style.display = 'none';
      history.replaceState(null, '', window.location.pathname);
      setAuthMode(false);
      showLoginModal();
      alert('パスワードを再設定しました。新しいパスワードでログインしてください。');
    } catch(e){
      els.resetError.textContent = e.message;
    }
  }

  function openUpgradeFlow(){
'@
$result = ReplaceOnce $content $find5 $replace5 "⑤ パスワード再設定関数の追加"
if ($result) { $content = $result }

# ---- ⑥ refreshAuthStatus() の自動呼び出しを、reset_token確認後に変更 ----
$find6 = 'refreshAuthStatus().then(checkBillingReturn);'
$replace6 = @'
if(!checkResetTokenInUrl()){
    refreshAuthStatus().then(checkBillingReturn);
  }
'@
$result = ReplaceOnce $content $find6 $replace6 "⑥ 初期化処理の修正"
if ($result) { $content = $result }

# ---- ⑦ イベント登録を追加(</script>の直前、未追加の場合のみ)----
$eventCode = @'

  els.forgotPasswordLink.addEventListener('click', openForgotPassword);
  els.forgotBackBtn.addEventListener('click', closeForgotPassword);
  els.forgotSubmitBtn.addEventListener('click', handleForgotSubmit);
  els.resetSubmitBtn.addEventListener('click', handleResetSubmit);
'@
if ($content.Contains("els.resetSubmitBtn.addEventListener")) {
    Write-Host "⑦ イベント登録: すでに追加済みのためスキップ" -ForegroundColor Yellow
} else {
    $lastScriptIdx = $content.LastIndexOf('</script>')
    if ($lastScriptIdx -lt 0) {
        Write-Host "エラー: </script> タグが見つかりませんでした" -ForegroundColor Red
    } else {
        $content = $content.Substring(0, $lastScriptIdx) + $eventCode + "`n" + $content.Substring($lastScriptIdx)
        Write-Host "⑦ イベント登録の追加 : OK" -ForegroundColor Green
    }
}

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


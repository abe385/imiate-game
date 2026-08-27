# ============================================================
# imiate.html にログイン・課金UIを自動挿入するスクリプト
# ============================================================

$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup"

if (-not (Test-Path $path)) {
    Write-Host "エラー: imiate.html が見つかりません: $path" -ForegroundColor Red
    exit 1
}

# 念のためバックアップを作成(失敗しても元に戻せるように)
Copy-Item $path $backup -Force
Write-Host "バックアップを作成しました: $backup"

$content = Get-Content -Raw -Encoding UTF8 $path

function InsertBefore($content, $anchor, $insertion) {
    $idx = $content.IndexOf($anchor)
    if ($idx -lt 0) { throw "挿入位置が見つかりませんでした(anchor): $anchor" }
    return $content.Substring(0, $idx) + $insertion + "`n" + $content.Substring($idx)
}

function InsertAfter($content, $anchor, $insertion) {
    $idx = $content.IndexOf($anchor)
    if ($idx -lt 0) { throw "挿入位置が見つかりませんでした(anchor): $anchor" }
    $insertPos = $idx + $anchor.Length
    return $content.Substring(0, $insertPos) + "`n" + $insertion + "`n" + $content.Substring($insertPos)
}

# ---- ブロック① CSS ----
$block1 = @'
  /* ==================== ログイン・課金UI ==================== */
  .accountBar{
    font-size:12px; color:#c9d2e8; margin-top:8px; display:flex;
    gap:8px; justify-content:center; flex-wrap:wrap;
  }
  .linkBtn{
    background:none; border:none; color:var(--gold); font-size:12px;
    text-decoration:underline; cursor:pointer; padding:0; font-family:inherit;
  }
  .modalOverlay{
    display:none; position:fixed; inset:0; background:rgba(0,0,0,0.6);
    z-index:1000; align-items:center; justify-content:center; padding:20px;
  }
  .modalBox{
    background:var(--paper); color:var(--ink); border-radius:16px;
    padding:28px 22px; max-width:320px; width:100%; text-align:center;
  }
  .modalBox h2{
    font-family:'Shippori Mincho', serif; font-size:20px; margin:0 0 6px;
  }
  .modalBox p{ font-size:13px; color:#5a5647; margin:0 0 18px; line-height:1.6; }
  .modalBox input{
    width:100%; padding:12px; border-radius:10px; border:1.5px solid var(--paper-dim);
    font-size:15px; margin-bottom:10px; background:#fff;
  }
  .modalBox .primaryBtn{
    width:100%; background:var(--accent); color:#fff; border:none; border-radius:10px;
    padding:13px; font-size:15px; font-weight:700; cursor:pointer; margin-bottom:10px;
  }
  .modalBox .primaryBtn:active{ background:var(--accent-dark); }
  .modalBox .switchText{ font-size:13px; color:#5a5647; }
  .modalBox .authError{ color:var(--danger); font-size:13px; min-height:18px; margin-bottom:8px; }
  .paywallOverlay{
    display:none; position:fixed; inset:0; background:rgba(26,29,46,0.92);
    z-index:900; align-items:center; justify-content:center; padding:20px;
  }
  .paywallBox{
    background:var(--paper); color:var(--ink); border-radius:16px;
    padding:28px 22px; max-width:320px; width:100%; text-align:center;
  }
  .paywallBox h2{ font-family:'Shippori Mincho', serif; font-size:20px; margin:0 0 10px; }
  .paywallBox p{ font-size:14px; color:#5a5647; margin:0 0 18px; line-height:1.7; }
  .paywallBox .priceTag{ font-size:24px; font-weight:900; color:var(--accent-dark); margin-bottom:18px; }
  .paywallBox .primaryBtn{
    width:100%; background:var(--gold); color:#2b2b22; border:none; border-radius:10px;
    padding:14px; font-size:16px; font-weight:900; cursor:pointer; margin-bottom:10px;
  }
'@

# ---- ブロック② HTML ----
$block2 = @'
<div class="accountBar" id="accountBar"></div>

<div class="modalOverlay" id="loginOverlay">
  <div class="modalBox">
    <h2 id="authTitle">はじめまして</h2>
    <p>メールアドレスを登録すると、7日間無料でお試しいただけます。</p>
    <div class="authError" id="authError"></div>
    <input type="email" id="authEmail" placeholder="メールアドレス" autocomplete="email">
    <input type="password" id="authPassword" placeholder="パスワード(8文字以上)" autocomplete="current-password">
    <button class="primaryBtn" id="authSubmitBtn">無料で始める</button>
    <div class="switchText">
      すでにアカウントをお持ちですか?
      <button class="linkBtn" id="authSwitchBtn">ログインする</button>
    </div>
  </div>
</div>

<div class="paywallOverlay" id="paywallOverlay">
  <div class="paywallBox">
    <h2>🔒 無料期間が終了しました</h2>
    <p>脳トレ(連想ゲーム)を引き続きお楽しみいただくには、サブスクリプションへのご登録が必要です。</p>
    <div class="priceTag">月額110円</div>
    <button class="primaryBtn" id="paywallUpgradeBtn">アップグレードする</button>
    <button class="linkBtn" id="paywallLogoutBtn">別のアカウントでログイン</button>
  </div>
</div>
'@

# ---- ブロック③ JavaScript ----
$block3 = @'
  // ==================== ログイン・課金機能 ====================
  const API_BASE = "https://noutore-account.hisashi-word-chain.workers.dev";
  let authToken = localStorage.getItem('noutoreToken');
  let authStatus = null;
  let isSignupMode = true;

  async function apiFetch(path, options = {}){
    const headers = Object.assign({}, options.headers || {});
    if(authToken) headers['Authorization'] = `Bearer ${authToken}`;
    if(options.body) headers['Content-Type'] = 'application/json';
    const res = await fetch(`${API_BASE}${path}`, Object.assign({}, options, { headers }));
    const data = await res.json().catch(() => ({}));
    if(!res.ok) throw new Error(data.error || 'エラーが発生しました');
    return data;
  }

  function daysLeft(unixSec){
    if(!unixSec) return 0;
    return Math.max(0, Math.ceil((unixSec - Math.floor(Date.now() / 1000)) / 86400));
  }

  function updateAccountBar(){
    if(!authStatus){ els.accountBar.innerHTML = ''; return; }
    let label = '';
    if(authStatus.status === 'trial'){
      label = `🎁 無料期間中(残り${daysLeft(authStatus.trialEndsAt)}日) ・ <button id="upgradeBtn" class="linkBtn">アップグレード</button>`;
    } else if(authStatus.status === 'active'){
      label = `✅ 有料会員 ・ <button id="portalBtn" class="linkBtn">契約管理</button>`;
    } else {
      label = `⏰ 無料期間が終了しました ・ <button id="upgradeBtn" class="linkBtn">アップグレード</button>`;
    }
    label += ` ・ <button id="logoutBtn" class="linkBtn">ログアウト</button>`;
    els.accountBar.innerHTML = label;
    const up = document.getElementById('upgradeBtn'); if(up) up.addEventListener('click', startCheckout);
    const pt = document.getElementById('portalBtn'); if(pt) pt.addEventListener('click', openPortal);
    const lo = document.getElementById('logoutBtn'); if(lo) lo.addEventListener('click', logout);
  }

  function showPaywall(show){
    els.paywallOverlay.style.display = show ? 'flex' : 'none';
  }

  function showLoginModal(){
    els.loginOverlay.style.display = 'flex';
  }
  function hideLoginModal(){
    els.loginOverlay.style.display = 'none';
  }

  async function refreshAuthStatus(){
    if(!authToken){ showLoginModal(); return; }
    try{
      const data = await apiFetch('/auth/me', { method: 'GET' });
      authStatus = data;
      updateAccountBar();
      hideLoginModal();
      showPaywall(data.status === 'expired');
    } catch(e){
      authToken = null;
      localStorage.removeItem('noutoreToken');
      showLoginModal();
    }
  }

  async function handleAuthSubmit(){
    const email = els.authEmail.value.trim();
    const password = els.authPassword.value;
    els.authError.textContent = '';
    try{
      const path = isSignupMode ? '/auth/signup' : '/auth/login';
      const data = await apiFetch(path, { method: 'POST', body: JSON.stringify({ email, password }) });
      authToken = data.token;
      localStorage.setItem('noutoreToken', authToken);
      await refreshAuthStatus();
    } catch(e){
      els.authError.textContent = e.message;
    }
  }

  function toggleAuthMode(){
    isSignupMode = !isSignupMode;
    document.getElementById('authTitle').textContent = isSignupMode ? 'はじめまして' : 'おかえりなさい';
    els.authSubmitBtn.textContent = isSignupMode ? '無料で始める' : 'ログイン';
    els.authSwitchBtn.textContent = isSignupMode ? 'ログインする' : '新規登録する';
    els.authError.textContent = '';
  }

  async function logout(){
    try{ await apiFetch('/auth/logout', { method: 'POST' }); } catch(e){ /* ignore */ }
    authToken = null;
    authStatus = null;
    localStorage.removeItem('noutoreToken');
    updateAccountBar();
    showPaywall(false);
    showLoginModal();
  }

  async function startCheckout(){
    try{
      const data = await apiFetch('/billing/create-checkout-session', { method: 'POST' });
      window.location.href = data.url;
    } catch(e){
      alert('決済ページの取得に失敗しました: ' + e.message);
    }
  }

  async function openPortal(){
    try{
      const data = await apiFetch('/billing/portal', { method: 'POST' });
      window.location.href = data.url;
    } catch(e){
      alert('契約管理ページの取得に失敗しました: ' + e.message);
    }
  }

  async function checkBillingReturn(){
    const params = new URLSearchParams(window.location.search);
    if(params.get('billing') === 'success'){
      for(let i = 0; i < 5; i++){
        await new Promise(r => setTimeout(r, 1500));
        await refreshAuthStatus();
        if(authStatus && authStatus.status === 'active') break;
      }
      history.replaceState(null, '', window.location.pathname);
    }
  }
'@

try {
    $content = InsertBefore $content '</style>' $block1
    $content = InsertAfter $content '<div class="sub">今日のお題の単語を、意味の近さのヒントを頼りに当てよう</div>' $block2
    $content = InsertBefore $content 'const els = {' $block3

    Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
    Write-Host "✅ 3か所の挿入が完了しました!" -ForegroundColor Green
} catch {
    Write-Host "❌ エラーが発生しました: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "ファイルは変更されていません。バックアップから復元は不要です。" -ForegroundColor Yellow
}


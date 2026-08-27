$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup7"

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

# ---- ① ペイウォールのHTML全体を、法対応リンク・年齢確認チェック付きに差し替え ----
$find1 = @'
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
$replace1 = @'
<div class="paywallOverlay" id="paywallOverlay">
  <div class="paywallBox">
    <h2 id="paywallTitle">🔒 無料期間が終了しました</h2>
    <p id="paywallText">脳トレ(連想ゲーム)を引き続きお楽しみいただくには、サブスクリプションへのご登録が必要です。</p>
    <div class="priceTag">月額110円</div>
    <div style="font-size:13px; margin-bottom:14px; line-height:1.9; color:#5a5647;">
      <a href="terms.html" target="_blank" style="color:var(--accent-dark);">利用規約</a>
      ・<a href="privacy.html" target="_blank" style="color:var(--accent-dark);">プライバシーポリシー</a>
      ・<a href="tokushoho.html" target="_blank" style="color:var(--accent-dark);">特定商取引法に基づく表記</a>
      をご確認ください。
    </div>
    <label style="display:flex; align-items:flex-start; gap:8px; font-size:14px; text-align:left; margin-bottom:16px; cursor:pointer;">
      <input type="checkbox" id="ageConfirmCheckbox" style="margin-top:3px; width:19px; height:19px; flex-shrink:0;">
      <span>私は18歳以上であり、上記の利用規約・プライバシーポリシー・特定商取引法に基づく表記の内容に同意します。</span>
    </label>
    <div class="authError" id="paywallError" style="min-height:18px; margin-bottom:6px;"></div>
    <button class="primaryBtn" id="paywallUpgradeBtn">アップグレードする</button>
    <button class="linkBtn" id="paywallCloseBtn" style="display:none; margin-bottom:8px;">あとで登録する</button>
    <button class="linkBtn" id="paywallLogoutBtn">別のアカウントでログイン</button>
  </div>
</div>
'@
$result = ReplaceOnce $content $find1 $replace1 "① ペイウォールHTMLの差し替え"
if ($result) { $content = $result }

# ---- ② els オブジェクトに新しい要素を追加 ----
$find2 = @'
    authSwitchBtn: document.getElementById('authSwitchBtn'),
  };
'@
$replace2 = @'
    authSwitchBtn: document.getElementById('authSwitchBtn'),
    ageConfirmCheckbox: document.getElementById('ageConfirmCheckbox'),
    paywallError: document.getElementById('paywallError'),
    paywallCloseBtn: document.getElementById('paywallCloseBtn'),
  };
'@
$result = ReplaceOnce $content $find2 $replace2 "② els への追加"
if ($result) { $content = $result }

# ---- ③ updateAccountBar() の「アップグレード」ボタンを、確認画面経由に変更 ----
$find3 = @'
    const up = document.getElementById('upgradeBtn'); if(up) up.addEventListener('click', startCheckout);
'@
$replace3 = @'
    const up = document.getElementById('upgradeBtn'); if(up) up.addEventListener('click', openUpgradeFlow);
'@
$result = ReplaceOnce $content $find3 $replace3 "③ アカウントバーのボタン修正"
if ($result) { $content = $result }

# ---- ④ openUpgradeFlow / confirmUpgrade 関数を追加(startCheckout関数の直前に挿入)----
$find4 = @'
  async function startCheckout(){
'@
$replace4 = @'
  function openUpgradeFlow(){
    const expired = authStatus && authStatus.status === 'expired';
    document.getElementById('paywallTitle').textContent = expired ? '🔒 無料期間が終了しました' : '💳 アップグレード';
    document.getElementById('paywallText').textContent = expired
      ? '脳トレ(連想ゲーム)を引き続きお楽しみいただくには、サブスクリプションへのご登録が必要です。'
      : '無料期間中でも、今すぐアップグレードいただけます。';
    els.ageConfirmCheckbox.checked = false;
    els.paywallError.textContent = '';
    els.paywallCloseBtn.style.display = expired ? 'none' : 'inline-block';
    showPaywall(true);
  }

  function confirmUpgrade(){
    if(!els.ageConfirmCheckbox.checked){
      els.paywallError.textContent = '同意いただける場合のみお進みいただけます。';
      return;
    }
    els.paywallError.textContent = '';
    startCheckout();
  }

  async function startCheckout(){
'@
$result = ReplaceOnce $content $find4 $replace4 "④ 新しい関数の追加"
if ($result) { $content = $result }

# ---- ⑤ paywallUpgradeBtn のイベント登録先を confirmUpgrade に変更 ----
$find5 = @'
  document.getElementById('paywallUpgradeBtn').addEventListener('click', startCheckout);
  document.getElementById('paywallLogoutBtn').addEventListener('click', logout);
'@
$replace5 = @'
  document.getElementById('paywallUpgradeBtn').addEventListener('click', confirmUpgrade);
  document.getElementById('paywallLogoutBtn').addEventListener('click', logout);
  els.paywallCloseBtn.addEventListener('click', () => showPaywall(false));
'@
$result = ReplaceOnce $content $find5 $replace5 "⑤ イベント登録の修正"
if ($result) { $content = $result }

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


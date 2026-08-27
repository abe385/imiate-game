$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup10"

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

# ---- ① accountBar のレイアウトを縦並び中央寄せに変更 ----
$find1 = @'
  .accountBar{
    font-size:16px; color:#eef1fb; margin-top:12px; display:flex;
    gap:10px; justify-content:center; flex-wrap:wrap; align-items:center;
    padding:8px 12px; background:rgba(255,255,255,0.08); border-radius:10px;
  }
'@
$replace1 = @'
  .accountBar{
    font-size:16px; color:#eef1fb; margin-top:12px; display:flex;
    flex-direction:column; gap:10px; justify-content:center; align-items:center;
    padding:14px 12px; background:rgba(255,255,255,0.08); border-radius:12px;
  }
  .upgradeBigBtn{
    background:var(--gold); color:#2b2b22; font-weight:900; font-size:18px;
    border:none; border-radius:14px; padding:14px 32px; cursor:pointer;
    box-shadow:0 4px 14px rgba(224,184,74,0.4);
  }
  .upgradeBigBtn:active{ transform:scale(0.97); }
  .smallLogout{
    font-size:13px; color:#aab2cc; font-weight:500; background:none; border:none;
    text-decoration:underline; cursor:pointer; font-family:inherit;
  }
'@
$result = ReplaceOnce $content $find1 $replace1 "① accountBarレイアウトの変更"
if ($result) { $content = $result }

# ---- ② updateAccountBar() 関数を新しいレイアウトに書き換え ----
$find2 = @'
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
    const up = document.getElementById('upgradeBtn'); if(up) up.addEventListener('click', openUpgradeFlow);
    const pt = document.getElementById('portalBtn'); if(pt) pt.addEventListener('click', openPortal);
    const lo = document.getElementById('logoutBtn'); if(lo) lo.addEventListener('click', logout);
  }
'@
$replace2 = @'
  function updateAccountBar(){
    if(!authStatus){ els.accountBar.innerHTML = ''; return; }
    let html = '';
    if(authStatus.status === 'trial'){
      html = `<div>🎁 無料期間中(残り${daysLeft(authStatus.trialEndsAt)}日)</div>
        <button id="upgradeBtn" class="upgradeBigBtn">🚀 アップグレードする</button>`;
    } else if(authStatus.status === 'active'){
      html = `<div>✅ 有料会員</div>
        <button id="portalBtn" class="upgradeBigBtn">契約管理</button>`;
    } else {
      html = `<div>⏰ 無料期間が終了しました</div>
        <button id="upgradeBtn" class="upgradeBigBtn">🚀 アップグレードする</button>`;
    }
    html += `<button id="logoutBtn" class="smallLogout">ログアウト</button>`;
    els.accountBar.innerHTML = html;
    const up = document.getElementById('upgradeBtn'); if(up) up.addEventListener('click', openUpgradeFlow);
    const pt = document.getElementById('portalBtn'); if(pt) pt.addEventListener('click', openPortal);
    const lo = document.getElementById('logoutBtn'); if(lo) lo.addEventListener('click', logout);
  }
'@
$result = ReplaceOnce $content $find2 $replace2 "② updateAccountBar関数の書き換え"
if ($result) { $content = $result }

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


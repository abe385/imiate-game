$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup5"

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

# ---- ① HTML: パスワード確認欄を追加 ----
$find1 = @'
    <input type="password" id="authPassword" placeholder="パスワード(8文字以上)" autocomplete="current-password">
    <button class="primaryBtn" id="authSubmitBtn">無料で始める</button>
'@
$replace1 = @'
    <input type="password" id="authPassword" placeholder="パスワード(8文字以上)" autocomplete="new-password">
    <input type="password" id="authPasswordConfirm" placeholder="パスワード(確認用・もう一度入力)" autocomplete="new-password">
    <button class="primaryBtn" id="authSubmitBtn">無料で始める</button>
'@
$result = ReplaceOnce $content $find1 $replace1 "① パスワード確認欄の追加"
if ($result) { $content = $result }

# ---- ② JS: els オブジェクトに authPasswordConfirm を追加 ----
$find2 = @'
    authPassword: document.getElementById('authPassword'),
'@
$replace2 = @'
    authPassword: document.getElementById('authPassword'),
    authPasswordConfirm: document.getElementById('authPasswordConfirm'),
'@
$result = ReplaceOnce $content $find2 $replace2 "② els への追加"
if ($result) { $content = $result }

# ---- ③ JS: toggleAuthMode() でログインモード時は確認欄を隠す ----
$find3 = @'
  function toggleAuthMode(){
    isSignupMode = !isSignupMode;
    document.getElementById('authTitle').textContent = isSignupMode ? 'はじめまして' : 'おかえりなさい';
    els.authSubmitBtn.textContent = isSignupMode ? '無料で始める' : 'ログイン';
    els.authSwitchBtn.textContent = isSignupMode ? 'ログインする' : '新規登録する';
    els.authError.textContent = '';
  }
'@
$replace3 = @'
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
$result = ReplaceOnce $content $find3 $replace3 "③ toggleAuthMode の修正"
if ($result) { $content = $result }

# ---- ④ JS: handleAuthSubmit() で確認欄との一致チェックを追加 ----
$find4 = @'
  async function handleAuthSubmit(){
    const email = els.authEmail.value.trim();
    const password = els.authPassword.value;
    els.authError.textContent = '';
    try{
'@
$replace4 = @'
  async function handleAuthSubmit(){
    const email = els.authEmail.value.trim();
    const password = els.authPassword.value;
    els.authError.textContent = '';
    if(isSignupMode){
      if(password.length < 8){
        els.authError.textContent = 'パスワードは8文字以上にしてください';
        return;
      }
      if(password !== els.authPasswordConfirm.value){
        els.authError.textContent = 'パスワードが一致しません。もう一度ご確認ください。';
        return;
      }
    }
    try{
'@
$result = ReplaceOnce $content $find4 $replace4 "④ 一致チェックの追加"
if ($result) { $content = $result }

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


$path = "C:\word-chain-worker\imiate-game\imiate.html"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup_$timestamp"

Copy-Item $path $backup -Force
Write-Host "バックアップを作成しました: $backup"

$content = Get-Content -Raw -Encoding UTF8 $path

$find = @'
    <div class="switchText">
      すでにアカウントをお持ちですか?
      <button class="linkBtn" id="authSwitchBtn">ログインする</button>
    </div>
'@
$replace = @'
    <div class="switchText">
      すでにアカウントをお持ちですか?
      <button class="linkBtn" id="authSwitchBtn">ログインする</button>
    </div>
    <div style="text-align:center; margin-top:10px; display:none;" id="forgotPasswordWrap">
      <button class="linkBtn" id="forgotPasswordLink">パスワードを忘れた方はこちら</button>
    </div>
'@

$idx = $content.IndexOf($find)
if ($idx -lt 0) {
    Write-Host "エラー: 挿入位置が見つかりませんでした" -ForegroundColor Red
    exit 1
}
$content = $content.Substring(0, $idx) + $replace + $content.Substring($idx + $find.Length)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host "追加しました" -ForegroundColor Green


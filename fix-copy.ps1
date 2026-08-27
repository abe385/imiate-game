$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup3"

if (-not (Test-Path $path)) {
    Write-Host "エラー: imiate.html が見つかりません: $path" -ForegroundColor Red
    exit 1
}

Copy-Item $path $backup -Force
Write-Host "バックアップを作成しました: $backup"

$content = Get-Content -Raw -Encoding UTF8 $path

$find = '<p>メールアドレスを登録すると、7日間無料でお試しいただけます。</p>'
$replace = '<p>メールアドレスと、お好きなパスワード(8文字以上)を決めるだけで始められます。メール認証は不要です。<br>登録すると7日間無料でお試しいただけます。</p>'

$idx = $content.IndexOf($find)
if ($idx -lt 0) {
    Write-Host "❌ 置換対象が見つかりませんでした" -ForegroundColor Red
    exit 1
}
$content = $content.Substring(0, $idx) + $replace + $content.Substring($idx + $find.Length)

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host "✅ 説明文を更新しました!" -ForegroundColor Green


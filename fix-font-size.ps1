$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup4"

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

# ---- モーダルタイトルを大きく ----
$find1 = @'
  .modalBox h2{
    font-family:'Shippori Mincho', serif; font-size:20px; margin:0 0 6px;
  }
'@
$replace1 = @'
  .modalBox h2{
    font-family:'Shippori Mincho', serif; font-size:28px; margin:0 0 10px;
  }
'@
$result = ReplaceOnce $content $find1 $replace1 "① モーダルタイトル"
if ($result) { $content = $result }

# ---- 説明文を大きく ----
$find2 = @'
  .modalBox p{ font-size:13px; color:#5a5647; margin:0 0 18px; line-height:1.6; }
'@
$replace2 = @'
  .modalBox p{ font-size:17px; color:#3a3628; margin:0 0 20px; line-height:1.8; font-weight:500; }
'@
$result = ReplaceOnce $content $find2 $replace2 "② 説明文"
if ($result) { $content = $result }

# ---- 入力欄を大きく ----
$find3 = @'
  .modalBox input{
    width:100%; padding:12px; border-radius:10px; border:1.5px solid var(--paper-dim);
    font-size:15px; margin-bottom:10px; background:#fff;
  }
'@
$replace3 = @'
  .modalBox input{
    width:100%; padding:16px; border-radius:12px; border:2px solid var(--paper-dim);
    font-size:19px; margin-bottom:14px; background:#fff;
  }
  .modalBox input::placeholder{ font-size:16px; }
'@
$result = ReplaceOnce $content $find3 $replace3 "③ 入力欄"
if ($result) { $content = $result }

# ---- ボタンを大きく ----
$find4 = @'
  .modalBox .primaryBtn{
    width:100%; background:var(--accent); color:#fff; border:none; border-radius:10px;
    padding:13px; font-size:15px; font-weight:700; cursor:pointer; margin-bottom:10px;
  }
'@
$replace4 = @'
  .modalBox .primaryBtn{
    width:100%; background:var(--accent); color:#fff; border:none; border-radius:12px;
    padding:18px; font-size:19px; font-weight:900; cursor:pointer; margin-bottom:14px;
  }
'@
$result = ReplaceOnce $content $find4 $replace4 "④ 開始ボタン"
if ($result) { $content = $result }

# ---- 切り替えテキストを大きく ----
$find5 = @'
  .modalBox .switchText{ font-size:13px; color:#5a5647; }
  .modalBox .authError{ color:var(--danger); font-size:13px; min-height:18px; margin-bottom:8px; }
'@
$replace5 = @'
  .modalBox .switchText{ font-size:15px; color:#3a3628; line-height:1.8; }
  .modalBox .authError{ color:var(--danger); font-size:15px; font-weight:700; min-height:20px; margin-bottom:10px; }
'@
$result = ReplaceOnce $content $find5 $replace5 "⑤ 切り替え文言・エラー文"
if ($result) { $content = $result }

# ---- linkBtn(ログインする/新規登録するボタン)も大きく ----
$find6 = @'
  .linkBtn{
    background:none; border:none; color:var(--gold); font-size:12px;
    text-decoration:underline; cursor:pointer; padding:0; font-family:inherit;
  }
'@
$replace6 = @'
  .linkBtn{
    background:none; border:none; color:#c99a1f; font-size:15px; font-weight:700;
    text-decoration:underline; cursor:pointer; padding:0; font-family:inherit;
  }
'@
$result = ReplaceOnce $content $find6 $replace6 "⑥ リンクボタン"
if ($result) { $content = $result }

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で ❌ が無ければ全て成功です。" -ForegroundColor Cyan


$path = "C:\word-chain-worker\imiate-game\imiate.html"
$backup = "C:\word-chain-worker\imiate-game\imiate.html.backup9"

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

# ---- ① head部分にmanifestとアイコン設定を追加 ----
$find1 = '<title>脳トレ(連想ゲーム)</title>'
$replace1 = @'
<title>脳トレ(連想ゲーム)</title>
<link rel="manifest" href="manifest.json">
<link rel="apple-touch-icon" href="icon-192.png">
<meta name="theme-color" content="#1a1d2e">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
'@
$result = ReplaceOnce $content $find1 $replace1 "① head へのmanifest追加"
if ($result) { $content = $result }

# ---- ② accountBarの下に「ホーム画面に追加」ボタンを設置 ----
$find2 = '<div class="accountBar" id="accountBar"></div>'
$replace2 = @'
<div class="accountBar" id="accountBar"></div>
<div style="text-align:center; margin-top:8px;">
  <button id="installBtn" class="linkBtn" style="display:none; color:#ffe08a; font-size:15px; font-weight:800;">📲 ホーム画面に追加してアプリのように使う</button>
</div>

<div class="modalOverlay" id="installIosOverlay">
  <div class="modalBox">
    <h2>📲 ホーム画面に追加</h2>
    <p style="text-align:left; line-height:2;">
      1. 画面下(または上)の <b>共有ボタン</b>(四角から矢印が出ているアイコン)をタップ<br>
      2. メニューの中から <b>「ホーム画面に追加」</b> を選択<br>
      3. 右上の <b>「追加」</b> をタップすれば完了です
    </p>
    <button class="primaryBtn" id="installIosCloseBtn">閉じる</button>
  </div>
</div>
'@
$result = ReplaceOnce $content $find2 $replace2 "② ホーム画面追加ボタンの設置"
if ($result) { $content = $result }

# ---- ③ els オブジェクトに新しい要素を追加 ----
$find3 = @'
    paywallCloseBtn: document.getElementById('paywallCloseBtn'),
  };
'@
$replace3 = @'
    paywallCloseBtn: document.getElementById('paywallCloseBtn'),
    installBtn: document.getElementById('installBtn'),
    installIosOverlay: document.getElementById('installIosOverlay'),
    installIosCloseBtn: document.getElementById('installIosCloseBtn'),
  };
'@
$result = ReplaceOnce $content $find3 $replace3 "③ els への追加"
if ($result) { $content = $result }

# ---- ④ PWAインストール機能のJSを追加(</script>の直前に挿入)----
$eventCode = @'

  // ==================== PWA「ホーム画面に追加」機能 ====================
  let deferredInstallPrompt = null;
  const isIos = /iphone|ipad|ipod/i.test(navigator.userAgent);

  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredInstallPrompt = e;
    els.installBtn.style.display = 'inline-block';
  });

  if (isIos) {
    // iOSはbeforeinstallpromptに対応していないため、常にボタンを表示し
    // タップ時に手順の説明を表示する。
    els.installBtn.style.display = 'inline-block';
  }

  els.installBtn.addEventListener('click', async () => {
    if (isIos) {
      els.installIosOverlay.style.display = 'flex';
      return;
    }
    if (deferredInstallPrompt) {
      deferredInstallPrompt.prompt();
      await deferredInstallPrompt.userChoice;
      deferredInstallPrompt = null;
      els.installBtn.style.display = 'none';
    }
  });

  els.installIosCloseBtn.addEventListener('click', () => {
    els.installIosOverlay.style.display = 'none';
  });

  window.addEventListener('appinstalled', () => {
    els.installBtn.style.display = 'none';
  });

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('service-worker.js').catch(() => {
      // 登録に失敗してもゲーム自体には影響しない
    });
  }
'@
$lastScriptIdx = $content.LastIndexOf('</script>')
if ($lastScriptIdx -lt 0) {
    Write-Host "エラー: </script> タグが見つかりませんでした" -ForegroundColor Red
} else {
    $content = $content.Substring(0, $lastScriptIdx) + $eventCode + "`n" + $content.Substring($lastScriptIdx)
    Write-Host "④ PWAインストール機能の追加 : OK" -ForegroundColor Green
}

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "処理が完了しました。上記で エラー が無ければ全て成功です。" -ForegroundColor Cyan


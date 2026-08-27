# -*- coding: utf-8 -*-
"""
difficulty_map.json を imiate.html に組み込み、
「1問目=やさしい単語から出題」「2問目=全体から出題(今まで通り)」
に変更するスクリプト。

使い方:
    python apply_difficulty.py <対象フォルダ>

例:
    python apply_difficulty.py C:\\word-chain-worker\\imiate-game-test
    python apply_difficulty.py C:\\word-chain-worker\\imiate-game
"""
import sys
import json
import shutil
import datetime
import os

if len(sys.argv) < 2:
    print("エラー: 対象フォルダを指定してください")
    print(r'例: python apply_difficulty.py C:\word-chain-worker\imiate-game-test')
    sys.exit(1)

TARGET_DIR = sys.argv[1]
HTML_PATH = os.path.join(TARGET_DIR, "imiate.html")
DIFFICULTY_PATH = os.path.join(TARGET_DIR, "difficulty_map.json")

if not os.path.exists(HTML_PATH):
    print(f"エラー: {HTML_PATH} が見つかりません")
    sys.exit(1)
if not os.path.exists(DIFFICULTY_PATH):
    print(f"エラー: {DIFFICULTY_PATH} が見つかりません")
    sys.exit(1)

# 二重適用防止
with open(HTML_PATH, "r", encoding="utf-8") as f:
    content = f.read()

if "EASY_WORD_SET" in content:
    print("すでに難易度分けが追加済みのようです。二重適用防止のため中止します。")
    sys.exit(0)

# バックアップ
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup_path = os.path.join(TARGET_DIR, f"imiate.html.backup_{timestamp}")
shutil.copy(HTML_PATH, backup_path)
print(f"バックアップを作成しました: {backup_path}")

# 難易度データを読み込み
with open(DIFFICULTY_PATH, "r", encoding="utf-8") as f:
    difficulty_map = json.load(f)

easy_words = sorted([w for w, d in difficulty_map.items() if d == "easy"])
print(f"やさしい単語: {len(easy_words)} 語")

easy_words_js_array = json.dumps(easy_words, ensure_ascii=False)

# ---- ① EASY_WORD_SET と ANSWER_ORDER_1 の定義を差し替え ----
find1 = "const ANSWER_ORDER_1 = seededShuffle(ANSWER_POOL, 20260822);"
if find1 not in content:
    print("エラー: 置換対象(ANSWER_ORDER_1の定義)が見つかりませんでした")
    sys.exit(1)

replace1 = f"""const EASY_WORD_SET = new Set({easy_words_js_array});
  const ANSWER_POOL_EASY = ANSWER_POOL.filter(w => EASY_WORD_SET.has(w));
  const ANSWER_ORDER_1 = seededShuffle(
    ANSWER_POOL_EASY.length > 0 ? ANSWER_POOL_EASY : ANSWER_POOL,
    20260822
  );"""

content = content.replace(find1, replace1)
print("① ANSWER_ORDER_1 をやさしい単語ベースに変更: OK")

with open(HTML_PATH, "w", encoding="utf-8") as f:
    f.write(content)

print("")
print("処理が完了しました。")

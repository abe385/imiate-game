"""
imiate.html に埋め込まれている WORD_VECTORS から、単語名(キー)だけを抜き出すスクリプト。
ベクトルの数値データは扱わない(重いので不要)。

使い方:
    python extract_words.py

出力:
    word_list.json (既存の単語一覧、JSON配列)
"""
import re
import json

INPUT_PATH = r"C:\word-chain-worker\imiate-game\imiate.html"
OUTPUT_PATH = r"C:\word-chain-worker\imiate-game\word_list.json"

print("imiate.html を読み込んでいます...(サイズが大きいので少し時間がかかります)")
with open(INPUT_PATH, "r", encoding="utf-8") as f:
    content = f.read()

# WORD_VECTORS = { ... }; の { ... } 部分を取り出す
match = re.search(r'const WORD_VECTORS\s*=\s*(\{)', content)
if not match:
    raise SystemExit("エラー: WORD_VECTORS が見つかりませんでした")

start = match.start(1)
# 対応する閉じ括弧を、深さを数えて探す(文字列中の { } は無視してよい設計のはずだが、
# 念のため簡易的な括弧カウントで対応する)
depth = 0
end = None
in_string = False
escape = False
for i in range(start, len(content)):
    ch = content[i]
    if in_string:
        if escape:
            escape = False
        elif ch == '\\':
            escape = True
        elif ch == '"':
            in_string = False
        continue
    else:
        if ch == '"':
            in_string = True
        elif ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                end = i + 1
                break

if end is None:
    raise SystemExit("エラー: WORD_VECTORS の終端が見つかりませんでした")

json_text = content[start:end]
print(f"WORD_VECTORS のJSON部分を抽出しました({len(json_text):,}文字)。パース中...")

data = json.loads(json_text)
words = list(data.keys())

print(f"単語数: {len(words)}")

with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
    json.dump(words, f, ensure_ascii=False, indent=2)

print(f"完了しました。{OUTPUT_PATH} に保存しました。")

"""
word_list.json の各単語に、JLPT語彙データ(N5=易しい 〜 N1=難しい)を突き合わせて
難易度ラベルを付け、imiate.html に組み込むための difficulty マップを生成する。

- ベクトルデータ(意味の近さ計算)には一切触らない。
- 「1問目=やさしい(N5/N4相当)」「2問目=それ以外」の判定に使う。
- JLPT語彙データに載っていない単語(固有名詞・カタカナ語など)は
  「不明(unknown)」として扱い、安全側(=やさしい扱いにしない)に倒す。

使い方:
    pip install requests --break-system-packages   (未インストールの場合)
    python build_difficulty.py

出力:
    difficulty_map.json  (単語 -> "easy" | "normal" のマップ)
"""
import json
import csv
import io
import urllib.request

WORD_LIST_PATH = r"C:\word-chain-worker\imiate-game\word_list.json"
OUTPUT_PATH = r"C:\word-chain-worker\imiate-game\difficulty_map.json"

JLPT_LEVELS = ["n5", "n4", "n3", "n2", "n1"]
BASE_URL = "https://raw.githubusercontent.com/elzup/jlpt-word-list/master/src/{}.csv"

def fetch_level_words(level):
    url = BASE_URL.format(level)
    print(f"取得中: {url}")
    with urllib.request.urlopen(url) as res:
        text = res.read().decode("utf-8")
    words = set()
    reader = csv.DictReader(io.StringIO(text))
    for row in reader:
        expr = row.get("expression", "")
        for w in expr.split(";"):
            w = w.strip()
            if w:
                words.add(w)
    return words

def main():
    print("既存の単語リストを読み込んでいます...")
    with open(WORD_LIST_PATH, "r", encoding="utf-8") as f:
        words = json.load(f)
    print(f"単語数: {len(words)}")

    level_words = {}
    for lv in JLPT_LEVELS:
        level_words[lv] = fetch_level_words(lv)

    # やさしい判定: N5・N4・N3 に載っている単語
    easy_set = level_words["n5"] | level_words["n4"] | level_words["n3"]

    difficulty_map = {}
    easy_count = 0
    normal_count = 0
    for w in words:
        if w in easy_set:
            difficulty_map[w] = "easy"
            easy_count += 1
        else:
            difficulty_map[w] = "normal"
            normal_count += 1

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(difficulty_map, f, ensure_ascii=False, indent=2)

    print("")
    print(f"やさしい(easy)判定: {easy_count} 語")
    print(f"それ以外(normal)判定: {normal_count} 語")
    print(f"完了しました。{OUTPUT_PATH} に保存しました。")

if __name__ == "__main__":
    main()

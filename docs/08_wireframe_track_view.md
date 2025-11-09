---
VIEW: Track View (トラック・ビュー)
PLATFORM: スマートフォン (横画面専用) - `917x412 dp` (基準)
LAYOUT: 3列 L字型レイアウト
DESCRIPTION: メインの詳細編集画面。「親指」での操作（L字型）と、「1画面1目的」（トラック・タブ）、「センサーの不正確さの補正」を前提とする。

---

### COLUMN_1 (左親指エリア)
* **WIDTH:** 画面全体の `15%`
* **ALIGNMENT:** 上から下に配置
* **CONTENT:**
    1.  `[ Button: ← 戻る ]` (アイコン: `Arrow-Left`)
        * **ACTION:** 「アレンジ・ビュー」（`docs/01`）に戻る。
    2.  `[ Button: 選択 ]` (アイコン: `Cursor`)
        * **ACTION:** ピアノロール/グリッドの「選択モード」に切り替え。
    3.  `[ Button: 書き込み ]` (アイコン: `Pencil`)
        * **ACTION:** 「書き込みモード」に切り替え。
    4.  `[ Button: スナップ設定 ]` (アイコン: `Grid`)
        * **ACTION:** タップすると「スナップ設定」(`[小節]`, `[拍]`, `[グリッド]`, `[フリー]`)のポップアップが開く。
    5.  `[ Button: オクターブ ↑ ]` (アイコン: `Chevron-Up`)
        * **ACTION:** ピアノロールの表示オクターブを1つ上げる。
    6.  `[ Button: オクターブ ↓ ]` (アイコン: `Chevron-Down`)
        * **ACTION:** ピアノロールの表示オクターブを1つ下げる。
    7.  `[ Button: MUTATE (介入) ]` (アイコン: `Atom` / `Wand`)
        * **SIZE:** **Large** (この列で最も大きいボタン)
        * **ACTION:** `docs/02` の「MUTATE（介入）」ワークフローを開始する。
    8.  `[ Button: 鼻歌 (Hum) ]` (アイコン: `Mic`)
        * **ACTION:** `docs/07` の「鼻歌解析」を開始する。

---

### COLUMN_2 (中央メインエリア)
* **WIDTH:** 画面全体の `70%`
* **ALIGNMENT:** 上から下に配置
* **CONTENT:**
    1.  `[ Area: 上部バー ]` (※修正版)
        * **HEIGHT:** 画面高さの `10%`
        * **LAYOUT:** 2列 (Row)
        * **CONTENT_LEFT (Width 40%):**
            * `[ Tab Bar: [Dr] [Ba] [Ch] [Me] ]` (トラック切替タブ)
        * **CONTENT_RIGHT (Width 60%):**
            * `[ Text: コード/情報 ]` (例: `4:01 | Cmaj7 > G7 > F > G`)
            * **NOTE:** このテキストは、再生ヘッドに追従して**動的に変化**する。
    2.  `[ Area: メイン編集エリア ]` (※修正版)
        * **HEIGHT:** 画面高さの `90%` (残りすべてを占有)
        * **CONTENT:** ピアノロール / ドラム・グリッド
        * **NOTE:** ピアノロールは「ドラッグで音長変更」と「タップでコンテキストメニュー（`[長くする]`ボタン）」の**両方**をサポートする。

---

### COLUMN_3 (右親指エリア)
* **WIDTH:** 画面全体の `15%`
* **ALIGNMENT:** 上から下に配置
* **CONTENT:**
    1.  `[ Button: ガイド・モード ]` (アイコン: `Eye` / `Filter`)
        * **ACTION:** ピアノロールの「鍵盤の非表示」をON/OFFする。
    2.  `[ Button: 保存 ]` (アイコン: `Save`)
        * **ACTION:** `README.md` の「セッション保存機能」を実行。
    3.  `[ Button: メトロノーム ]` (アイコン: `Metronome`)
        * **ACTION:** クリック音のON/OFF。
    4.  `[ Button: Redo ]` (アイコン: `Arrow-Clockwise`)
        * **ACTION:** やり直し。
    5.  `[ Button: Undo (元に戻す) ]` (アイコン: `Arrow-CounterClockwise`)
        * **SIZE:** **Large**
    6.  `[ Button: 再生 / 停止 ]` (アイコン: `Play` / `Stop`)
        * **SIZE:** **Extra Large** (この列で最も大きく、押しやすい位置)
        * **ACTION:** 曲の再生/停止。
---

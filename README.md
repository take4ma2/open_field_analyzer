# Open Field Analyzer

## はじめに
　本ツールはオープンフィールドテストで録画したムービーデータを解析するTime OF9 for Open Field test(小原医科産業株式会社製)の出力データの一つである
XYデータファイルをもとに必要なパラメータの解析を行うことを目的として開発したruby製プログラムです。
　該当データをお持ちでない場合は本プログラムは利用できません。

## インストール方法

### 動作対象

ruby interpreter(version 2.2以降)をインストールした Windows 10, MacOSX, Linux

### インストール方法

```
$ git clone https://githaub.com/take4ma2/open_field_analyzer.git
```

### 使用方法

#### Windows 10

`open_field_analyzer.bat`にXYデータファイルを含むディレクトリをドラッグ&ドロップ

#### Other OS

カレントディレクトリをインストールしたディレクトリに移動して、以下のコマンドを実行

```
$ ruby open_field_analyzer.rb /your/xydata/directory
```

### 結果

* ディレクトリ名_of.csv: 解析結果の要約

* subjects/[subject_no].csv: 1frameごとの結果ファイル

### 評価期間や各種設定の変更方法

このディレクトリにあるconstants.rbをテキストエディタで開いて編集してください。

```constants.rb
# define Constants
module Constants
  ARENA_X = 40.0         # Open Field Arena X size[cm]: default 40.0
  ARENA_Y = 40.0         # Open Field Arena Y size[cm]: default 40.0
  ROI_X = 120.0          # ROI X size[pixcels]: default 120.0
  ROI_Y = 120.0          # ROI Y size[pixcels]: default 120.0
  CENTER_AREA = 40.0     # Center region definition[%] (% of Rectangle area compare with arena whole area).: default 40.0
  BLOCK_ROWS = 5         # Arena division number for vertical axis.: default 5
  BLOCK_COLUMNS = 5      # Arena division number for horizontal axis.: default 5
  DURATION = 1200        # Duration of experiment[sec.]: default 1200
  FRAME_RATE = 2         # Frame rate[fps]: default 2
  MOTION_CRITERIA = 4.0  # If subject moves more than MOTION_CRITERIA, status is 'moved', else 'rested'.[cm/s]: default 4.0
end
```

`Module Constants` に解析で利用している定数が定義されています。
変更したい値を直接変更して下さい。
これらの値に負の値や数値以外の値が設定されることまではチェックしていないので、その際の正しい動作は保証できません。ご自身の責任でご利用ください。

#### ex) フレームレート(FRAME_RATE)を4, 評価期間(DURATION)を10分(600 sec.)に変更する場合の設定

```constants.rb
# define Constants
module Constants
  ARENA_X = 40.0         # Open Field Arena X size[cm]: default 40.0
  ARENA_Y = 40.0         # Open Field Arena Y size[cm]: default 40.0
  ROI_X = 120.0          # ROI X size[pixcels]: default 120.0
  ROI_Y = 120.0          # ROI Y size[pixcels]: default 120.0
  CENTER_AREA = 40.0     # Center region definition[%] (% of Rectangle area compare with arena whole area).: default 40.0
  BLOCK_ROWS = 5         # Arena division number for vertical axis.: default 5
  BLOCK_COLUMNS = 5      # Arena division number for horizontal axis.: default 5
  DURATION = 600         # Duration of experiment[sec.]: default 1200
  FRAME_RATE = 4         # Frame rate[fps]: default 2
  MOTION_CRITERIA = 4.0  # If subject moves more than MOTION_CRITERIA, status is 'moved', else 'rested'.[cm/s]: default 4.0
end
```

#### (参考) rubyファイルの書式について

`# ` はrubyの__コメント行__です。`# `以降の記述はすべてコメントとして扱われ、プログラムの動きには影響しません。
設定値のデフォルトが各定数のコメントに記述されていますので、編集後に値を戻す際にご確認ください。


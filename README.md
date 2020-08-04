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


# nf_tools

## 概要

Netfilter の補足ツール

## 使用方法

### nf_list.sh

    IPv4のルール一覧を表示します。
    # nf_list.sh -4

    IPv6のルール一覧を表示します。
    # nf_list.sh -6

    イーサネットブリッジのルール一覧を表示します。
    # nf_list.sh -b

### nf_ruleset.sh

    ルールリストに従ってNetfilter のルール設定を実行します。
    # nf_ruleset.sh -C 変数定義ファイル名 ルールリストのファイル名

#### 変数定義ファイルの書式

このファイルの実例等に関しては、
[examples ディレクトリ](https://github.com/yuksiy/nf_tools/tree/master/examples)
を参照してください。

#### ルールリストの書式

このファイルの実例等に関しては、
[examples ディレクトリ](https://github.com/yuksiy/nf_tools/tree/master/examples)
を参照してください。

    第1フィールド   第2フィールド   …
    --------------------------------------------
    ルールコマンド  テーブル名(-t)  コマンド  チェイン名  入力I/F  出力I/F  イーサネットタイプ  MAC発信元アドレス  MAC送信先アドレス  IP発信元アドレス  IP送信先アドレス  IPプロトコル  IP発信元ポート  IP送信先ポート  ICMPタイプ/コード  接続状態オプション(任意)  ターゲット(-j)  ターゲット固有オプション(任意)  備考 (無視されます)

* 「#」で始まる行はコメント行扱いされます。

* 空行は無視されます。

* フィールド区切り文字は「タブ」とします。

* 以下のフィールドの設定値は必須設定です。  
  * ルールコマンド
  * コマンド
  * チェイン名

* ルールコマンドフィールドに指定できる値は、以下のいずれかです。  
  半角空白文字で区切って複数の値を指定できます。  
  * 4 (=iptables)
  * 6 (=ip6tables)
  * b (=ebtables)

* 以下のフィールドに値を指定できるのは、
  ルールコマンドフィールドに「b」が指定されている場合です。  
  * イーサネットタイプ
  * MAC発信元アドレス
  * MAC送信先アドレス

* ICMPタイプ/コードフィールドに値を指定できるのは、
  以下のいずれかの条件を満たしている場合です。  
  * ルールコマンドフィールドに「4」または「6」が指定されている場合
  * ルールコマンドフィールドに「b」が指定され、かつ
    イーサネットタイプフィールドに「IPv6」が指定されている場合

* 各フィールドの設定値を「$VAR」または「${VAR}」の形式で記述すると、
  変数定義ファイルに記述された変数が参照されます。  
  ただし、以下のフィールドでは、上記の変数形式での指定はできません。(制限事項)  
  * IP発信元ポート
  * IP送信先ポート

* 各フィールド中では以下のコマンドラインマクロを使用できます。  
  ```
  マクロ      展開後文字列
  --------------------------------
  @RULE_CMD@  ルールコマンド
  ```

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* iptables (IPv4,IPv6のルールを操作する場合のみ)
* ebtables (イーサネットブリッジのルールを操作する場合のみ)
* [common_sh](https://github.com/yuksiy/common_sh)
* [color_tools](https://github.com/yuksiy/color_tools) (「examples/nf_init.sh」「examples/nf_ruleset_main.sh」を使用する場合のみ)

***注意:***  
***他のNetfilter 管理ソフト(firewalld, ufw 等)が有効になっている環境で、本パッケージを併用して使用することは推奨しません。***  
***本パッケージを使用する際には、事前にそれらを無効化またはアンインストールすることを推奨します。***

## インストール

ソースからインストールする場合:

    (Linux の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/nf_tools>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/nf_tools/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2006-2017 Yukio Shiiya

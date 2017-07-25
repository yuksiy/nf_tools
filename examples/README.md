# examples

## 「nf_ruleset_rule.ods」ファイル

nf_ruleset.sh 用の「ファイアウォール ルール設定書」のサンプルファイルです。  
[ルールリストの書式](https://github.com/yuksiy/nf_tools/blob/master/README.md#ルールリストの書式)
に従って表計算ソフトで作成しました。

***注意:***  
***このサンプルファイルでは、本パッケージの使い方を例示するためにいくつかのIPv4のルールのみを設定しています。***  
***IPv6・イーサネットブリッジのルールに関してはすべて許可となっていることに注意してください。***

## 「nf_ruleset_rule.txt」ファイル

nf_ruleset.sh 用の「ルールリスト」のサンプルファイルです。  
上記で作成したnf_ruleset_rule.ods ファイルを表計算ソフトで開き、
新規のテキストファイルにコピー・アンド・ペーストして保存したのち、
以下のコマンドを実行して不要なタブ文字を削除することによって作成しました。

    sed -i 's/\t\+$//' nf_ruleset_rule.txt

## 「nf_ruleset_conf.sh」ファイル

nf_ruleset.sh 用の「変数定義ファイル」のサンプルファイルです。  
上記で作成したnf_ruleset_rule.txt ファイルとセットで使用します。

## 「nf_init.sh」ファイル

Linux (Debian) にて、システムの起動時に
Netfilter ルールを初期化するためのサンプルファイルです。

## 「nf_ruleset_main.sh」ファイル

Linux (Debian) にて、システムの起動時に
nf_ruleset.sh を自動起動するためのサンプルファイルです。

## 「nf_ruleset.sh」の自動起動設定

「nf_ruleset_rule.ods」を除く上記の4ファイルが
カレントディレクトリに置かれているものとします。

さらに、「nf_ruleset_rule.txt」「nf_ruleset_conf.sh」の2ファイルは、
作業対象の環境に合わせて内容を編集済みであるものとします。 

***注意:***  
***以下の手順にて自動起動設定を行う前に、「nf_ruleset_rule.txt」「nf_ruleset_conf.sh」の2ファイルを十分にテストしてください。***  
***これらのファイルに不備がある状態でホストを再起動した場合、リモートからそのホストにログインできなくなる等の問題が発生する恐れがあります。***

    # install -p -m 0600 nf_ruleset_rule.txt /etc/
    # install -p -m 0700 nf_ruleset_conf.sh  /etc/
    # install -p nf_init.sh         /etc/init.d/
    # install -p nf_ruleset_main.sh /etc/init.d/
    # insserv -v nf_init.sh
    # insserv -v nf_ruleset_main.sh

## 「nf_ruleset.sh」の自動起動設定の戻し

    # insserv -v -r nf_ruleset_main.sh
    # insserv -v -r nf_init.sh
    # rm /etc/init.d/nf_init.sh
    # rm /etc/init.d/nf_ruleset_main.sh
    # rm /etc/nf_ruleset_rule.txt
    # rm /etc/nf_ruleset_conf.sh

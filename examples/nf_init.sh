#!/bin/bash

# ==============================================================================
#   機能
#     Netfilter ルールを初期化する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2005-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

### BEGIN INIT INFO
# Provides:          nf_init
# Required-Start:    kmod
# Required-Stop:     
# Should-Start:      
# Should-Stop:       
# X-Start-Before:    networking
# X-Stop-After:      networking
# Default-Start:     S
# Default-Stop:      0 1 6
# X-Interactive:     
# Short-Description: Netfilter init
# Description:       
### END INIT INFO

######################################################################
# 変数定義
######################################################################
# ユーザ変数

# システム環境 依存変数
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin
IPTABLES="iptables"
IP6TABLES="ip6tables"
EBTABLES="ebtables"

#
# cf.
#   iptables(8)
#   ip6tables(8)
#   ebtables(8)
#
IPTABLES_TABLES_ALL="filter nat mangle raw security"
IPTABLES_TABLES_POLICY_DROP="filter"
IPTABLES_TABLES_POLICY_ACCEPT="nat mangle raw security"

IP6TABLES_TABLES_ALL="filter mangle raw security"
IP6TABLES_TABLES_POLICY_DROP="filter"
IP6TABLES_TABLES_POLICY_ACCEPT="mangle raw security"

EBTABLES_TABLES_ALL="filter nat broute"
EBTABLES_TABLES_POLICY_DROP="filter"
EBTABLES_TABLES_POLICY_ACCEPT="nat broute"

#↓ここから、以下のエントリを作成するために使用するコマンドライン
#  (ユーザ定義チェインが作成されていない環境で実行すること。)
#CMD_TABLE_2_CHAIN() {
#  cmd="$1"
#  shift 1
#  for table in "$@" ; do
#    case ${cmd} in
#    ${IPTABLES})
#      chains="$(LANG=C ${cmd} -t ${table} -L | sed -n 's#^Chain \([^ ]*\) .*$#\1#p' | paste -s -d " ")"
#      echo "IPTABLES_CHAINS_${table}=\"${chains}\""
#      ;;
#    ${IP6TABLES})
#      chains="$(LANG=C ${cmd} -t ${table} -L | sed -n 's#^Chain \([^ ]*\) .*$#\1#p' | paste -s -d " ")"
#      echo "IP6TABLES_CHAINS_${table}=\"${chains}\""
#      ;;
#    ${EBTABLES})
#      chains="$(LANG=C ${cmd} -t ${table} -L | sed -n 's#^Bridge chain: \([^,]\+\),.*$#\1#p' | paste -s -d " ")"
#      echo "EBTABLES_CHAINS_${table}=\"${chains}\""
#      ;;
#    esac
#  done
#}
#CMD_TABLE_2_CHAIN ${IPTABLES}  ${IPTABLES_TABLES_ALL}
#CMD_TABLE_2_CHAIN ${IP6TABLES} ${IP6TABLES_TABLES_ALL}
#CMD_TABLE_2_CHAIN ${EBTABLES}  ${EBTABLES_TABLES_ALL}
#↑ここまで、以下のエントリを作成するために使用するコマンドライン
IPTABLES_CHAINS_filter="INPUT FORWARD OUTPUT"
IPTABLES_CHAINS_nat="PREROUTING INPUT OUTPUT POSTROUTING"
IPTABLES_CHAINS_mangle="PREROUTING INPUT FORWARD OUTPUT POSTROUTING"
IPTABLES_CHAINS_raw="PREROUTING OUTPUT"
IPTABLES_CHAINS_security="INPUT FORWARD OUTPUT"

IP6TABLES_CHAINS_filter="INPUT FORWARD OUTPUT"
IP6TABLES_CHAINS_mangle="PREROUTING INPUT FORWARD OUTPUT POSTROUTING"
IP6TABLES_CHAINS_raw="PREROUTING OUTPUT"
IP6TABLES_CHAINS_security="INPUT FORWARD OUTPUT"

EBTABLES_CHAINS_filter="INPUT FORWARD OUTPUT"
EBTABLES_CHAINS_nat="PREROUTING OUTPUT POSTROUTING"
EBTABLES_CHAINS_broute="BROUTING"

# プログラム内部変数
COLOR_ECHO="color_echo.sh"
COLOR_INFO="light_blue"
COLOR_ERR="light_red"

#ECHO_INFO="echo"
#ECHO_ERR="${ECHO_INFO}"
ECHO_INFO="${COLOR_ECHO} -F ${COLOR_INFO}"
ECHO_ERR="${COLOR_ECHO} -F ${COLOR_ERR}"

FLAG_OPT_NO_PLAY=FALSE

######################################################################
# 関数定義
######################################################################
USAGE() {
	cat <<- EOF 1>&2
		Usage:
		  nf_init.sh [OPTIONS ...] MODE
		
		  MODE : {start|stop|flush}
		
		OPTIONS:
		  -n (no-play)
		     Print the commands that would be executed, but do not execute them.
	EOF
}

CMD_E() {
	if [ "${FLAG_OPT_NO_PLAY}" = "FALSE" ];then
		eval "$*"
		if [ $? -ne 0 ];then
			${ECHO_ERR} "NG!"
			exit 1
		fi
	else
		echo "+ $*"
	fi
}

# 全テーブルの全組み込みチェインのポリシーをセット
POLICY_SET() {
	echo -n " Policy set "
	CMD_TABLE_CHAIN ${IPTABLES}  P DROP   ${IPTABLES_TABLES_POLICY_DROP}
	CMD_TABLE_CHAIN ${IPTABLES}  P ACCEPT ${IPTABLES_TABLES_POLICY_ACCEPT}
	CMD_TABLE_CHAIN ${IP6TABLES} P DROP   ${IP6TABLES_TABLES_POLICY_DROP}
	CMD_TABLE_CHAIN ${IP6TABLES} P ACCEPT ${IP6TABLES_TABLES_POLICY_ACCEPT}
	CMD_TABLE_CHAIN ${EBTABLES}  P DROP   ${EBTABLES_TABLES_POLICY_DROP}
	CMD_TABLE_CHAIN ${EBTABLES}  P ACCEPT ${EBTABLES_TABLES_POLICY_ACCEPT}
	${ECHO_INFO} "OK!"
}

# 全テーブルの全組み込みチェインのポリシーをリセット
POLICY_RESET() {
	echo -n " Policy reset "
	CMD_TABLE_CHAIN ${IPTABLES}  P ACCEPT ${IPTABLES_TABLES_ALL}
	CMD_TABLE_CHAIN ${IP6TABLES} P ACCEPT ${IP6TABLES_TABLES_ALL}
	CMD_TABLE_CHAIN ${EBTABLES}  P ACCEPT ${EBTABLES_TABLES_ALL}
	${ECHO_INFO} "OK!"
}

# 全テーブルの全チェインのルールをクリア
CHAIN_FLUSH() {
	echo -n " All chains flush "
	CMD_TABLE ${IPTABLES}  F ${IPTABLES_TABLES_ALL}
	CMD_TABLE ${IP6TABLES} F ${IP6TABLES_TABLES_ALL}
	CMD_TABLE ${EBTABLES}  F ${EBTABLES_TABLES_ALL}
	${ECHO_INFO} "OK!"
}

# 全テーブルの全ユーザ定義チェインを削除
CHAIN_DEL() {
	echo -n " User-defined chains delete "
	CMD_TABLE ${IPTABLES}  X ${IPTABLES_TABLES_ALL}
	CMD_TABLE ${IP6TABLES} X ${IP6TABLES_TABLES_ALL}
	CMD_TABLE ${EBTABLES}  X ${EBTABLES_TABLES_ALL}
	${ECHO_INFO} "OK!"
}

CMD_TABLE() {
	cmd="$1"
	command="$2"
	shift 2
	for table in "$@" ; do
		CMD_E "${cmd} -t ${table} -${command}"
	done
}

CMD_TABLE_CHAIN() {
	cmd="$1"
	command="$2"
	target="$3"
	shift 3
	for table in "$@" ; do
		case ${cmd} in
		${IPTABLES})	chains=IPTABLES_CHAINS_${table};;
		${IP6TABLES})	chains=IP6TABLES_CHAINS_${table};;
		${EBTABLES})	chains=EBTABLES_CHAINS_${table};;
		esac
		for chain in ${!chains} ; do
			CMD_E "${cmd} -t ${table} -${command} ${chain} ${target}"
		done
	done
}

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o n -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-n)	FLAG_OPT_NO_PLAY=TRUE ; shift 1;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ "$1" = "" ];then
	echo "-E Missing MODE argument" 1>&2
	USAGE;exit 1
else
	# モードのチェック
	case "$1" in
	start|stop|flush)
		MODE="$1"
		;;
	*)
		echo "-E Invalid MODE argument" 1>&2
		USAGE;exit 1
		;;
	esac
fi

#####################
# メインループ 開始 #
#####################

# 処理開始メッセージの表示
echo "Netfilter init script: nf_init.sh ${MODE}"

case "${MODE}" in
start)
	POLICY_SET
	CHAIN_FLUSH
	CHAIN_DEL
	;;
stop)
	#セキュリティの観点から、使用中止。
	echo " All chains flushing disabled, use \"flush\" instead of \"stop\""
	;;
flush)
	POLICY_RESET
	CHAIN_FLUSH
	CHAIN_DEL
	;;
esac

exit 0


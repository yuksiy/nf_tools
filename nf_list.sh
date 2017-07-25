#!/bin/sh

# ==============================================================================
#   機能
#     Netfilter のルール一覧を表示する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2006-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 関数定義
######################################################################
USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    nf_list.sh [OPTIONS ...] [CHAIN]
		
		    CHAIN : Specify the chain which the command should operate on.
		            If no chain is specified, all chains are listed.
		
		OPTIONS:
		    -4
		       List rules for IPv4.
		       This option can not be specified together with -6 or -b.
		    -6
		       List rules for IPv6.
		       This option can not be specified together with -4 or -b.
		    -b
		       List rules for ethernet bridge.
		       This option can not be specified together with -4 or -6.
		    -t TABLE
		       Specify the packet matching table which the command should operate on.
		       Default is ${TABLE}.
		    --help
		       Display this help and exit.
	EOF
}

######################################################################
# 変数定義
######################################################################
# ユーザ変数
IPTABLES_L_OPTION="-n --line-numbers -v"
IP6TABLES_L_OPTION="-n --line-numbers -v"
EBTABLES_L_OPTION="--Ln"

# システム環境 依存変数
IPTABLES="iptables"
IP6TABLES="ip6tables"
EBTABLES="ebtables"

# プログラム内部変数
RULE_CMD="4"
TABLE="filter"
CHAIN=""

#DEBUG=TRUE

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o 46bt: -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE ${ACTION};exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-4|-6|-b)	RULE_CMD="`echo \"${opt}\" | sed 's#^-##'`" ; shift 1;;
	-t)	TABLE="$2" ; shift 2;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ ! "$1" = "" ];then
	CHAIN="$1"
fi

# 変数定義(引数のチェック後)
case ${RULE_CMD} in
4)
	CMD=${IPTABLES}
	CMD_OPTION=${IPTABLES_L_OPTION}
	;;
6)
	CMD=${IP6TABLES}
	CMD_OPTION=${IP6TABLES_L_OPTION}
	;;
b)
	CMD=${EBTABLES}
	CMD_OPTION=${EBTABLES_L_OPTION}
	;;
esac

# ルール一覧の表示
echo "##############################################################################"
echo "# Table ${TABLE}"
echo "##############################################################################"
${CMD} -t ${TABLE} -L ${CHAIN} ${CMD_OPTION}
echo


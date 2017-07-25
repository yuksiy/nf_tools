#!/bin/sh

# ==============================================================================
#   機能
#     Netfilter ルール設定スクリプトを実行する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2006-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

### BEGIN INIT INFO
# Provides:          nf_ruleset_main
# Required-Start:    nf_init
# Required-Stop:     nf_init
# Should-Start:      
# Should-Stop:       
# X-Start-Before:    networking
# X-Stop-After:      networking
# Default-Start:     S
# Default-Stop:      0 1 6
# X-Interactive:     
# Short-Description: Netfilter ruleset
# Description:       
### END INIT INFO

######################################################################
# 変数定義
######################################################################
# ユーザ変数

# システム環境 依存変数
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

# プログラム内部変数
COLOR_ECHO="color_echo.sh"
COLOR_INFO="light_blue"
COLOR_ERR="light_red"

#ECHO_INFO="echo"
#ECHO_ERR="${ECHO_INFO}"
ECHO_INFO="${COLOR_ECHO} -F ${COLOR_INFO}"
ECHO_ERR="${COLOR_ECHO} -F ${COLOR_ERR}"

NF_RULESET="/usr/local/sbin/nf_ruleset.sh"
CONFIG_FILE="/etc/nf_ruleset_conf.sh"
RULE_LIST="/etc/nf_ruleset_rule.txt"

FLAG_OPT_NO_PLAY=FALSE
FLAG_OPT_VERBOSE=FALSE

#DEBUG=TRUE
RULE_LIST_SH=""
SHEBANG_CMD_LINE="/bin/sh -e"
EXCLUDE_IN_IFACE=""
EXCLUDE_OUT_IFACE=""

######################################################################
# 関数定義
######################################################################
USAGE() {
	cat <<- EOF 1>&2
		Usage:
		  nf_ruleset_main.sh [OPTIONS ...] MODE
		
		  MODE : {start|stop}
		
		OPTIONS:
		  -n (no-play)
		     Print the commands that would be executed, but do not execute them.
		  -v (verbose)
		     Verbose output.
		  -R RULE_LIST_SH
		     Specify a nf_rule_list.sh location if you want to change the default.
		  --exclude_in_iface=EXCLUDE_IN_IFACE
		  --exclude_out_iface=EXCLUDE_OUT_IFACE
		     Specify pattern of field value to exclude.
	EOF
}

CMD_E() {
	eval "$*"
	if [ $? -ne 0 ];then
		${ECHO_ERR} "NG!"
		exit 1
	fi
}

# Netfilter ルール設定スクリプトの実行
RULESET() {
	echo -n " All rules set "
	NF_RULESET_OPTIONS="-C ${CONFIG_FILE}${RULE_LIST_SH:+ -R \"${RULE_LIST_SH}\"}${SHEBANG_CMD_LINE:+ -S \"${SHEBANG_CMD_LINE}\"}${EXCLUDE_IN_IFACE:+ --exclude_in_iface=\"${EXCLUDE_IN_IFACE}\"}${EXCLUDE_OUT_IFACE:+ --exclude_out_iface=\"${EXCLUDE_OUT_IFACE}\"}"
	if [ "${FLAG_OPT_NO_PLAY}" = "FALSE" ];then
		if [ "${FLAG_OPT_VERBOSE}" = "TRUE" ];then
			NF_RULESET_OPTIONS="-v ${NF_RULESET_OPTIONS}"
		fi
	else
		NF_RULESET_OPTIONS="-n ${NF_RULESET_OPTIONS}"
	fi
	CMD_E "${NF_RULESET} ${NF_RULESET_OPTIONS} ${RULE_LIST}"
	${ECHO_INFO} "OK!"
}

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o nvR: -l exclude_in_iface:,exclude_out_iface: -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE ${ACTION};exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-n)	FLAG_OPT_NO_PLAY=TRUE ; shift 1;;
	-v)	FLAG_OPT_VERBOSE=TRUE ; shift 1;;
	-R)	RULE_LIST_SH="$2" ; shift 2;;
	--exclude_in_iface)	EXCLUDE_IN_IFACE="$2" ; shift 2;;
	--exclude_out_iface)	EXCLUDE_OUT_IFACE="$2" ; shift 2;;
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
	start|stop)
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
echo "Netfilter ruleset script: nf_ruleset_main.sh ${MODE}"

case "${MODE}" in
start)
	RULESET
	;;
stop)
	:
	;;
esac

exit 0


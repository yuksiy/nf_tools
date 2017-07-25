#!/bin/sh

# ==============================================================================
#   機能
#     ルールリストに従ってNetfilter のルール設定を実行する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2006-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_ROOT=`dirname $0`
SCRIPT_NAME=`basename $0`
PID=$$

LANG=ja_JP.UTF-8

######################################################################
# 変数定義
######################################################################
# ユーザ変数

# システム環境 依存変数
export IPTABLES="iptables"
export IP6TABLES="ip6tables"
export EBTABLES="ebtables"

# プログラム内部変数
FLAG_OPT_NO_PLAY=FALSE
FLAG_OPT_VERBOSE=FALSE
CONFIG_FILE=""

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"
RULE_LIST_SH="${SCRIPT_TMP_DIR}/nf_rule_list.sh"
SHEBANG_CMD_LINE="/bin/sh -e"
EXCLUDE_IN_IFACE=""
EXCLUDE_OUT_IFACE=""

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	mkdir -p "${SCRIPT_TMP_DIR}"
}

POST_PROCESS() {
	# 一時ディレクトリの削除
	if [ ! ${DEBUG} ];then
		rm -fr "${SCRIPT_TMP_DIR}"
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    nf_ruleset.sh [OPTIONS ...] RULE_LIST
		
		    RULE_LIST : Specify the netfilter rule list.
		
		OPTIONS:
		    -n (no-play)
		       Print the commands that would be executed, but do not execute them.
		    -v (verbose)
		       Verbose output.
		    -C CONFIG_FILE (config-file)
		       Specify a config file if you need it.
		    -R RULE_LIST_SH
		       Specify a location of nf_rule_list.sh if you want to change the default.
		    -S SHEBANG_CMD_LINE
		       Specify a shebang command line of nf_rule_list.sh if you want to change
		       the default.
		    --exclude_in_iface=EXCLUDE_IN_IFACE
		    --exclude_out_iface=EXCLUDE_OUT_IFACE
		       Specify pattern of field value to exclude.
		    --help
		       Display this help and exit.
	EOF
}

. mod_convert_function.sh

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o nvC:R:S: -l exclude_in_iface:,exclude_out_iface:,help -- \"$@\" 2>&1`"
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
	-C)
		CONFIG_FILE="$2" ; shift 2
		# 変数定義ファイルのチェック
		if [ ! -f "${CONFIG_FILE}" ];then
			echo "-E CONFIG_FILE not a file -- \"${CONFIG_FILE}\"" 1>&2
			USAGE;exit 1
		fi
		# 変数定義ファイルの読み込み
		. "${CONFIG_FILE}"
		;;
	-R)	RULE_LIST_SH="$2" ; shift 2;;
	-S)	SHEBANG_CMD_LINE="$2" ; shift 2;;
	--exclude_in_iface)	EXCLUDE_IN_IFACE="$2" ; shift 2;;
	--exclude_out_iface)	EXCLUDE_OUT_IFACE="$2" ; shift 2;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ "$1" = "" ];then
	echo "-E Missing RULE_LIST argument" 1>&2
	USAGE;exit 1
else
	export RULE_LIST="$1"
	# ルールリストのチェック
	if [ ! -f "${RULE_LIST}" ];then
		echo "-E RULE_LIST not a file -- \"${RULE_LIST}\"" 1>&2
		USAGE;exit 1
	fi
	# ルールリストのモード・オーナ・グループ取得
	mod_str=`ls -ald "${RULE_LIST}" | awk '{print $1}'`
	mod=`MOD_STR2OCT ${mod_str}`
	uname=`ls -ald "${RULE_LIST}" | awk '{print $3}'`
	gname=`ls -ald "${RULE_LIST}" | awk '{print $4}'`
fi

# 作業開始前処理
PRE_PROCESS

# ルールリストスクリプトのヘッダ作成
cat /dev/null >         "${RULE_LIST_SH}"
if [ $? -ne 0 ];then
	echo "-E Cannot write file -- \"${RULE_LIST_SH}\"" 1>&2
	POST_PROCESS;exit 1
fi
chown ${uname}:${gname} "${RULE_LIST_SH}"
chmod ${mod}            "${RULE_LIST_SH}"
if [ ! "${CONFIG_FILE}" = "" ];then
	cat <<- EOF >> "${RULE_LIST_SH}"
		#!${SHEBANG_CMD_LINE}
		
		. "${CONFIG_FILE}"
		
	EOF
else
	cat <<- EOF >> "${RULE_LIST_SH}"
		#!${SHEBANG_CMD_LINE}
		
	EOF
fi

# ルールリストスクリプトのコンテンツ部分の作成
awk -F '\t' \
	-v EXCLUDE_IN_IFACE="${EXCLUDE_IN_IFACE}" \
	-v EXCLUDE_OUT_IFACE="${EXCLUDE_OUT_IFACE}" \
' \
function APPEND_CMD_LINE(opt, arg, exclamation_arg) {
	cmd_line=sprintf("%s %s", cmd_line, OPT_ARG(opt, arg, exclamation_arg))
}
function OPT_ARG(opt, arg, exclamation_arg, i) {
	values_max=SPLIT_VALUE_SPACE(arg)
	if (exclamation_arg == "MAY" && values[1] == "!") {
		values_min=2
		opt_arg=sprintf("! %s", opt)
	} else {
		values_min=1
		opt_arg=sprintf("%s", opt)
	}
	for (i=values_min; i<=values_max; i++) opt_arg=sprintf("%s%s ", opt_arg, values[i])
	sub(/ $/, "", opt_arg)
	return opt_arg
}
function SPLIT_VALUE_SPACE(value) {
	sub(/^ +/, "", value)	# value の先頭の1個以上の空白文字を削除
	sub(/ +$/, "", value)	# value の末尾の1個以上の空白文字を削除
	return split(value, values, " +")
}
{
	# コメントまたは空行でない場合
	if ($0 !~/^#/ && $0 != "") {
		# フィールド値の取得
		                      # option                                                        "!" argument
		                      # --------------------------------------------------------------------------
		rule_cmd=$1           # N/A                                                           NONE

		table=$2              # -t                                                            NONE
		command=$3            # -command                                                      NONE
		chain=$4              # N/A                                                           NONE
		in_iface=$5           # -i                                                            MAY
		out_iface=$6          # -o                                                            MAY

		ether_type=$7         # -p                                                            MAY
		mac_src_addr=$8       # -s                                                            MAY
		mac_dest_addr=$9      # -d                                                            MAY

		ip_src_addr=$10       # -s|--ip-source|--ip6-source                                   MAY
		ip_dest_addr=$11      # -d|--ip-destination|--ip6-destination                         MAY
		ip_proto=$12          # -p|--ip-protocol|--ip6-protocol                               MAY

		ip_src_port=$13       # --sport|--sports|--ip-source-port|--ip6-source-port           MAY|MAY
		ip_dest_port=$14      # --dport|--dports|--ip-destination-port|--ip6-destination-port MAY|MAY

		ip_icmp_type=$15      # --icmp-type|--icmpv6-type|--ip6-icmp-type                     MAY|MAY

		ip_status_options=$16 # N/A                                                           NONE
		target=$17            # -j                                                            NONE
		target_options=$18    # N/A                                                           NONE

		# 必須フィールドのチェック
		if (rule_cmd == "" || command == "" || chain == "") {
			system(sprintf("echo 1>&2"))
			system(sprintf("echo \042-E Omitted required field at line %s -- \134\042${RULE_LIST}\134\042\042 1>&2", NR))
			system(sprintf("echo \047%s\047 1>&2", $0))
			exit 1
		}

		# 変数形式で指定できないフィールドのチェック
		if (ip_src_port ~/\$/ || ip_dest_port ~/\$/) {
			system(sprintf("echo 1>&2"))
			system(sprintf("echo \042-E Variable used in prohibited field at line %s -- \134\042${RULE_LIST}\134\042\042 1>&2", NR))
			system(sprintf("echo \047%s\047 1>&2", $0))
			exit 1
		}

		# ルールコマンドのループ
		split(rule_cmd, rule_cmds, " +")
		cmd_line=""
		for (i in rule_cmds) {
			# ルールコマンドフィールドのチェック
			if (rule_cmds[i] == "4") {
				cmd=ENVIRON["IPTABLES"]
			} else if (rule_cmds[i] == "6") {
				cmd=ENVIRON["IP6TABLES"]
			} else if (rule_cmds[i] == "b") {
				cmd=ENVIRON["EBTABLES"]
			} else {
				system(sprintf("echo 1>&2"))
				system(sprintf("echo \042-E Invalid value of rule_cmd field at line %s -- \134\042${RULE_LIST}\134\042\042 1>&2", NR))
				system(sprintf("echo \047%s\047 1>&2", $0))
				exit 1
			}

			# コマンドラインの構成
			cmd_line=sprintf("eval %s", cmd)
			if (table     != "") APPEND_CMD_LINE("-t ", table,     "NONE")
			if (command   != "") APPEND_CMD_LINE("-",   command,   "NONE")
			if (chain     != "") APPEND_CMD_LINE("",    chain,     "NONE")
			if (in_iface  != "") APPEND_CMD_LINE("-i ", in_iface,  "MAY")
			if (out_iface != "") APPEND_CMD_LINE("-o ", out_iface, "MAY")

			# ether_type, mac_src_addr, mac_dest_addr
			if (rule_cmds[i] == "b") {
				if (ether_type    != "") APPEND_CMD_LINE("-p ", ether_type,   "MAY")
				if (mac_src_addr  != "") APPEND_CMD_LINE("-s ", ip_src_addr,  "MAY")
				if (mac_dest_addr != "") APPEND_CMD_LINE("-d ", ip_dest_addr, "MAY")
			} else {
				if (ether_type    != "" ||
				    mac_src_addr  != "" ||
				    mac_dest_addr != "") {
					system(sprintf("echo 1>&2"))
					system(sprintf("echo \042-E Cannot specify value in following field: ether_type, mac_src_addr, mac_dest_addr at line %s -- \134\042${RULE_LIST}\134\042\042 1>&2", NR))
					system(sprintf("echo \047%s\047 1>&2", $0))
					exit 1
				}
			}

			# ip_src_addr, ip_dest_addr, ip_proto
			if (rule_cmds[i] == "4" || rule_cmds[i] == "6") {
				if (ip_src_addr  != "") APPEND_CMD_LINE("-s ", ip_src_addr,  "MAY")
				if (ip_dest_addr != "") APPEND_CMD_LINE("-d ", ip_dest_addr, "MAY")
				if (ip_proto     != "") APPEND_CMD_LINE("-p ", ip_proto,     "MAY")
			} else if (rule_cmds[i] == "b") {
				if (ether_type ~/^[Ii][Pp][Vv]4$/) {
					if (ip_src_addr  != "") APPEND_CMD_LINE("--ip-source ",      ip_src_addr,  "MAY")
					if (ip_dest_addr != "") APPEND_CMD_LINE("--ip-destination ", ip_dest_addr, "MAY")
					if (ip_proto     != "") APPEND_CMD_LINE("--ip-protocol ",    ip_proto,     "MAY")
				} else if (ether_type ~/^[Ii][Pp][Vv]6$/) {
					if (ip_src_addr  != "") APPEND_CMD_LINE("--ip6-source ",      ip_src_addr,  "MAY")
					if (ip_dest_addr != "") APPEND_CMD_LINE("--ip6-destination ", ip_dest_addr, "MAY")
					if (ip_proto     != "") APPEND_CMD_LINE("--ip6-protocol ",    ip_proto,     "MAY")
				}
			}

			# ip_src_port, ip_dest_port
			if (rule_cmds[i] == "4" || rule_cmds[i] == "6") {
				# 変数初期化
				multiport=""
				# ip_src_port|ip_dest_portにカンマが含まれる場合
				if (ip_src_port  ~/,/) multiport="TRUE"
				if (ip_dest_port ~/,/) multiport="TRUE"
				# ip_src_port|ip_dest_portが空でなく、かつカンマが含まれない場合
				# --sport|--dportオプションをmultiportモジュールオプションより前に書き出す
				if (ip_src_port  != "" && ip_src_port  !~/,/) APPEND_CMD_LINE("--sport ", ip_src_port,  "MAY")
				if (ip_dest_port != "" && ip_dest_port !~/,/) APPEND_CMD_LINE("--dport ", ip_dest_port, "MAY")
				# multiportが空でない場合、multiportモジュールオプションの書き出し
				if (multiport != "") APPEND_CMD_LINE("-m ", "multiport", "NONE")
				# ip_src_port|ip_dest_portが空でなく、かつカンマが含まれる場合
				# --sports|--dportsオプションをmultiportモジュールオプションの後に書き出す
				if (ip_src_port  != "" && ip_src_port  ~/,/) APPEND_CMD_LINE("--sports ", ip_src_port,  "MAY")
				if (ip_dest_port != "" && ip_dest_port ~/,/) APPEND_CMD_LINE("--dports ", ip_dest_port, "MAY")
			} else if (rule_cmds[i] == "b") {
				if (ether_type ~/^[Ii][Pp][Vv]4$/) {
					if (ip_src_port  != "") APPEND_CMD_LINE("--ip-source-port ",      ip_src_port,  "MAY")
					if (ip_dest_port != "") APPEND_CMD_LINE("--ip-destination-port ", ip_dest_port, "MAY")
				} else if (ether_type ~/^[Ii][Pp][Vv]6$/) {
					if (ip_src_port  != "") APPEND_CMD_LINE("--ip6-source-port ",      ip_src_port,  "MAY")
					if (ip_dest_port != "") APPEND_CMD_LINE("--ip6-destination-port ", ip_dest_port, "MAY")
				}
			}

			# ip_icmp_type
			if (ip_icmp_type != "") {
				if (rule_cmds[i] == "4") {
					APPEND_CMD_LINE("--icmp-type ", ip_icmp_type, "MAY")
				} else if (rule_cmds[i] == "6") {
					APPEND_CMD_LINE("--icmpv6-type ", ip_icmp_type, "MAY")
				} else if (rule_cmds[i] == "b") {
					if (ether_type ~/^[Ii][Pp][Vv]6$/) {
						APPEND_CMD_LINE("--ip6-icmp-type ", ip_icmp_type, "MAY")
					} else {
						system(sprintf("echo 1>&2"))
						system(sprintf("echo \042-E Cannot specify value in following field: ip_icmp_type at line %s -- \134\042${RULE_LIST}\134\042\042 1>&2", NR))
						system(sprintf("echo \047%s\047 1>&2", $0))
						exit 1
					}
				}
			}

			if (ip_status_options != "") APPEND_CMD_LINE("",    ip_status_options, "NONE")
			if (target != "")            APPEND_CMD_LINE("-j ", target,            "NONE")
			if (target_options != "")    APPEND_CMD_LINE("",    target_options,    "NONE")

			# コマンドラインマクロの更新
			gsub(/@RULE_CMD@/, rule_cmds[i], cmd_line)

			# record_reasonの初期化
			record_reason=""
			if (EXCLUDE_IN_IFACE != "" && in_iface ~EXCLUDE_IN_IFACE) {
				record_reason=sprintf("%s,%s", record_reason, "in_iface")
			} else if (EXCLUDE_OUT_IFACE != "" && out_iface ~EXCLUDE_OUT_IFACE) {
				record_reason=sprintf("%s,%s", record_reason, "out_iface")
			}
			sub(/^,/, "", record_reason)
			# record_reasonが空でない場合
			if (record_reason != "") {
				cmd_line=sprintf("#Disabled by the reason: %s# %s", record_reason, cmd_line)
			}

			# コマンドラインの出力
			printf("%s\n", cmd_line)
		}
	# コメントまたは空行の場合
	} else {
		# 行全体を加工せずに出力
		printf("%s\n", $0)
	}
}' "${RULE_LIST}" \
>> "${RULE_LIST_SH}"
if [ $? -ne 0 ];then
	POST_PROCESS;exit 1
fi

#####################
# メインループ 開始 #
#####################

if [ "${FLAG_OPT_NO_PLAY}" = "FALSE" ];then
	if [ "${FLAG_OPT_VERBOSE}" = "FALSE" ];then
		${SHEBANG_CMD_LINE}    "${RULE_LIST_SH}"
	else
		${SHEBANG_CMD_LINE} -x "${RULE_LIST_SH}"
	fi
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
else
	cat "${RULE_LIST_SH}"
fi

#####################
# メインループ 終了 #
#####################

# 作業終了後処理
POST_PROCESS;exit 0


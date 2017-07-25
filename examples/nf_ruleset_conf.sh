#!/bin/sh

# インターフェース
export IF_LOOPBACK="lo"

# ログ取得
export _4_OPT_LOG_DROP="--log-prefix \"DROP_IP4: \" --log-level warning"
export _6_OPT_LOG_DROP="--log-prefix \"DROP_IP6: \" --log-level warning"
export _4_OPT_LIMIT_DROP="-m limit"
export _6_OPT_LIMIT_DROP="-m limit"

modprobe ebt_log
modprobe ebt_limit
export _b_OPT_LOG_DROP="--log-prefix \"DROP_EBT: \" --log-level warning"
export _b_OPT_LIMIT_DROP="--limit 3/hour"

# 接続状態
export OPT_STATE_NEW_SET="-m state --state NEW,ESTABLISHED,RELATED"
export OPT_STATE_NEW_RESET="-m state --state ESTABLISHED,RELATED"


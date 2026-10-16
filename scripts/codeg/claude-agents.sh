#!/bin/bash
# Claude の公式 Grok プラグインだけに、専用の読み取り専用起動方法を渡す。
export GROK_BINARY="${HOME}/.local/bin/codeg-grok-readonly"
exec /usr/bin/claude "$@"

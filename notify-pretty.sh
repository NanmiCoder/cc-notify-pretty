#!/bin/bash

TYPE=$1
PROJECT_NAME=$(basename "$CLAUDE_PROJECT_DIR")
# 定义图标路径
CLAUDE_ICON_PNG="$HOME/.claude/icons/claude_icon.png"
CLAUDE_ICON_URL="file://$HOME/.claude/icons/claude_icon.png"

# =========== 关键修改开始 ===========
# 定义我们刚才魔改过的那个特定程序的绝对路径
# 不要直接用 "terminal-notifier"，一定要用这个全路径！
NOTIFIER_BIN="$HOME/.claude/claude-notifier.app/Contents/MacOS/terminal-notifier"
# =========== 关键修改结束 ===========

if [ "$TYPE" = "stop" ]; then
    # 使用我们定义的绝对路径变量来运行命令
    "$NOTIFIER_BIN" \
        -title "✅ 任务完成" \
        -subtitle "项目: $PROJECT_NAME" \
        -message "Claude Code 已完成所有操作" \
        -sound "Glass" \
        -appIcon "$CLAUDE_ICON_URL" \
        -group "claude-stop-$PROJECT_NAME" \
        -execute "/usr/local/bin/cursor '$CLAUDE_PROJECT_DIR'"

elif [ "$TYPE" = "permission" ]; then
    # 使用我们定义的绝对路径变量来运行命令
    "$NOTIFIER_BIN" \
        -title "🔐 需要授权" \
        -subtitle "项目: $PROJECT_NAME" \
        -message "Claude Code 需要你的确认才能继续" \
        -sound "Submarine" \
        -appIcon "$CLAUDE_ICON_URL" \
        -group "claude-permission-$PROJECT_NAME" \
        -execute "/usr/local/bin/cursor '$CLAUDE_PROJECT_DIR'"
fi

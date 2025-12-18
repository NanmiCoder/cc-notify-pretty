# Claude Code 通知工具

## 工具简介

`notify-pretty.sh` 是一个 macOS 通知脚本，用于在 Claude Code CLI 工具执行任务时向用户发送桌面通知。

---

## 快速安装指南

按照以下步骤，从零开始安装配置 Claude Code 通知工具。

### 前置要求

- macOS 系统
- 已安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- 已安装 Homebrew（用于安装 terminal-notifier）

### 第 1 步：安装 terminal-notifier

```bash
brew install terminal-notifier
```

### 第 2 步：创建目录结构

```bash
mkdir -p ~/.claude/scripts
mkdir -p ~/.claude/icons
```

### 第 3 步：复制 terminal-notifier 为自定义应用

```bash
# 复制 terminal-notifier.app 作为 claude-notifier.app
cp -R /opt/homebrew/Cellar/terminal-notifier/2.0.0/terminal-notifier.app ~/.claude/claude-notifier.app

# 注意：如果你的 Homebrew 安装在其他位置（如 Intel Mac），路径可能是：
# /usr/local/Cellar/terminal-notifier/2.0.0/terminal-notifier.app
```

### 第 4 步：准备 Claude 图标

下载或创建一个 Claude 图标（PNG 格式，建议至少 256x256 像素），保存到：

```bash
~/.claude/icons/claude_icon.png
```

### 第 5 步：生成并替换图标

```bash
# 创建 iconset 目录
mkdir -p /tmp/claude.iconset

# 生成各种尺寸的图标
sips -z 16 16     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_16x16.png
sips -z 32 32     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_16x16@2x.png
sips -z 32 32     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_32x32.png
sips -z 64 64     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_32x32@2x.png
sips -z 128 128   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_128x128.png
sips -z 256 256   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_128x128@2x.png
sips -z 256 256   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_256x256.png
sips -z 512 512   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_256x256@2x.png
sips -z 512 512   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_512x512.png
sips -z 1024 1024 ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_512x512@2x.png

# 转换为 ICNS
iconutil -c icns /tmp/claude.iconset -o /tmp/claude_icon.icns

# 替换应用中的图标
cp /tmp/claude_icon.icns ~/.claude/claude-notifier.app/Contents/Resources/Terminal.icns
cp /tmp/claude_icon.icns ~/.claude/claude-notifier.app/Contents/Resources/AppIcon.icns
cp /tmp/claude_icon.icns ~/.claude/icons/claude_icon.icns
```

### 第 6 步：配置应用属性

```bash
# 修改 bundle identifier（避免图标缓存问题）
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.claude.notifier.v2" \
    ~/.claude/claude-notifier.app/Contents/Info.plist

# 设置通知样式为"提醒"（不自动消失）
/usr/libexec/PlistBuddy -c "Set :NSUserNotificationAlertStyle alert" \
    ~/.claude/claude-notifier.app/Contents/Info.plist

# 删除旧签名并重新签名
rm -rf ~/.claude/claude-notifier.app/Contents/_CodeSignature
codesign --force --deep --sign - ~/.claude/claude-notifier.app

# 注册应用
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f ~/.claude/claude-notifier.app
```

### 第 7 步：创建通知脚本

创建文件 `~/.claude/scripts/notify-pretty.sh`：

```bash
#!/bin/bash

TYPE=$1
PROJECT_NAME=$(basename "$CLAUDE_PROJECT_DIR")
# 定义图标路径
CLAUDE_ICON_PNG="$HOME/.claude/icons/claude_icon.png"
CLAUDE_ICON_URL="file://$HOME/.claude/icons/claude_icon.png"

# 定义通知程序路径
NOTIFIER_BIN="$HOME/.claude/claude-notifier.app/Contents/MacOS/terminal-notifier"

if [ "$TYPE" = "stop" ]; then
    "$NOTIFIER_BIN" \
        -title "✅ 任务完成" \
        -subtitle "项目: $PROJECT_NAME" \
        -message "Claude Code 已完成所有操作" \
        -sound "Glass" \
        -appIcon "$CLAUDE_ICON_URL" \
        -group "claude-stop-$PROJECT_NAME" \
        -execute "/usr/local/bin/cursor '$CLAUDE_PROJECT_DIR'"

elif [ "$TYPE" = "permission" ]; then
    "$NOTIFIER_BIN" \
        -title "🔐 需要授权" \
        -subtitle "项目: $PROJECT_NAME" \
        -message "Claude Code 需要你的确认才能继续" \
        -sound "Submarine" \
        -appIcon "$CLAUDE_ICON_URL" \
        -group "claude-permission-$PROJECT_NAME" \
        -execute "/usr/local/bin/cursor '$CLAUDE_PROJECT_DIR'"
fi
```

设置执行权限：

```bash
chmod +x ~/.claude/scripts/notify-pretty.sh
```

### 第 8 步：配置 Claude Code Hooks

编辑 Claude Code 配置文件 `~/.claude/settings.json`，添加 hooks 配置：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/notify-pretty.sh stop"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/notify-pretty.sh permission"
          }
        ]
      }
    ]
  }
}
```

如果你已有 `settings.json` 文件，只需合并 `hooks` 部分即可。

### 第 8.1 步：配置点击通知后的跳转行为（可选）

脚本中的 `-execute` 参数定义了点击通知后执行的命令。默认配置为使用 **Cursor** 编辑器打开项目：

```bash
-execute "/usr/local/bin/cursor '$CLAUDE_PROJECT_DIR'"
```

如果你使用其他 IDE，请修改 `notify-pretty.sh` 中的 `-execute` 参数：

| IDE | 配置示例 |
|-----|----------|
| Cursor | `-execute "/usr/local/bin/cursor '$CLAUDE_PROJECT_DIR'"` |
| VS Code | `-execute "/usr/local/bin/code '$CLAUDE_PROJECT_DIR'"` |
| WebStorm | `-execute "/usr/local/bin/webstorm '$CLAUDE_PROJECT_DIR'"` |
| Sublime Text | `-execute "/usr/local/bin/subl '$CLAUDE_PROJECT_DIR'"` |
| Vim/Neovim | `-execute "open -a Terminal '$CLAUDE_PROJECT_DIR'"` |

> **提示**：如果你不确定你的 IDE 命令行工具路径，可以使用 `which <命令>` 查找，例如 `which code`。
>
> 如果你使用其他 IDE 或有特殊需求，可以让 AI 帮你找到正确的配置方式。

### 第 9 步：授权通知权限

首次运行时，macOS 会询问是否允许通知。你也可以手动设置：

1. 打开 **系统设置** → **通知**
2. 找到 **claude-notifier**
3. 开启 **允许通知**
4. 选择通知样式为 **提醒**（如果希望通知不自动消失）

### 第 10 步：测试

```bash
export CLAUDE_PROJECT_DIR="$HOME/.claude/scripts"
~/.claude/scripts/notify-pretty.sh stop
```

如果看到带有 Claude 图标的通知弹窗，说明安装成功！

---

## 解决的问题

在使用 Claude Code 进行编程任务时，某些操作可能需要较长时间，或者需要用户授权才能继续。如果用户切换到其他窗口工作，可能会错过重要的提示。

这个工具通过 macOS 原生通知系统解决了这个问题：
- **任务完成通知**：当 Claude Code 完成任务时，发送通知提醒用户
- **授权请求通知**：当 Claude Code 需要用户确认才能继续时，发送通知

## 背景

### 技术栈

- 基于 [terminal-notifier](https://github.com/julienXX/terminal-notifier) 构建
- 使用自定义的 `claude-notifier.app`，位于 `~/.claude/claude-notifier.app`
- 通过 Claude Code 的 hooks 机制触发

### 目录结构

```
~/.claude/
├── claude-notifier.app/          # 自定义的通知应用
│   └── Contents/
│       ├── Info.plist            # 应用配置（bundle identifier: com.claude.notifier.v2）
│       ├── MacOS/
│       │   └── terminal-notifier # 可执行文件
│       └── Resources/
│           ├── Terminal.icns     # 应用图标（Claude 图标）
│           └── AppIcon.icns      # 应用图标（Claude 图标）
├── icons/
│   ├── claude_icon.png           # Claude 图标 PNG 格式
│   └── claude_icon.icns          # Claude 图标 ICNS 格式
└── scripts/
    └── notify-pretty.sh          # 通知脚本
```

## 遇到的问题

### 问题描述

在 macOS 系统设置中，`claude-notifier` 应用显示的是正确的 Claude 图标，但实际发送通知时，通知弹窗中显示的仍然是旧的终端图标。

### 问题原因

经过探索发现了以下问题：

1. **ICNS 文件未更新**：`claude_icon.icns` 的内容与旧的 `Terminal.icns` 完全相同（MD5 哈希值一致），只有 PNG 文件是新的

2. **contentImage vs appIcon**：脚本中使用的 `-contentImage` 参数只是在通知内容中添加附加图片，不会改变应用图标

3. **macOS 图标缓存顽固**：即使替换了 `.icns` 文件，macOS 仍然使用基于 bundle identifier 缓存的旧图标

## 解决方案

### 步骤 1：创建正确的 ICNS 文件

使用 `iconutil` 从 PNG 生成包含多种分辨率的 ICNS 文件：

```bash
# 创建 iconset 目录
mkdir -p /tmp/claude.iconset

# 生成各种尺寸
sips -z 16 16     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_16x16.png
sips -z 32 32     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_16x16@2x.png
sips -z 32 32     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_32x32.png
sips -z 64 64     ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_32x32@2x.png
sips -z 128 128   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_128x128.png
sips -z 256 256   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_128x128@2x.png
sips -z 256 256   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_256x256.png
sips -z 512 512   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_256x256@2x.png
sips -z 512 512   ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_512x512.png
sips -z 1024 1024 ~/.claude/icons/claude_icon.png --out /tmp/claude.iconset/icon_512x512@2x.png

# 转换为 ICNS
iconutil -c icns /tmp/claude.iconset -o /tmp/claude_icon.icns
```

### 步骤 2：替换图标文件

```bash
cp /tmp/claude_icon.icns ~/.claude/claude-notifier.app/Contents/Resources/Terminal.icns
cp /tmp/claude_icon.icns ~/.claude/claude-notifier.app/Contents/Resources/AppIcon.icns
cp /tmp/claude_icon.icns ~/.claude/icons/claude_icon.icns
```

### 步骤 3：修改 Bundle Identifier（关键步骤）

这是解决缓存问题的关键。修改 bundle identifier 让 macOS 认为这是一个全新的应用：

```bash
# 修改 bundle identifier
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.claude.notifier.v2" \
    ~/.claude/claude-notifier.app/Contents/Info.plist

# 删除旧的代码签名
rm -rf ~/.claude/claude-notifier.app/Contents/_CodeSignature

# 重新签名（ad-hoc 签名）
codesign --force --deep --sign - ~/.claude/claude-notifier.app

# 重新注册应用
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f ~/.claude/claude-notifier.app
```

### 步骤 4：更新通知脚本

在脚本中添加 `-appIcon` 参数（使用 URL 格式）：

```bash
CLAUDE_ICON_URL="file://$HOME/.claude/icons/claude_icon.png"

"$NOTIFIER_BIN" \
    -title "任务完成" \
    -message "..." \
    -appIcon "$CLAUDE_ICON_URL" \
    ...
```

## 使用方法

### 发送任务完成通知

```bash
export CLAUDE_PROJECT_DIR="/path/to/project"
~/.claude/scripts/notify-pretty.sh stop
```

### 发送授权请求通知

```bash
export CLAUDE_PROJECT_DIR="/path/to/project"
~/.claude/scripts/notify-pretty.sh permission
```

## 通知样式配置

macOS 支持两种通知样式：

| 样式 | 说明 |
|------|------|
| `banner`（横幅） | 几秒后自动消失 |
| `alert`（提醒） | 需要用户手动关闭，会一直停留 |

当前配置为 `alert` 样式，通知不会自动消失，避免错过重要提示。

如需修改样式，编辑 Info.plist：

```bash
# 改为提醒样式（不消失）
/usr/libexec/PlistBuddy -c "Set :NSUserNotificationAlertStyle alert" \
    ~/.claude/claude-notifier.app/Contents/Info.plist

# 改为横幅样式（自动消失）
/usr/libexec/PlistBuddy -c "Set :NSUserNotificationAlertStyle banner" \
    ~/.claude/claude-notifier.app/Contents/Info.plist

# 修改后需要重新签名
codesign --force --deep --sign - ~/.claude/claude-notifier.app
```

## 关键经验

1. **macOS 图标缓存基于 bundle identifier**：仅替换图标文件不够，需要修改 bundle identifier 才能让系统刷新图标

2. **-appIcon 参数需要 URL 格式**：不能直接使用文件路径，需要使用 `file://` 前缀

3. **修改 Info.plist 后需要重新签名**：否则应用可能无法正常运行

4. **terminal-notifier 参数说明**：
   - `-appIcon`：替换通知左侧的应用图标
   - `-contentImage`：在通知内容中添加附加图片（右侧）
   - `-sender`：指定发送者的 bundle identifier

5. **通知样式由 Info.plist 控制**：`NSUserNotificationAlertStyle` 决定通知是否自动消失

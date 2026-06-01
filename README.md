# MacTranslator

macOS 菜单栏翻译工具，选中文本按 `⌥T` 即可翻译，支持任意应用。

## 功能

- 全局快捷键 `⌥T` 翻译选中文本
- 自动语言检测：中文 ↔ 英文
- 毛玻璃浮窗显示，鼠标附近弹出
- 一键复制翻译结果
- 菜单栏内嵌 API Key 设置，无需打开额外窗口
- 使用 DeepSeek API，成本极低

## 环境要求

- macOS 13+
- Swift 5.9+
- DeepSeek API Key（[申请地址](https://platform.deepseek.com)）

## 使用

```bash
# 编译
swift build

# 运行
.build/debug/MacTranslator
```

启动后：
1. 菜单栏出现书本图标
2. 点击图标 → 设置 → 填入 DeepSeek API Key → 保存
3. 在任意应用选中文字，按 `⌥T` 即可翻译

## 项目结构

```
Sources/MacTranslator/
├── main.swift            # 入口
├── AppDelegate.swift     # 菜单栏与翻译流程
├── TranslationService.swift  # DeepSeek API 调用
├── TranslationPanel.swift    # 浮窗 UI
├── HotkeyManager.swift   # 全局快捷键注册
└── SettingsView.swift    # 菜单栏内嵌设置面板
```

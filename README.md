# MacTranslator

macOS 菜单栏翻译工具，选中文本按 `⌥T` 即可翻译，支持任意应用。

## 功能

- 全局快捷键 `⌥T` 翻译选中文本
- 自动语言检测：英文 → 中文
- 毛玻璃浮窗显示，大小自适应
- 一键复制翻译结果
- 使用 DeepSeek API，成本极低

## 使用

```bash
# 编译
swift build

# 运行
.build/debug/MacTranslator
```

首次运行需要：
1. 在设置中填入 DeepSeek API Key
2. 系统设置 → 隐私与安全性 → 辅助功能 → 允许 MacTranslator

## 要求

- macOS 13.0+
- DeepSeek API Key

# IETLS AI (Flutter)

IETLS AI 是一个面向 IELTS Writing Task 2 的 Flutter 写作辅助项目，核心交互模仿 VSCode 的自动补全体验：**AI 生成建议，用户按 Tab 直接接受补全**。

## 目标体验（VSCode 风格）

- 在编辑器中输入作文时，AI 根据上下文生成补全文本。
- 补全以灰色 Ghost Text 形式显示在光标后方（当前版本优先支持“光标位于末尾”场景）。
- 快捷键：
  - `Tab`：接受整条建议
  - `Ctrl + →`：接受一个词
  - `Esc`：忽略建议
  - `Ctrl + R`：重新生成建议
- 点击 `归档为 .md`：将当前题目与正文保存到本地归档目录

## 核心流程

```text
用户输入 -> Debounce -> Trigger Policy -> Completion Mode Detect
-> Context Extract -> Prompt Build -> Model Adapter (DeepSeek)
-> Stream Response -> Post Process -> Ghost Text/Suggestion Bar
-> 用户按 Tab 接受 -> 写回编辑器
```

## 项目结构（已实现）

```text
lib/
  main.dart

  app/
    ielts_ai_app.dart

  editor/
    document_snapshot.dart
    essay_editor_controller.dart

  ai/
    ai_assist_engine.dart
    ai_assist_preference.dart
    completion_mode_detector.dart
    context_extractor.dart
    debouncer.dart
    post_processor.dart
    prompt_builder.dart
    trigger_policy.dart
    model/
      model_api_adapter.dart
      deepseek_adapter.dart
    models/
      ai_request.dart

  ui/
    pages/
      essay_editor_page.dart
    widgets/
      ghost_text_editor.dart
      suggestion_bar.dart
```

## 模块职责

- **EssayEditorController**：管理编辑器文本、光标、输入变化快照。
- **AiAssistEngine**：统一处理自动触发与手动触发、流式补全、取消请求。
- **TriggerPolicy + Debouncer**：控制何时请求 AI（频繁/较少/手动）。
- **CompletionModeDetector**：判断“续写当前句 / 下一句 / 下一段”。
- **ContextExtractor**：提取题目、分数、光标上下文、当前句段。
- **PromptBuilder**：构建约束明确的补全 Prompt。
- **ModelApiAdapter**：模型适配层；默认实现 DeepSeekAdapter。
- **PostProcessor**：清洗模型输出，保证可直接插入。
- **GhostTextEditor + SuggestionBar**：负责视觉呈现与键盘交互。

## 运行方式

```bash
flutter pub get
flutter run -d windows
```

## 环境变量（API Key）

项目改为通过根目录 `.env` 读取 API Key，不再在前端输入框里配置。

```env
DEEPSEEK_API_KEY=your_api_key_here
```

未配置时，AI 请求会被拦截并提示先配置 `.env`。

## 归档功能

点击设置区的 `归档为 .md` 按钮后，会把当前内容保存到本地：

- 目录：`<应用文档目录>/ieltsai_archives/`
- 文件名：`essay_yyyyMMdd_HHmmss.md`

## 当前实现说明

- 已完成完整 Flutter 分层设计和可运行交互闭环。
- 默认使用 `DeepSeekAdapter` 的模拟流式输出（方便离线开发与调试）。
- 若接入真实 API，只需在 `model_api_adapter.dart` 接口下替换 `deepseek_adapter.dart` 的实现，不影响业务层结构。

# AI 智能助手模块 — 开发日志

## 一、模块概述

在 HarmonyOS 健康生活应用中新增 AI 智能助手 Tab，用户可以与 AI 进行多轮对话，获得健康建议。AI 接口对接 DeepSeek API（OpenAI 兼容格式），聊天记录持久化到本地关系型数据库。

---

## 二、新增文件

### 1. `entry/src/main/ets/ai/model/ChatMessage.ets` — 数据模型

定义聊天消息和 API 交互所需的所有类型：

```typescript
export enum MessageRole {
  USER = 'user',
  ASSISTANT = 'assistant',
  SYSTEM = 'system'
}

export class ChatMessage {
  role: MessageRole;
  content: string;
  timestamp: number;

  constructor(role: MessageRole, content: string) {
    this.role = role;
    this.content = content;
    this.timestamp = Date.now();
  }
}

export interface ApiMessage {
  role: string;
  content: string;
}

export interface ApiChoice {
  message: ApiMessage;
}

export interface ApiResponse {
  choices: ApiChoice[];
}

export interface ApiRequestMessage {
  role: string;
  content: string;
}

export interface ApiRequestBody {
  model: string;
  messages: ApiRequestMessage[];
  temperature: number;
  max_tokens: number;
}
```

| 类型 | 用途 |
|------|------|
| `MessageRole` | 枚举，标识消息发送者（用户/AI/系统） |
| `ChatMessage` | 前端使用的消息对象，含角色、内容、时间戳 |
| `ApiMessage` / `ApiChoice` / `ApiResponse` | 解析 API 返回的 JSON 响应 |
| `ApiRequestMessage` / `ApiRequestBody` | 组装发送给 API 的请求体 |

---

### 2. `entry/src/main/ets/ai/service/AiService.ets` — AI API 服务层

封装 HTTP 请求，对接 DeepSeek 等 OpenAI 兼容 API。

```typescript
export class AiService {
  private apiUrl: string = 'https://api.deepseek.com/v1/chat/completions';
  private apiKey: string = 'sk-xxx';
  private model: string = 'deepseek-chat';

  configure(apiUrl: string, apiKey: string, model?: string): void
  buildSystemPrompt(healthContext: string): string
  buildMessages(userMessage: string, history: ChatMessage[], healthContext: string): ApiRequestMessage[]
  async sendMessage(userMessage: string, history: ChatMessage[], healthContext: string): Promise<string>
}
```

| 方法 | 功能 |
|------|------|
| `configure()` | 配置 API 地址、密钥、模型名 |
| `buildSystemPrompt()` | 构建系统提示词，注入健康应用上下文 |
| `buildMessages()` | 将系统提示 + 历史消息 + 新消息组装为请求数组 |
| `sendMessage()` | 使用 `@ohos.net.http` 发起 POST 请求，解析返回的 AI 回复 |

#### 调用流程

```
用户输入 → AiChatPage.sendMessage()
  → AiService.sendMessage()
    → http.createHttp().request(POST, body)
    → 解析 response.result → ApiResponse
    → 返回 choices[0].message.content
  → AiChatPage 显示 AI 回复
```

#### 系统提示词

> 你是一个健康生活助手，帮助用户管理日常健康习惯。你可以根据用户的健康数据给出建议和鼓励。
> 当前用户的健康数据摘要：${healthContext}
> 请用简洁友好的中文回答用户问题，字数控制在200字以内。

---

### 3. `entry/src/main/ets/ai/pages/AiChatPage.ets` — 聊天界面

```typescript
@Component
export struct AiChatPage {
  @State messages: ChatMessage[] = [];  // 消息列表
  @State inputText: string = '';        // 输入框内容
  @State isLoading: boolean = false;    // 加载状态
  @State inputRefreshKey: number = 0;   // 用于重建输入框清空文字
  private scroller: Scroller = new Scroller();  // 滚动控制

  aboutToAppear()    // 从 DB 加载历史消息，无记录则显示欢迎语
  sendMessage()      // 发送消息，调用 AI 服务，显示回复
  saveMessage(msg)   // 消息写入 DB
  scrollToBottom()   // 新消息后自动滚动到底部
  buildMessageBubble(msg)  // @Builder 渲染聊天气泡
  build()            // 组装整个聊天页面 UI
}
```

#### UI 布局

```
Column {
  Row { Text("AI 助手") }                      // 蓝色标题栏 56vp
  Scroll {                                     // 消息区域 layoutWeight(1)
    ForEach(this.messages) {
      buildMessageBubble(msg)                  // 聊天气泡
    }
  }
  if (isLoading) {                             // 加载指示器 36vp
    Row { LoadingProgress + Text("AI正在思考...") }
  }
  Row {                                        // 输入栏
    TextInput { ... }                          // 输入框 layoutWeight(1)
    Button("发送")                              // 发送按钮
  }
}
```

#### 聊天气泡样式

- **用户消息**：蓝色 (`#007DFF`) 背景、白色文字、右对齐、左下直角其他圆角
- **AI 消息**：灰色 (`#F2F2F2`) 背景、深色文字、左对齐、右下直角其他圆角
- 最大宽度 80%，间距 8vp

#### 关键实现细节

| 问题 | 解决方案 |
|------|---------|
| TextInput 不显示文字 | 不绑定 `text` 属性（非受控组件），仅用 `onChange` 追踪值 |
| 输入框获取焦点 | `.defaultFocus(true)` + `.focusable(true)` |
| 发送后清空输入框 | 使用 `.key('input_${inputRefreshKey}')`，每发一次 key 值+1，强制重建组件 |
| 切换 Tab 消息不丢失 | `@State messages` 保留在内存中，Tab 切换不销毁组件 |

---

### 4. `entry/src/main/ets/common/database/tables/ChatMsgApi.ets` — 聊天记录持久化

新建 `chatMsg` 表，提供增删查操作。

```typescript
export interface ChatMsgRow {
  id: number;
  role: string;
  content: string;
  timestamp: number;
}

class ChatMsgApi {
  insertData(role: string, content: string, timestamp: number, callback: Function): void
  queryAll(callback: Function): void
  deleteAll(callback: Function): void
}
```

#### 数据库表结构

| 列名 | 类型 | 说明 |
|------|------|------|
| `id` | INTEGER | 主键，自增 |
| `role` | TEXT | 消息角色：`user` / `assistant` / `system` |
| `content` | TEXT | 消息内容 |
| `timestamp` | INTEGER | 毫秒时间戳 |

#### 持久化流程

```
用户发送消息 → AiChatPage.sendMessage()
  → 创建 ChatMessage 对象
  → messages 数组追加
  → ChatMsgApi.insertData() 写入 chatMsg 表

AI 回复 → AiChatPage.sendMessage()
  → 创建 ChatMessage 对象
  → messages 数组追加
  → ChatMsgApi.insertData() 写入 chatMsg 表

页面加载 → AiChatPage.aboutToAppear()
  → ChatMsgApi.queryAll() 读取全部行
  → 按 row.role 还原为 MessageRole 枚举
  → 恢复 messages 数组
```

---

## 三、修改的已有文件

### 1. `module.json5` — 新增网络权限

```json5
{
  "name": "ohos.permission.INTERNET",
  "reason": "$string:internet_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
}
```

AI 助手需要通过 HTTP 调用云端 API，因此需要网络权限。

---

### 2. `resources/base/element/string.json` — 新增字符串

```json
{ "name": "tab_ai",          "value": "AI助手" }
{ "name": "internet_reason", "value": "Used for AI assistant network requests" }
```

---

### 3. `model/NavItemModel.ets` — 新增 AI Tab

```typescript
export enum TabId {
  HOME,
  ACHIEVEMENT,
  AI,          // 新增
  MINE
}

export const NavList: NavItem[] = [
  { /* 首页 */ },
  { /* 成就 */ },
  { /* AI助手 */ },  // 新增，位于成就和我的之间
  { /* 我的 */ },
]
```

---

### 4. `pages/MainPage.ets` — 主页面新增 TabContent

```typescript
import { AiChatPage } from '../ai/pages/AiChatPage';

// build() 中新增第三个 TabContent：
TabContent() {
  AiChatPage()
}
.tabBar(this.TabBuilder(TabId.AI))
```

底部导航栏变为：**首页 → 成就 → AI助手 → 我的**

---

### 5. `model/RdbColumnModel.ets` — 新增 chatMsg 表列定义

```typescript
export const columnChatMsgList: Array<ColumnInfo> = [
  new ColumnInfo('id', 'integer', -1, false, true, true),       // 主键 自增
  new ColumnInfo('role', 'text', -1, false, false, false),      // 角色
  new ColumnInfo('content', 'text', -1, false, false, false),   // 内容
  new ColumnInfo('timestamp', 'integer', -1, false, false, false) // 时间戳
];
```

---

### 6. `common/constants/CommonConstants.ets` — 新增表名常量

```typescript
static readonly CHAT_MSG = {
  tableName: 'chatMsg',
  columns: ['id', 'role', 'content', 'timestamp']
} as CommonConstantsInfo
```

---

### 7. `entryability/EntryAbility.ets` — 启动时建表

```typescript
import { columnChatMsgList } from '../model/RdbColumnModel';

// onCreate() 中新增：
RdbUtils.createTable(Const.CHAT_MSG.tableName, columnChatMsgList)
  .then(() => Logger.info('RdbHelper createTable chatMsg success'))
  .catch((err) => Logger.error('RdbHelper chatMsg err : ' + JSON.stringify(err)));
```

---

### 8. `viewmodel/HomeViewModel.ets` — 修复打卡 Bug

**Bug 1：新添加任务被标记为已完成**

```diff
- let task = new TaskInfo(0, dateToStr(new Date()), taskID, targetValue, isAlarm,
-     startTime, endTime, frequency, true, targetValue, isOpen);
+ let task = new TaskInfo(0, dateToStr(new Date()), taskID, targetValue, isAlarm,
+     startTime, endTime, frequency, false, '0', isOpen);
```

第9个参数 `isDone` 从 `true` 改为 `false`，第10个参数 `finValue` 从 `targetValue` 改为 `'0'`。

**Bug 2：添加/删除任务未同步数据库**

```typescript
// 添加任务时：
TaskInfoTableApi.updateDataByDate(task, (res: number) => {
  if (!res) {
    TaskInfoTableApi.insertData(task, (insertRes: number) => {
      Logger.info('...', `Insert task ${taskID} for ${task.date}, result: ${insertRes}`);
    });
  }
});

// 删除任务时：
TaskInfoTableApi.updateDataByDate(task, (res: number) => {
  Logger.info('...', `Disable task ${taskID} for ${task.date}, result: ${res}`);
});
```

先尝试更新已有行（`updateDataByDate`），如返回 0（行不存在）则插入新行（`insertData`）。

---

## 四、架构总览

```
MainPage (Tabs: 首页 | 成就 | AI助手 | 我的 )
                         │
                         ▼
                    AiChatPage
                   /    │     \
                  /     │      \
          AiService  ChatMsgApi  UI Components
         (HTTP请求)   (RDB存储)   (聊天气泡/输入框)
              │          │
              ▼          ▼
     DeepSeek API    taskInfo.db/chatMsg表
```

---

## 五、技术栈

| 层面 | 技术 |
|------|------|
| UI 框架 | ArkTS 声明式 (`@Component`、`@State`、`@Builder`) |
| 列表渲染 | `ForEach` + `Scroll` |
| 表单输入 | `TextInput`（非受控模式，通过 `.key()` 重建清空） |
| HTTP 通信 | `@ohos.net.http` |
| 本地存储 | `@ohos.data.relationalStore` (RDB) |
| 日志 | `@ohos.hilog` → Logger 封装 (TAG: `AiService` / `AiChatPage` / `ChatMsgTable`) |
| AI 模型 | DeepSeek `deepseek-chat`（OpenAI 兼容格式） |

---

## 六、数据流

```
┌─────────────┐    POST /v1/chat/completions    ┌──────────────┐
│  AiService  │ ──────────────────────────────→ │  DeepSeek API │
│  (HTTP)     │ ←────────────────────────────── │               │
└──────┬──────┘    JSON { choices: [...] }      └──────────────┘
       │
       │ sendMessage()
       ▼
┌─────────────┐    insertData()                  ┌──────────────┐
│ AiChatPage  │ ──────────────────────────────→ │   chatMsg 表  │
│  (UI)       │ ←──── queryAll() ─────────────  │   (RDB)      │
└─────────────┘                                  └──────────────┘
```

---

## 七、扩展计划（未实现）

- [ ] 健康数据真实注入（读取 taskInfo / dayInfo 表数据作为 AI 上下文）
- [ ] API 配置设置页面（替换硬编码 Key）
- [ ] 快捷问题预设按钮
- [ ] 流式输出（SSE / 打字机效果）
- [ ] 停止生成按钮
- [ ] 端侧 AI 方案（HiAI / MindSpore Lite）

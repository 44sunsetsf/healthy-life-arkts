import { ChatMessage, MessageRole } from '../model/ChatMessage';
import { aiService } from '../service/AiService';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import ChatMsgApi, { ChatMsgRow } from '../../common/database/tables/ChatMsgApi';
import TaskInfoTableApi from '../../common/database/tables/TaskInfoApi';
import DayInfoApi from '../../common/database/tables/DayInfoApi';
import TaskInfo from '../../viewmodel/TaskInfo';
import DayInfo from '../../viewmodel/DayInfo';
import Logger from '../../common/utils/Logger';

const TAG = 'AiChatPage';

const TASK_NAMES: string[] = ['早起', '喝水', '吃苹果', '每日微笑', '每日刷牙', '早睡'];
const TASK_UNITS: string[] = ['', '', '个', '次', '次', ''];

interface Conversation {
  title: string;
  date: string;
  msgCount: number;
  timeStart: number;
  timeEnd: number;
}

@Component
export struct AiChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State showHistory: boolean = false;
  @State conversations: Conversation[] = [];
  private scroller: Scroller = new Scroller();
  private firstLoad: boolean = true;

  aboutToAppear() {
    if (this.firstLoad) {
      this.firstLoad = false;
      this.showWelcome();
    }
  }

  showWelcome(): void {
    const welcome = new ChatMessage(MessageRole.ASSISTANT,
      '你好！我是你的健康生活AI助手。你可以问我关于健康习惯、饮食、运动等方面的问题，我也可以根据你的打卡数据给你个性化的建议。请问有什么可以帮你的？');
    this.messages = [welcome];
  }

  newConversation(): void {
    this.saveMessage(new ChatMessage(MessageRole.SYSTEM, ''));
    this.showWelcome();
    this.inputText = '';
    this.showHistory = false;
    this.scrollToBottom();
  }

  loadHistory(): void {
    ChatMsgApi.queryAll((rows: ChatMsgRow[]) => {
      if (!rows || rows.length === 0) {
        this.conversations = [];
        return;
      }
      const groups: Conversation[] = [];
      let currentStart = 0;
      let currentEnd = 0;
      let firstUserMsg = '';
      let count = 0;
      let started = false;

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        if (row.role === 'system') {
          if (started && count > 0 && firstUserMsg) {
            groups.push({
              title: firstUserMsg,
              date: new Date(currentStart).toLocaleString(),
              msgCount: count,
              timeStart: currentStart,
              timeEnd: currentEnd
            });
          }
          started = false;
          firstUserMsg = '';
          count = 0;
          continue;
        }
        if (!started) {
          currentStart = row.timestamp;
          started = true;
        }
        currentEnd = row.timestamp;
        count++;
        if (!firstUserMsg && row.role === 'user') {
          firstUserMsg = row.content;
        }
      }
      if (started && count > 0 && firstUserMsg) {
        groups.push({
          title: firstUserMsg,
          date: new Date(currentStart).toLocaleString(),
          msgCount: count,
          timeStart: currentStart,
          timeEnd: currentEnd
        });
      }
      this.conversations = groups.reverse();
    });
  }

  restoreConversation(conv: Conversation): void {
    ChatMsgApi.queryAll((rows: ChatMsgRow[]) => {
      const msgs: ChatMessage[] = [];
      for (const row of rows) {
        if (row.role === 'system') {
          continue;
        }
        if (row.timestamp >= conv.timeStart && row.timestamp <= conv.timeEnd) {
          let msgRole: MessageRole = MessageRole.ASSISTANT;
          if (row.role === 'user') {
            msgRole = MessageRole.USER;
          }
          const msg = new ChatMessage(msgRole, row.content);
          msg.timestamp = row.timestamp;
          msgs.push(msg);
        }
      }
      this.messages = msgs;
      this.showHistory = false;
      this.scrollToBottom();
    });
  }

  saveMessage(msg: ChatMessage): void {
    ChatMsgApi.insertData(msg.role, msg.content, msg.timestamp, (res: number) => {
      Logger.debug(TAG, `saveMessage: role=${msg.role}, len=${msg.content.length}, result=${res}`);
    });
  }

  buildHealthContext(): Promise<string> {
    return new Promise<string>((resolve) => {
      const today = new Date().toDateString();
      TaskInfoTableApi.query(today, true, (taskList: TaskInfo[]) => {
        DayInfoApi.query(today, (dayInfo: DayInfo) => {
          let context = `今天是${today}。\n今日打卡情况如下：\n`;
          let finishCount = 0;
          let totalCount = 0;
          for (let i = 0; i < taskList.length; i++) {
            const task = taskList[i];
            const taskId = task.taskID - 1;
            const name = TASK_NAMES[taskId];
            const unit = TASK_UNITS[taskId];
            if (task.isDone) {
              finishCount++;
              context += `- ${name}：✅ 已完成`;
            } else {
              context += `- ${name}：❌ 未完成`;
            }
            if (unit && task.targetValue) {
              context += `（${task.finValue}/${task.targetValue}${unit}）`;
            }
            context += '\n';
            totalCount++;
          }
          context += `\n总体进度：${finishCount}/${totalCount} 已完成。`;
          if (finishCount === totalCount && totalCount > 0) {
            context += ' 所有任务已全部完成！';
          }
          resolve(context);
        });
      });
    });
  }

  async sendMessage() {
    const text = this.inputText.trim();
    if (!text || this.isLoading) {
      return;
    }
    const userMsg = new ChatMessage(MessageRole.USER, text);
    this.messages = this.messages.concat([userMsg]);
    this.saveMessage(userMsg);
    this.inputText = '';
    this.scrollToBottom();
    this.isLoading = true;
    const healthContext = await this.buildHealthContext();
    try {
      const reply = await aiService.sendMessage(text, this.messages.slice(0, -1), healthContext);
      const aiMsg = new ChatMessage(MessageRole.ASSISTANT, reply);
      this.messages = this.messages.concat([aiMsg]);
      this.saveMessage(aiMsg);
    } catch (err) {
      const errMsg = new ChatMessage(MessageRole.ASSISTANT, '抱歉，网络请求失败了，请检查网络连接和API配置后重试。');
      this.messages = this.messages.concat([errMsg]);
    } finally {
      this.isLoading = false;
      this.scrollToBottom();
    }
  }

  scrollToBottom() {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }

  @Builder
  buildHistoryPanel() {
    Column() {
      Row() {
        Text('历史记录')
          .fontSize('18fp')
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('＋')
          .fontSize('22fp')
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .onClick(() => this.newConversation())
        Text('✕')
          .fontSize('16fp')
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .onClick(() => { this.showHistory = false; })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#6C5CE7')
      .padding({ left: 20, right: 20 })

      if (this.conversations.length === 0) {
        Column() {
          Text('📭')
            .fontSize('48fp')
            .margin({ top: 120 })
          Text('暂无历史记录')
            .fontSize('14fp')
            .fontColor('#999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F0FF')
      } else {
        Scroll() {
          Column() {
            ForEach(this.conversations, (conv: Conversation, index: number) => {
              Row() {
                Column() {
                  Text('💬')
                    .fontSize('28fp')
                }
                .width(44)
                .height(44)
                .borderRadius(22)
                .backgroundColor('#F0EBFF')
                .justifyContent(FlexAlign.Center)
                .margin({ right: 12 })

                Column() {
                  Text(conv.title.length > 25 ? conv.title.substring(0, 25) + '...' : conv.title)
                    .fontSize('14fp')
                    .fontColor('#2D3436')
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${conv.date}  ·  ${conv.msgCount} 条消息`)
                    .fontSize('11fp')
                    .fontColor('#B2BEC3')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 14, bottom: 14 })
              .backgroundColor('#FFFFFF')
              .border({ width: { bottom: '0.5vp' }, color: '#F0EBFF' })
              .onClick(() => this.restoreConversation(conv))
            }, (conv: Conversation) => conv.timeStart.toString())
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .backgroundColor('#F5F0FF')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildUserBubble(msg: ChatMessage) {
    Row() {
      Blank()
      Column() {
        Text(msg.content)
          .fontSize('15fp')
          .fontColor('#FFFFFF')
          .lineHeight('22fp')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .borderRadius({
            topLeft: 20,
            topRight: 20,
            bottomLeft: 20,
            bottomRight: 4
          })
          .backgroundColor('#6C5CE7')
          .constraintSize({ maxWidth: '78%' })
      }
      .shadow({ radius: 8, color: '#406C5CE7', offsetX: 0, offsetY: 3 })
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 6, bottom: 6 })
  }

  @Builder
  buildAiBubble(msg: ChatMessage) {
    Row() {
      Column() {
        Text('🤖')
          .fontSize('16fp')
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('#EDE7FF')
      .justifyContent(FlexAlign.Center)
      .margin({ right: 8, top: 4 })

      Column() {
        Text(msg.content)
          .fontSize('15fp')
          .fontColor('#2D3436')
          .lineHeight('22fp')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .borderRadius({
            topLeft: 4,
            topRight: 20,
            bottomLeft: 20,
            bottomRight: 20
          })
          .backgroundColor('#FFFFFF')
          .constraintSize({ maxWidth: '72%' })
      }
      .shadow({ radius: 6, color: '#18000000', offsetX: 0, offsetY: 2 })

      Blank()
    }
    .width('100%')
    .padding({ left: 12, right: 16, top: 6, bottom: 6 })
  }

  @Builder
  buildLoading() {
    Row() {
      Column() {
        Text('🤖')
          .fontSize('16fp')
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('#EDE7FF')
      .justifyContent(FlexAlign.Center)
      .margin({ right: 8 })

      Row({ space: 4 }) {
        Text('•').fontSize('20fp').fontColor('#A29BFE')
        Text('•').fontSize('20fp').fontColor('#6C5CE7')
        Text('•').fontSize('20fp').fontColor('#A29BFE')
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .borderRadius({ topLeft: 4, topRight: 20, bottomLeft: 20, bottomRight: 20 })
      .backgroundColor('#FFFFFF')

      Blank()
    }
    .width('100%')
    .padding({ left: 12, right: 16, top: 6, bottom: 6 })
  }

  build() {
    if (this.showHistory) {
      this.buildHistoryPanel()
    } else {
      Column() {
        // Header
        Row() {
          Column() {
            Text('✨ AI 智能助手')
              .fontSize('18fp')
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
            Text('你的专属健康管家')
              .fontSize('10fp')
              .fontColor('#DFE6E9')
              .margin({ top: 2 })
          }
          Blank()
          Row({ space: 4 }) {
            Text('＋')
              .fontSize('18fp')
              .fontColor('#FFFFFF')
              .width(34)
              .height(34)
              .borderRadius(17)
              .backgroundColor('#FFFFFF20')
              .textAlign(TextAlign.Center)
              .onClick(() => this.newConversation())
            Text('📋')
              .fontSize('16fp')
              .width(34)
              .height(34)
              .borderRadius(17)
              .backgroundColor('#FFFFFF20')
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.loadHistory();
                this.showHistory = true;
              })
          }
        }
        .width('100%')
        .height(64)
        .backgroundColor('#6C5CE7')
        .padding({ left: 20, right: 16 })

        // Messages
        Scroll(this.scroller) {
          Column() {
            ForEach(this.messages, (msg: ChatMessage, index: number) => {
              if (msg.role === MessageRole.USER) {
                this.buildUserBubble(msg)
              } else {
                this.buildAiBubble(msg)
              }
            }, (msg: ChatMessage, index: number) => index.toString())

            if (this.isLoading) {
              this.buildLoading()
            }

            Column().height(8)
          }
          .width('100%')
          .padding({ top: 8 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .backgroundColor('#F5F0FF')

        // Input bar
        Row() {
          TextInput({ placeholder: '输入你的问题...' })
            .fontSize('14fp')
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#FFFFFF')
            .borderRadius(22)
            .padding({ left: 20, right: 8 })
            .defaultFocus(true)
            .focusable(true)
            .onChange((value: string) => {
              this.inputText = value;
            })
            .onSubmit(() => this.sendMessage())

          Button() {
            Text('➤')
              .fontSize('16fp')
              .fontColor('#FFFFFF')
          }
          .width(42)
          .height(42)
          .borderRadius(21)
          .backgroundColor('#6C5CE7')
          .margin({ left: 6 })
          .shadow({ radius: 6, color: '#406C5CE7', offsetX: 0, offsetY: 3 })
          .onClick(() => this.sendMessage())
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('#FFFFFF')
        .border({ width: { top: '0.5vp' }, color: '#EDE7FF' })
      }
      .width('100%')
      .height('100%')
    }
  }
}

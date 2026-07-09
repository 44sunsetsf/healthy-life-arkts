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
  @State inputRefreshKey: number = 0;
  @State showHistory: boolean = false;
  @State conversations: Conversation[] = [];
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.newConversation();
  }

  newConversation(): void {
    Logger.info(TAG, 'newConversation');
    const welcome = new ChatMessage(MessageRole.ASSISTANT,
      '你好！我是你的健康生活AI助手。你可以问我关于健康习惯、饮食、运动等方面的问题，我也可以根据你的打卡数据给你个性化的建议。请问有什么可以帮你的？');
    this.messages = [welcome];
    this.inputText = '';
    this.inputRefreshKey++;
    this.scrollToBottom();
    this.saveMessage(welcome);
  }

  loadHistory(): void {
    Logger.info(TAG, 'loadHistory: querying DB');
    ChatMsgApi.queryAll((rows: ChatMsgRow[]) => {
      if (!rows || rows.length === 0) {
        Logger.info(TAG, 'loadHistory: no history');
        this.conversations = [];
        return;
      }
      const groups: Conversation[] = [];
      let currentStart = rows[0].timestamp;
      let currentEnd = rows[0].timestamp;
      let firstUserMsg = '';
      let count = 0;

      for (let i = 0; i < rows.length; i++) {
        const ts = rows[i].timestamp;
        if (ts - currentEnd > 30 * 60 * 1000) {
          if (count > 0 && firstUserMsg) {
            groups.push({
              title: firstUserMsg,
              date: new Date(currentStart).toLocaleString(),
              msgCount: count,
              timeStart: currentStart,
              timeEnd: currentEnd
            });
          }
          currentStart = ts;
          firstUserMsg = '';
          count = 0;
        }
        currentEnd = ts;
        count++;
        if (!firstUserMsg && rows[i].role === 'user') {
          firstUserMsg = rows[i].content;
        }
      }
      if (count > 0 && firstUserMsg) {
        groups.push({
          title: firstUserMsg,
          date: new Date(currentStart).toLocaleString(),
          msgCount: count,
          timeStart: currentStart,
          timeEnd: currentEnd
        });
      }
      this.conversations = groups.reverse();
      Logger.info(TAG, `loadHistory: ${this.conversations.length} conversations`);
    });
  }

  restoreConversation(conv: Conversation): void {
    Logger.info(TAG, `restoreConversation: ${conv.timeStart} - ${conv.timeEnd}`);
    ChatMsgApi.queryAll((rows: ChatMsgRow[]) => {
      const msgs: ChatMessage[] = [];
      for (const row of rows) {
        if (row.timestamp >= conv.timeStart && row.timestamp <= conv.timeEnd) {
          let msgRole: MessageRole = MessageRole.ASSISTANT;
          if (row.role === 'user') {
            msgRole = MessageRole.USER;
          } else if (row.role === 'system') {
            msgRole = MessageRole.SYSTEM;
          }
          const msg = new ChatMessage(msgRole, row.content);
          msg.timestamp = row.timestamp;
          msgs.push(msg);
        }
      }
      this.messages = msgs;
      this.showHistory = false;
      this.scrollToBottom();
      Logger.info(TAG, `restoreConversation: loaded ${msgs.length} messages`);
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

          Logger.info(TAG, `buildHealthContext: ${context}`);
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

    Logger.info(TAG, `sendMessage: userMsgLen=${text.length}, historyLen=${this.messages.length}`);

    const userMsg = new ChatMessage(MessageRole.USER, text);
    this.messages = this.messages.concat([userMsg]);
    this.saveMessage(userMsg);
    this.inputText = '';
    this.inputRefreshKey++;
    this.scrollToBottom();
    this.isLoading = true;

    const healthContext = await this.buildHealthContext();

    try {
      const reply = await aiService.sendMessage(text, this.messages.slice(0, -1), healthContext);
      Logger.info(TAG, `sendMessage: received reply len=${reply.length}`);
      const aiMsg = new ChatMessage(MessageRole.ASSISTANT, reply);
      this.messages = this.messages.concat([aiMsg]);
      this.saveMessage(aiMsg);
    } catch (err) {
      Logger.error(TAG, `sendMessage error: ${JSON.stringify(err)}`);
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
          .fontSize($r('app.float.default_18'))
          .fontColor($r('app.color.white'))
          .fontWeight(Const.FONT_WEIGHT_700)
        Blank()
        Text('➕')
          .fontSize('16fp')
          .padding($r('app.float.default_8'))
          .onClick(() => {
            this.newConversation();
          })
        Text('✕')
          .fontSize($r('app.float.default_20'))
          .fontColor($r('app.color.white'))
          .padding($r('app.float.default_8'))
          .onClick(() => {
            this.showHistory = false;
          })
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_56)
      .backgroundColor($r('app.color.blueColor'))
      .padding({ left: Const.THOUSANDTH_33, right: Const.THOUSANDTH_33 })

      if (this.conversations.length === 0) {
        Column() {
          Text('暂无历史记录')
            .fontSize($r('app.float.default_14'))
            .fontColor($r('app.color.statusTipColor'))
            .margin({ top: $r('app.float.default_100') })
        }
        .width(Const.THOUSANDTH_1000)
        .layoutWeight(1)
        .backgroundColor($r('app.color.primaryBgColor'))
      } else {
        Scroll() {
          Column() {
            ForEach(this.conversations, (conv: Conversation, index: number) => {
              Row() {
                Column() {
                  Text(conv.title.length > 30 ? conv.title.substring(0, 30) + '...' : conv.title)
                    .fontSize($r('app.float.default_14'))
                    .fontColor($r('app.color.titleColor'))
                    .fontWeight(Const.FONT_WEIGHT_500)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${conv.date}  ·  ${conv.msgCount}条消息`)
                    .fontSize($r('app.float.default_12'))
                    .fontColor($r('app.color.statusTipColor'))
                    .margin({ top: $r('app.float.default_4') })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('→')
                  .fontSize($r('app.float.default_16'))
                  .fontColor($r('app.color.blueColor'))
              }
              .width(Const.THOUSANDTH_1000)
              .padding({
                left: Const.THOUSANDTH_33,
                right: Const.THOUSANDTH_33,
                top: $r('app.float.default_14'),
                bottom: $r('app.float.default_14')
              })
              .backgroundColor($r('app.color.white'))
              .border({ width: { bottom: '0.5vp' }, color: '#E0E0E0' })
              .onClick(() => {
                this.restoreConversation(conv);
              })
            }, (conv: Conversation, index: number) => conv.timeStart.toString())
          }
          .width(Const.THOUSANDTH_1000)
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .backgroundColor($r('app.color.primaryBgColor'))
      }
    }
    .width(Const.THOUSANDTH_1000)
    .height(Const.THOUSANDTH_1000)
    .backgroundColor($r('app.color.primaryBgColor'))
  }

  @Builder
  buildMessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.role === MessageRole.USER) {
        Blank()
        Column() {
          Text(msg.content)
            .fontSize($r('app.float.default_14'))
            .fontColor($r('app.color.white'))
            .padding($r('app.float.default_12'))
            .borderRadius({
              topLeft: $r('app.float.default_12'),
              topRight: $r('app.float.default_12'),
              bottomLeft: $r('app.float.default_12')
            })
            .backgroundColor($r('app.color.blueColor'))
            .constraintSize({ maxWidth: Const.THOUSANDTH_800 })
        }
      } else {
        Column() {
          Text(msg.content)
            .fontSize($r('app.float.default_14'))
            .fontColor($r('app.color.titleColor'))
            .padding($r('app.float.default_12'))
            .borderRadius({
              topLeft: $r('app.float.default_12'),
              topRight: $r('app.float.default_12'),
              bottomRight: $r('app.float.default_12')
            })
            .backgroundColor($r('app.color.btnBgColor'))
            .constraintSize({ maxWidth: Const.THOUSANDTH_800 })
        }
        Blank()
      }
    }
    .width(Const.THOUSANDTH_1000)
    .padding({
      left: Const.THOUSANDTH_33,
      right: Const.THOUSANDTH_33,
      top: $r('app.float.default_8'),
      bottom: $r('app.float.default_8')
    })
  }

  build() {
    if (this.showHistory) {
      Column() {
        this.buildHistoryPanel()
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.THOUSANDTH_1000)
    } else {
      Column() {
        Row() {
          Text('AI 助手')
            .fontSize($r('app.float.default_22'))
            .fontColor($r('app.color.white'))
            .fontWeight(Const.FONT_WEIGHT_700)
          Blank()
          Text('➕')
            .fontSize('18fp')
            .padding($r('app.float.default_8'))
            .onClick(() => {
              this.newConversation();
            })
          Text('📋')
            .fontSize('20fp')
            .padding($r('app.float.default_8'))
            .onClick(() => {
              this.loadHistory();
              this.showHistory = true;
            })
        }
        .width(Const.THOUSANDTH_1000)
        .height(Const.DEFAULT_56)
        .backgroundColor($r('app.color.blueColor'))
        .padding({ left: Const.THOUSANDTH_33, right: Const.THOUSANDTH_33 })

        Scroll(this.scroller) {
          Column() {
            ForEach(this.messages, (msg: ChatMessage, index: number) => {
              this.buildMessageBubble(msg)
            }, (msg: ChatMessage, index: number) => index.toString())
          }
          .width(Const.THOUSANDTH_1000)
          .padding({ top: $r('app.float.default_8'), bottom: $r('app.float.default_8') })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .backgroundColor($r('app.color.primaryBgColor'))

        if (this.isLoading) {
          Row() {
            LoadingProgress()
              .width($r('app.float.default_24'))
              .height($r('app.float.default_24'))
              .color($r('app.color.blueColor'))
            Text('AI正在思考...')
              .fontSize($r('app.float.default_12'))
              .fontColor($r('app.color.statusTipColor'))
              .margin({ left: $r('app.float.default_8') })
          }
          .width(Const.THOUSANDTH_1000)
          .height($r('app.float.default_36'))
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.white'))
        }

        Row() {
          TextInput({ placeholder: '输入你的问题...' })
            .key(`input_${this.inputRefreshKey}`)
            .fontSize($r('app.float.default_14'))
            .fontColor($r('app.color.titleColor'))
            .layoutWeight(1)
            .height($r('app.float.default_40'))
            .backgroundColor($r('app.color.primaryBgColor'))
            .borderRadius($r('app.float.default_20'))
            .padding({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })
            .defaultFocus(true)
            .focusable(true)
            .onChange((value: string) => {
              this.inputText = value;
            })
            .onSubmit(() => {
              this.sendMessage();
            })

          Button('发送')
            .fontSize($r('app.float.default_14'))
            .height($r('app.float.default_40'))
            .backgroundColor($r('app.color.blueColor'))
            .fontColor($r('app.color.white'))
            .borderRadius($r('app.float.default_20'))
            .margin({ left: $r('app.float.default_8') })
            .onClick(() => {
              this.sendMessage();
            })
        }
        .width(Const.THOUSANDTH_1000)
        .padding({
          left: Const.THOUSANDTH_33,
          right: Const.THOUSANDTH_33,
          top: $r('app.float.default_8'),
          bottom: $r('app.float.default_8')
        })
        .backgroundColor($r('app.color.white'))
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.THOUSANDTH_1000)
    }
  }
}

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

@Component
export struct AiChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State inputRefreshKey: number = 0;
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    Logger.info(TAG, 'aboutToAppear: loading chat history from DB');
    ChatMsgApi.queryAll((rows: ChatMsgRow[]) => {
      if (rows && rows.length > 0) {
        Logger.info(TAG, `aboutToAppear: loaded ${rows.length} messages from DB`);
        const dbMessages: ChatMessage[] = [];
        for (const row of rows) {
          let msgRole: MessageRole = MessageRole.ASSISTANT;
          if (row.role === 'user') {
            msgRole = MessageRole.USER;
          } else if (row.role === 'system') {
            msgRole = MessageRole.SYSTEM;
          }
          const msg = new ChatMessage(msgRole, row.content);
          msg.timestamp = row.timestamp;
          dbMessages.push(msg);
        }
        this.messages = dbMessages;
        this.scrollToBottom();
      } else {
        Logger.info(TAG, 'aboutToAppear: no history, creating welcome message');
        const welcome = new ChatMessage(MessageRole.ASSISTANT,
          '你好！我是你的健康生活AI助手。你可以问我关于健康习惯、饮食、运动等方面的问题，我也可以根据你的打卡数据给你个性化的建议。请问有什么可以帮你的？');
        this.messages = [welcome];
        this.saveMessage(welcome);
      }
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
      Logger.debug(TAG, `sendMessage blocked: isEmpty=${!text}, isLoading=${this.isLoading}`);
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
    Column() {
      Row() {
        Text('AI 助手')
          .fontSize($r('app.float.default_24'))
          .fontColor($r('app.color.white'))
          .fontWeight(Const.FONT_WEIGHT_700)
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_56)
      .backgroundColor($r('app.color.blueColor'))
      .justifyContent(FlexAlign.Center)

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

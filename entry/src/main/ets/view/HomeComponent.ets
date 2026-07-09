/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import router from '@ohos.router';
import HealthText from './HealthTextComponent';
import AddBtn from '../view/home/AddBtnComponent';
import { AiFloatBtn } from '../ai/view/AiFloatBtn';
import { TaskCard } from '../view/home//TaskCardComponent';
import HomeTopView from '../view/home/HomeTopComponent';
import { CustomDialogView, CustomDialogCallback } from '../view/dialog/CustomDialogView';
import { ExpGainPopup, LevelUpPopup } from '../view/dialog/ExpGainPopup';
import TaskInfo from '../viewmodel/TaskInfo';
import { HomeStore } from '../viewmodel/HomeViewModel';
import { ITaskItem, TaskMapById } from '../model/TaskInitList';
import { HealthDataSrcMgr } from '../common/utils/HealthDataSrcMgr';
import { BroadCast, BroadCastType } from '../common/utils/BroadCast';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import AchievementInfo from '../viewmodel/AchievementInfo';
import { WeekDateModel } from '../model/WeekCalendarModel';
import { sameDate, dateToStr } from '../common/utils/Utils';
import TaskInfoTableApi from '../common/database/tables/TaskInfoApi';
import Logger from '../common/utils/Logger';

const WHITE_COLOR_0X = 255;
const MONTH_DAY_WIDTH: number = 100 / Const.WEEK_DAY_NUM;
const MONTH_WEEK_TITLES: string[] = ['一', '二', '三', '四', '五', '六', '日'];

@Styles
function allSize() {
  .width(Const.THOUSANDTH_1000)
  .height(Const.THOUSANDTH_1000)
}

@Extend(Text)
function titleTextStyle() {
  .fontSize($r('app.float.default_16'))
  .fontWeight(Const.FONT_WEIGHT_500)
  .width(Const.THOUSANDTH_1000)
  .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
  .fontColor($r(`app.element.color.titleColor`))
  .padding({
    top: Const.THOUSANDTH_15,
    bottom: Const.THOUSANDTH_15,
    left: Const.THOUSANDTH_33
  })
}

@Component
export default struct HomeIndex {
  @Provide broadCast: BroadCast = HealthDataSrcMgr.getInstance().getBroadCast();
  @State naviAlpha: number = 0;
  @Link homeStore: HomeStore;
  @Link editedTaskInfo: ITaskItem;
  @Link @Watch('taskChange') editedTaskID: string;
  @State showExpPopup: boolean = false;
  @State showLevelUpPopup: boolean = false;
  @State expGained: number = 0;
  @State levelUpLevel: number = 1;
  private scroller: Scroller = new Scroller();
  private yOffset: number = 0;

  taskChange() {
    this.homeStore.updateTaskInfoList(this.editedTaskInfo);
  }

  taskItemAction(item: TaskInfo, isClick: boolean): void {
    if (!this.homeStore.checkCurrentDay()) {
      return;
    }
    if (isClick) {
      // click to clock
      let callback: CustomDialogCallback = { confirmCallback: (taskTemp: TaskInfo) => {
        this.onConfirm(taskTemp)
      }, cancelCallback: () => {
      } };
      this.broadCast.emit(BroadCastType.SHOW_TASK_DETAIL_DIALOG, [item, callback]);
    } else {
      // edit task
      let editTaskStr: string = JSON.stringify(TaskMapById[item.taskID - 1]);
      let editTask: ITaskItem = JSON.parse(editTaskStr);
      editTask.targetValue = item?.targetValue;
      editTask.isAlarm = item.isAlarm;
      editTask.startTime = item.startTime;
      editTask.frequency = item.frequency;
      editTask.isOpen = item.isOpen;
      router.pushUrl({ url: 'pages/TaskEditPage', params: { params: JSON.stringify(editTask) } });
    }
  }

  @Builder swipeEndBuilder(item: TaskInfo) {
    Row() {
      Row() {
        Text('设置')
          .fontSize(14)
          .fontColor(Color.White)
      }
      .width(56)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.blueColor'))
      .onClick(() => {
        this.taskItemAction(item, false);
      })

      Row() {
        Text('删除')
          .fontSize(14)
          .fontColor(Color.White)
      }
      .width(56)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.primaryRed'))
      .onClick(() => {
        this.deleteTask(item);
      })
    }
    .height('100%')
  }

  deleteTask(item: TaskInfo) {
    let dateStr = item.date || dateToStr(new Date());
    let deleteInfo = new TaskInfo(item.id, dateStr, item.taskID, item.targetValue,
      item.isAlarm, item.startTime, item.endTime, item.frequency, item.isDone,
      item.finValue, false);
    TaskInfoTableApi.deleteDataByID(deleteInfo, (res: number) => {
      Logger.info('deleteTask', 'Delete result: ' + res);
      this.homeStore.dateArr = this.homeStore.dateArr.map((weekItem) => {
        if (weekItem.dateStr === dateStr) {
          weekItem.taskList = weekItem.taskList.filter((taskItem: TaskInfo) => taskItem.taskID !== item.taskID);
          if (this.homeStore.checkCurrentDay()) {
            this.homeStore.selectedDayInfo = weekItem;
          }
          return weekItem;
        }
        return weekItem;
      }).slice(0);
    });
  }

  //confirm clockL
  onConfirm(task: TaskInfo) {
    this.homeStore.taskClock(task).then((res: AchievementInfo) => {
      if (res.expGained > 0) {
        this.expGained = res.expGained;
        this.showExpPopup = true;
      }
      if (res.isLevelUp) {
        this.levelUpLevel = res.newLevel;
        setTimeout(() => {
          this.showLevelUpPopup = true;
        }, 2200);
      }
      if (res.showAchievement) {
        let achievementLevel = res.achievementLevel;
        if (achievementLevel) {
          this.broadCast.emit(BroadCastType.SHOW_ACHIEVEMENT_DIALOG, achievementLevel);
        } else {
          this.broadCast.emit(BroadCastType.SHOW_ACHIEVEMENT_DIALOG);
        }
      }
    })
  }

  // change navigator alpha when scrolling the Scroll component
  onScrollAction() {
    this.yOffset = this.scroller.currentOffset().yOffset;
    if (this.yOffset > Const.DEFAULT_56) {
      this.naviAlpha = 1;
    } else {
      this.naviAlpha = this.yOffset / Const.DEFAULT_56;
    }
  }

  editTaskAction() {
    if (this.homeStore.checkCurrentDay()) {
      router.pushUrl({ url: 'pages/TaskListPage' });
    }
  }


  getMonthProgressImg(item: WeekDateModel): Resource {
    let finNum = item.dayInfo?.finTaskNum || 0;
    let targetNum = item.dayInfo?.targetTaskNum || 0;
    if (finNum === 0) {
      return $r('app.media.ic_home_undone');
    }
    if (targetNum > 0 && finNum === targetNum) {
      return $r('app.media.ic_home_all_done');
    }
    return $r('app.media.ic_home_half_done');
  }

  @Builder
  MonthDayItem(item: WeekDateModel) {
    if (item.dateStr === '') {
      Column() {}
        .width(`${MONTH_DAY_WIDTH}%`)
        .height($r('app.float.default_48'))
    } else {
      Column({ space: Const.DEFAULT_2 }) {
        Text(item.weekTitle)
          .fontSize($r('app.float.default_12'))
          .fontWeight(Const.FONT_WEIGHT_500)
          .fontColor(sameDate(item.date, this.homeStore.showDate) ?
            $r('app.color.blueColor') : $r('app.color.titleColor'))
          .opacity(Const.OPACITY_6)
        Image(this.getMonthProgressImg(item))
          .width($r('app.float.default_24'))
          .height($r('app.float.default_24'))
          .objectFit(ImageFit.Contain)
      }
      .width(`${MONTH_DAY_WIDTH}%`)
      .height($r('app.float.default_56'))
      .justifyContent(FlexAlign.Center)
    }
  }

  @Builder
  MonthSwitchIcon(isNext: boolean) {
    Row() {
      Image($r('app.media.ic_right_grey'))
        .width($r('app.float.default_6'))
        .height($r('app.float.default_12'))
        .objectFit(ImageFit.Contain)
    }
    .width(Const.DEFAULT_32)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.Center)
    .rotate({ z: 1, angle: isNext ? 0 : Const.DEFAULT_180 })
    .opacity(isNext ? (this.homeStore.canGoNextMonth() ? 1 : Const.OPACITY_4) :
      (this.homeStore.canGoPreviousMonth() ? 1 : Const.OPACITY_4))
    .onClick(() => {
      if (isNext) {
        this.homeStore.changeMonth(1);
      } else {
        this.homeStore.changeMonth(-1);
      }
    })
  }

  @Builder
  MonthCalendarOverlay() {
    Column() {
      Row() {
        Row() {
          Text($r('app.string.cancel'))
            .fontSize($r('app.float.default_16'))
            .fontColor($r('app.color.blueColor'))
            .fontWeight(Const.FONT_WEIGHT_500)
            .height($r('app.float.default_56'))
            .padding({ left: Const.DEFAULT_24, right: Const.DEFAULT_24 })
        }
        .width($r('app.float.default_100'))
        .height($r('app.float.default_56'))
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.homeStore.closeMonthView();
        })

        Row() {
          this.MonthSwitchIcon(false)
          Text(this.homeStore.monthTitle)
            .fontSize($r('app.float.default_18'))
            .fontWeight(Const.FONT_WEIGHT_500)
            .fontColor($r('app.color.titleColor'))
            .margin({ left: Const.DEFAULT_12, right: Const.DEFAULT_12 })
          this.MonthSwitchIcon(true)
        }
        .layoutWeight(1)
        .height($r('app.float.default_56'))
        .justifyContent(FlexAlign.Center)

        Blank()
          .width($r('app.float.default_100'))
      }
      .width(Const.THOUSANDTH_1000)
      .height($r('app.float.default_56'))
      .backgroundColor($r('app.color.white'))

      Column() {
        Row() {
          ForEach(MONTH_WEEK_TITLES, (item: string) => {
            Text(item)
              .width(`${MONTH_DAY_WIDTH}%`)
              .fontSize($r('app.float.default_14'))
              .fontColor($r('app.color.titleColor'))
              .opacity(Const.OPACITY_6)
              .textAlign(TextAlign.Center)
          }, (item: string) => item)
        }
        .width(Const.THOUSANDTH_1000)
        .height($r('app.float.default_36'))

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.homeStore.monthDateArr, (item: WeekDateModel) => {
            this.MonthDayItem(item)
          }, (item: WeekDateModel) => `${item.dateStr}${item.weekTitle}`)
        }
        .width(Const.THOUSANDTH_1000)
      }
      .width(Const.THOUSANDTH_1000)
      .backgroundColor($r('app.color.white'))
      .borderRadius($r('app.float.default_24'))
      .padding({ top: Const.DEFAULT_16, bottom: Const.DEFAULT_16, left: Const.DEFAULT_8, right: Const.DEFAULT_8 })
      .margin({ top: Const.DEFAULT_16, left: Const.DEFAULT_16, right: Const.DEFAULT_16 })
    }
    .width(Const.THOUSANDTH_1000)
    .height(Const.THOUSANDTH_1000)
    .backgroundColor($r('app.color.primaryBgColor'))
    .zIndex(10)
  }

  build() {
    Stack() {
      Column() {
        HomeTopView({ homeStore: this.homeStore })
        Text($r('app.string.task_list')).titleTextStyle()
        if (this.homeStore.getTaskListOfDay().length > 0) {
          List({ space: Const.DEFAULT_8, scroller: this.scroller }) {
            ForEach(this.homeStore.getTaskListOfDay(), (item: TaskInfo) => {
              ListItem() {
                TaskCard({
                  taskInfoStr: JSON.stringify(item),
                  clickAction: (isClick: boolean) => this.taskItemAction(item, isClick)
                })
              }
              .height($r('app.float.default_88'))
              .swipeAction({
                end: {
                  builder: () => {
                    this.swipeEndBuilder(item);
                  },
                  actionAreaDistance: 112
                }
              })
            }, (item: TaskInfo) => JSON.stringify(item))
          }
          .onAppear(() => {
            this.scroller.scrollTo({ xOffset: 0, yOffset: this.yOffset });
          })
          .padding({
            left: Const.THOUSANDTH_33,
            right: Const.THOUSANDTH_33
          })
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring)
          .onScroll(() => {
            this.onScrollAction()
          })
        } else {
          Column({ space: Const.DEFAULT_8 }) {
            Image($r('app.media.ic_no_data'))
              .width($r('app.float.default_132'))
              .height($r('app.float.default_100'));
            HealthText({ title: '', titleResource: $r('app.string.no_task'), fontSize: $r('app.float.default_14') })
              .opacity(Const.OPACITY_4)
          }
          .margin({ top: Const.DEFAULT_48 })
          .layoutWeight(1)
        }
      }

      AddBtn({ clickAction: () => {
        this.editTaskAction()
      } })

      AiFloatBtn()

      Row() {
        Text($r('app.string.EntryAbility_label'))
          .titleTextStyle()
          .fontSize($r('app.float.default_24'))
          .padding({ left: Const.THOUSANDTH_66 })
      }
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_56)
      .position({ x: 0, y: 0 })
      .backgroundColor(`rgba(${WHITE_COLOR_0X},${WHITE_COLOR_0X},${WHITE_COLOR_0X},${this.naviAlpha})`)

      CustomDialogView()

      if (this.showExpPopup) {
        Column() {
          ExpGainPopup({
            expGained: this.expGained,
            onDismiss: () => {
              this.showExpPopup = false;
            }
          })
        }
        .width(Const.THOUSANDTH_1000)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.Transparent)
      }

      if (this.showLevelUpPopup) {
        Column() {
          LevelUpPopup({
            newLevel: this.levelUpLevel,
            onDismiss: () => {
              this.showLevelUpPopup = false;
            }
          })
        }
        .width(Const.THOUSANDTH_1000)
        .height(Const.THOUSANDTH_1000)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.Transparent)
      }

      if (this.homeStore.showMonthView) {
        this.MonthCalendarOverlay()
      }
    }
    .allSize()
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}


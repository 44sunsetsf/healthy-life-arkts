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
import TaskInfoTableApi from '../common/database/tables/TaskInfoApi';
import { dateToStr } from '../common/utils/Utils';
import Logger from '../common/utils/Logger';

const WHITE_COLOR_0X = 255;

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
  .fontColor($r('app.color.titleColor'))
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
      let callback: CustomDialogCallback = { confirmCallback: (taskTemp: TaskInfo) => {
        this.onConfirm(taskTemp)
      }, cancelCallback: () => {
      } };
      this.broadCast.emit(BroadCastType.SHOW_TASK_DETAIL_DIALOG, [item, callback]);
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
        let editTaskStr: string = JSON.stringify(TaskMapById[item.taskID - 1]);
        let editTask: ITaskItem = JSON.parse(editTaskStr);
        editTask.targetValue = item.targetValue;
        editTask.isAlarm = item.isAlarm;
        editTask.startTime = item.startTime;
        editTask.frequency = item.frequency;
        editTask.isOpen = item.isOpen;
        router.pushUrl({ url: 'pages/TaskEditPage', params: { params: JSON.stringify(editTask) } });
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

  build() {
    Stack() {
      Column() {
        HomeTopView({ homeStore: $homeStore })
        Text($r('app.string.task_list')).titleTextStyle()
        if (this.homeStore.getTaskListOfDay().length > 0) {
          List({ space: Const.DEFAULT_8 }) {
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
          .padding({
            left: Const.THOUSANDTH_33,
            right: Const.THOUSANDTH_33
          })
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring)
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
      .backgroundColor('rgba(' + WHITE_COLOR_0X + ',' + WHITE_COLOR_0X + ',' + WHITE_COLOR_0X + ',' + this.naviAlpha + ')')

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
    }
    .allSize()
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}


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

import prompt from '@system.prompt';
import { ITaskItem } from '../../model/TaskInitList';
import { frequencyRange } from '../../common/utils/Utils';
import { returnTimeStamp, createAppleRange, createDrinkRange, createTimesRange, createRunRange, formatTime } from '../../viewmodel/TaskViewModel';
import { taskType } from '../../viewmodel/TaskInfo';
import { CommonConstants as Const } from '../..//common/constants/CommonConstants';
import { FrequencyContentType } from '../../model/TaskInitList';

@CustomDialog
export struct TargetSettingDialog {
  @Consume settingParams: ITaskItem;
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  drinkRange: string[] = createDrinkRange();
  appleRange: string[] = createAppleRange();
  timesRange: string[] = createTimesRange();
  runRange: string[] = createRunRange();
  currentValue: string = this.settingParams.targetValue;
  currentTime: string = Const.DEFAULT_TIME;

  compareTime(startTime: string, endTime: string) {
    if (returnTimeStamp(this.currentTime) < returnTimeStamp(startTime) ||
    returnTimeStamp(this.currentTime) > returnTimeStamp(endTime)) {
      prompt.showToast({
        message: Const.CHOOSE_TIME_OUT_RANGE
      })
      return false;
    }
    return true;
  }

  setTargetValue() {
    if (this.settingParams?.taskID === taskType.getup) {
      if (!this.compareTime(Const.GET_UP_EARLY_TIME, Const.GET_UP_LATE_TIME)) {
        return;
      }
      this.settingParams.targetValue = this.currentTime;
      return;
    }
    if (this.settingParams?.taskID === taskType.sleepEarly) {
      if (!this.compareTime(Const.SLEEP_EARLY_TIME, Const.SLEEP_LATE_TIME)) {
        return;
      }
      this.settingParams.targetValue = this.currentTime;
      return;
    }
    this.settingParams.targetValue = this.currentValue;
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.target_setting')).fontSize(Const.DEFAULT_20).margin({ right: Const.DEFAULT_12 })
        Text(this.settingParams?.taskID === taskType.getup ?
        Const.GET_UP_TIME_RANGE :
            this.settingParams?.taskID === taskType.sleepEarly ?
          Const.SLEEP_TIME_RANGE : '')
          .fontSize(Const.DEFAULT_16)
      }
      .width(Const.THOUSANDTH_1000)
      .justifyContent(FlexAlign.Start)

      if ([taskType.getup, taskType.sleepEarly].indexOf(this.settingParams?.taskID) > Const.HAS_NO_INDEX) {
        TimePicker({
          selected: new Date(`${new Date().toDateString()} 8:00:00`),
        })
          .height(Const.THOUSANDTH_800)
          .useMilitaryTime(true)
          .onChange((value: TimePickerResult) => {
            this.currentTime = formatTime(value);
          })
      } else if (this.settingParams?.taskID === taskType.drinkWater) {
        TextPicker({ range: this.drinkRange })
          .width(Const.THOUSANDTH_900,)
          .height(Const.THOUSANDTH_800,)
          .onChange((value) => {
            this.currentValue =  (value as string)?.split(' ')[0];
          })
      } else if (this.settingParams?.taskID === taskType.run) {
        TextPicker({ range: this.runRange })
          .width(Const.THOUSANDTH_900,)
          .height(Const.THOUSANDTH_800,)
          .onChange((value) => {
            this.currentValue =  (value as string)?.split(' ')[0];
          })
      } else if (this.settingParams?.taskID === taskType.smile || this.settingParams?.taskID === taskType.brushTeeth) {
        TextPicker({ range: this.timesRange })
          .width(Const.THOUSANDTH_900,)
          .height(Const.THOUSANDTH_800,)
          .onChange((value) => {
            this.currentValue =  (value as string)?.split(' ')[0];
          })
      } else {
        TextPicker({ range: this.appleRange })
          .width(Const.THOUSANDTH_900,)
          .height(Const.THOUSANDTH_800,)
          .onChange((value) => {
            this.currentValue =  (value as string)?.split(' ')[0];
          })
      }

      Row() {
        Text($r('app.string.cancel')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.currentTime = Const.DEFAULT_TIME;
            this.currentValue = '';
            this.controller.close();
          })

        Text($r('app.string.confirm')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.setTargetValue();
            this.controller.close();
          })
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_28)
      .margin({ bottom: Const.DEFAULT_20 })
    }
    .justifyContent(FlexAlign.Center)
    .height(Const.THOUSANDTH_560)
    .padding(Const.DEFAULT_12)
  }
}

@CustomDialog
export struct RemindTimeDialog {
  @Consume settingParams: ITaskItem;
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @State timeList: string[] = [];

  aboutToAppear() {
    this.initTimeList();
  }

  initTimeList() {
    let target: number = parseInt(this.settingParams?.targetValue) || 1;
    let existingTimes: string[] = this.settingParams?.startTime ?
      this.settingParams.startTime.split(',').map(t => t.trim()) : [];
    this.timeList = [];
    for (let i = 0; i < target; i++) {
      this.timeList.push(existingTimes[i] || Const.DEFAULT_TIME);
    }
  }

  build() {
    Column() {
      Column() {
        Text($r('app.string.remind_time'))
          .fontSize(Const.DEFAULT_20)
          .margin({ top: Const.DEFAULT_10 })
          .width(Const.THOUSANDTH_1000)
          .textAlign(TextAlign.Start)
      }
      .width(Const.THOUSANDTH_900)

      Scroll() {
        Column() {
          ForEach(this.timeList, (time: string, index: number) => {
            Column() {
              Text(`提醒 ${index + 1}`)
                .fontSize(Const.DEFAULT_16)
                .fontColor($r('app.color.titleColor'))
                .padding({ top: Const.DEFAULT_10, bottom: Const.DEFAULT_6 })

              TimePicker({
                selected: new Date(`${new Date().toDateString()} ${time}`),
              })
                .height(Const.THOUSANDTH_400)
                .useMilitaryTime(true)
                .onChange((value: TimePickerResult) => {
                  this.timeList[index] = formatTime(value);
                })
            }
            .width(Const.THOUSANDTH_1000)
          }, (item: string, index: number) => `${index}`)
        }
        .width(Const.THOUSANDTH_1000)
      }
      .flexGrow(1)

      Row() {
        Text($r('app.string.cancel')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })

        Text($r('app.string.confirm')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.settingParams.startTime = this.timeList.join(',');
            this.controller.close();
          })
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width(Const.THOUSANDTH_1000)
      .height(Const.DEFAULT_28)
      .margin({ bottom: Const.DEFAULT_20 })
    }
    .justifyContent(FlexAlign.Center)
    .height(Const.THOUSANDTH_900)
    .padding(Const.DEFAULT_12)
  }
}

@CustomDialog
export struct FrequencyDialog {
  @Consume settingParams: ITaskItem;
  @Consume frequency: string;
  private controller: CustomDialogController = new CustomDialogController({ builder: '' });
  private currentFrequency: string = Const.EVERYDAY;
  private frequencyChooseRange: FrequencyContentType[] = FrequencyDialog.initFrequencyChooseRange(this.settingParams?.frequency);

  static initFrequencyChooseRange(frequencyStr: string): FrequencyContentType[] {
    const range = frequencyRange();
    if (!frequencyStr || frequencyStr === '') {
      return range;
    }
    const selectedIds = frequencyStr.split(',').map(item => Number(item.trim()));
    range.forEach((item) => {
      if (selectedIds.includes(item.id)) {
        item.isChecked = true;
      }
    });
    return range;
  }

  setFrequency() {
    const checkedArr = this.frequencyChooseRange.filter((item) => item?.isChecked)
    if (checkedArr.length === this.frequencyChooseRange.length || checkedArr.length === Const.NO_LENGTH) {
      this.currentFrequency = Const.EVERYDAY;
      this.settingParams.frequency = Const.INIT_WEEK_IDS;
      return;
    }
    this.currentFrequency = checkedArr.reduce((sum, current) => {
      return sum + ' ' + current?.label;
    }, '')
    this.settingParams.frequency = checkedArr.reduce((sum, current) => {
      return sum === '' ? sum + current?.id : sum + ',' + current?.id;
    }, '')
  }

  build() {
    Column() {
      Column() {
        Text($r('app.string.set_your_frequency'))
          .fontSize(Const.DEFAULT_20)
          .margin({ top: Const.DEFAULT_10 })
          .width(Const.THOUSANDTH_1000)
          .textAlign(TextAlign.Start)
      }
      .width(Const.THOUSANDTH_900)

      List() {
        ForEach(this.frequencyChooseRange, (item: FrequencyContentType) => {
          ListItem() {
            Row() {
              Text(item?.label).fontSize(Const.DEFAULT_20)
              Toggle({ type: ToggleType.Checkbox, isOn: item.isChecked })
                .onChange((isOn) => {
                  item.isChecked = isOn;
                })
            }
            .width(Const.THOUSANDTH_1000)
            .justifyContent(FlexAlign.SpaceBetween)
            .height(Const.DEFAULT_60)
          }
        }, (item: FrequencyContentType) => JSON.stringify(item))
      }
      .divider({
        strokeWidth: Const.DEFAULT_2,
        color: $r('app.color.btnBgColor')
      })
      .flexGrow(1)
      .padding(Const.DEFAULT_12)
      .width(Const.THOUSANDTH_1000)

      Row() {
        Text($r('app.string.cancel')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })

        Text($r('app.string.confirm')).fontSize(Const.DEFAULT_20).fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.setFrequency();
            this.frequency = this.currentFrequency;
            this.controller.close();
          })
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width(Const.THOUSANDTH_900)
      .height(Const.DEFAULT_28)
      .margin({ bottom: Const.DEFAULT_16 })
    }
    .justifyContent(FlexAlign.Center)
    .height(Const.THOUSANDTH_900)
    .padding(Const.DEFAULT_12)
  }
}
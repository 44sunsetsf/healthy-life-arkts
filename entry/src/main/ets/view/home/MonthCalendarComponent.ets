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

import { HomeStore } from '../../viewmodel/HomeViewModel';
import { WeekDateModel } from '../../model/WeekCalendarModel';
import { sameDate } from '../../common/utils/Utils';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';

const MONTH_WEEK_TITLES: string[] = ['一', '二', '三', '四', '五', '六', '日'];
const MONTH_ROWS: number[] = [0, 1, 2, 3, 4, 5];
const MONTH_COLUMNS: number[] = [0, 1, 2, 3, 4, 5, 6];
const HISTORY_MONTH_COUNT: number = 6;

@Component
export struct MonthCalendar {
  @Link homeStore: HomeStore;
  @State browseMonthTime: number = new Date().getTime();
  @State selectedMonthDayTime: number = new Date().getTime();
  closeAction: Function = () => {};

  aboutToAppear(): void {
    let initMonth = this.clampMonthDate(new Date(this.homeStore.showDate));
    this.browseMonthTime = initMonth.getTime();
    this.selectedMonthDayTime = new Date(this.homeStore.showDate).getTime();
    this.loadMonthData(initMonth);
    this.homeStore.preloadMonthHistoryData((): void => {
      this.loadMonthData(new Date(this.browseMonthTime));
    });
  }

  getMonthTitle(): string {
    let date = new Date(this.browseMonthTime);
    return `${date.getFullYear()}年${date.getMonth() + 1}月`;
  }

  getCurrentMonthStart(): Date {
    let date = new Date();
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }

  getMinMonthStart(): Date {
    let currentMonth = this.getCurrentMonthStart();
    return new Date(currentMonth.getFullYear(), currentMonth.getMonth() - HISTORY_MONTH_COUNT, 1);
  }

  getMonthStart(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }

  clampMonthDate(date: Date): Date {
    let monthStart = this.getMonthStart(date);
    let minMonth = this.getMinMonthStart();
    let maxMonth = this.getCurrentMonthStart();
    if (monthStart.getTime() < minMonth.getTime()) {
      return minMonth;
    }
    if (monthStart.getTime() > maxMonth.getTime()) {
      return maxMonth;
    }
    return monthStart;
  }

  canGoPreviousMonth(): boolean {
    return this.getMonthStart(new Date(this.browseMonthTime)).getTime() > this.getMinMonthStart().getTime();
  }

  canGoNextMonth(): boolean {
    return this.getMonthStart(new Date(this.browseMonthTime)).getTime() < this.getCurrentMonthStart().getTime();
  }

  loadMonthData(date: Date): void {
    this.homeStore.getMonthData(date, (): void => {});
  }

  goToPreviousMonth(): void {
    if (!this.canGoPreviousMonth()) {
      return;
    }
    let date = new Date(this.browseMonthTime);
    date.setMonth(date.getMonth() - 1);
    let targetMonth = this.clampMonthDate(date);
    this.browseMonthTime = targetMonth.getTime();
    this.selectedMonthDayTime = targetMonth.getTime();
    this.loadMonthData(targetMonth);
  }

  goToNextMonth(): void {
    if (!this.canGoNextMonth()) {
      return;
    }
    let date = new Date(this.browseMonthTime);
    date.setMonth(date.getMonth() + 1);
    let targetMonth = this.clampMonthDate(date);
    this.browseMonthTime = targetMonth.getTime();
    this.selectedMonthDayTime = targetMonth.getTime();
    this.loadMonthData(targetMonth);
  }

  isDateSelectable(item: WeekDateModel): boolean {
    return item.date.getTime() <= new Date().getTime() &&
      item.date.getTime() >= this.getMinMonthStart().getTime();
  }

  isSelectedMonthDay(item: WeekDateModel): boolean {
    return sameDate(item.date, this.selectedMonthDayTime);
  }

  getProgressImg(item: WeekDateModel): Resource {
    let finNum = item.dayInfo?.finTaskNum || 0;
    if (finNum === 0) {
      return $r('app.media.ic_home_undone');
    }
    if (finNum >= (item.dayInfo?.targetTaskNum || 0)) {
      return $r('app.media.ic_home_all_done');
    }
    return $r('app.media.ic_home_half_done');
  }

  selectDate(item: WeekDateModel): void {
    if (!this.isDateSelectable(item)) {
      return;
    }
    this.selectedMonthDayTime = item.date.getTime();
    this.homeStore.selectedDay = (item.date.getDay() + Const.WEEK_DAY_NUM - 1) % Const.WEEK_DAY_NUM;
    this.homeStore.setSelectedShowDate(item.date.getTime());
    this.homeStore.updateSelectedDayInfo(item);
    this.closeAction();
  }

  @Builder MonthArrowIcon(isRight: boolean, isEnabled: boolean) {
    Row() {
      Image($r('app.media.ic_right_grey'))
        .width($r('app.float.default_6'))
        .height($r('app.float.default_12'))
    }
    .width($r('app.float.default_24'))
    .height($r('app.float.default_24'))
    .rotate({ z: 1, angle: isRight ? 0 : Const.DEFAULT_180 })
    .justifyContent(FlexAlign.Center)
    .opacity(isEnabled ? 1 : Const.OPACITY_4)
    .onClick((): void => {
      if (isRight) {
        this.goToNextMonth();
      } else {
        this.goToPreviousMonth();
      }
    })
  }

  @Builder MonthDay(item: WeekDateModel) {
    Column({ space: Const.DEFAULT_8 }) {
      Text(`${item.date.getDate()}`)
        .fontSize($r('app.float.default_14'))
        .fontWeight(this.isSelectedMonthDay(item) ? Const.FONT_WEIGHT_700 : Const.FONT_WEIGHT_400)
        .fontColor(this.isSelectedMonthDay(item) ?
          $r('app.color.blueColor') : $r('app.color.titleColor'))
        .opacity(item.isCurrentMonth && this.isDateSelectable(item) ? 1 : Const.OPACITY_4)
      Image(this.getProgressImg(item))
        .width($r('app.float.default_24'))
        .height($r('app.float.default_24'))
        .objectFit(ImageFit.Contain)
        .opacity(item.isCurrentMonth && this.isDateSelectable(item) ? 1 : Const.OPACITY_4)
    }
    .width(`${100 / Const.WEEK_DAY_NUM}%`)
    .height($r('app.float.default_56'))
    .justifyContent(FlexAlign.Center)
    .onClick((): void => this.selectDate(item))
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.cancel'))
          .fontSize($r('app.float.default_16'))
          .fontColor($r('app.color.blueColor'))
          .onClick((): void => this.closeAction())
        Row() {
          this.MonthArrowIcon(false, this.canGoPreviousMonth())
          Text(this.getMonthTitle())
            .fontSize($r('app.float.default_20'))
            .fontWeight(Const.FONT_WEIGHT_700)
            .fontColor($r('app.color.titleColor'))
            .textAlign(TextAlign.Center)
            .margin({ left: Const.DEFAULT_8, right: Const.DEFAULT_8 })
          this.MonthArrowIcon(true, this.canGoNextMonth())
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        Blank()
          .width($r('app.float.default_48'))
      }
      .height($r('app.float.default_56'))
      .width(Const.THOUSANDTH_1000)
      .padding({ left: Const.DEFAULT_20, right: Const.DEFAULT_20 })

      Row() {
        ForEach(MONTH_WEEK_TITLES, (item: string) => {
          Text(item)
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.statusTipColor'))
            .textAlign(TextAlign.Center)
            .width(`${100 / Const.WEEK_DAY_NUM}%`)
        }, (item: string) => item)
      }
      .width(Const.THOUSANDTH_1000)
      .padding({ left: Const.DEFAULT_20, right: Const.DEFAULT_20 })

      Column({ space: Const.DEFAULT_8 }) {
        ForEach(MONTH_ROWS, (row: number) => {
          Row() {
            ForEach(MONTH_COLUMNS, (column: number) => {
              if (this.homeStore.monthDateArr[row * Const.WEEK_DAY_NUM + column]) {
                this.MonthDay(this.homeStore.monthDateArr[row * Const.WEEK_DAY_NUM + column])
              } else {
                Blank()
                  .width(`${100 / Const.WEEK_DAY_NUM}%`)
                  .height($r('app.float.default_56'))
              }
            }, (column: number) => `${row}-${column}`)
          }
          .width(Const.THOUSANDTH_1000)
        }, (row: number) => `${row}`)
      }
      .width(Const.THOUSANDTH_1000)
      .padding({ left: Const.DEFAULT_20, right: Const.DEFAULT_20, top: Const.DEFAULT_16 })
    }
    .width(Const.THOUSANDTH_1000)
    .height(Const.THOUSANDTH_1000)
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}
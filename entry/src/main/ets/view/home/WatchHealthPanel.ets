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
import { HomeStore } from '../../viewmodel/HomeViewModel';
import { WatchHealthData } from '../../viewmodel/WatchHealthData';
import { WatchSyncResult } from '../../viewmodel/WatchSyncResult';
import { HealthDataSrcMgr } from '../../common/utils/HealthDataSrcMgr';
import { BroadCast, BroadCastType } from '../../common/utils/BroadCast';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import Logger from '../../common/utils/Logger';

const MINUTES_OF_HOUR: number = 60;
const NO_DATA_PLACEHOLDER: string = '--';

@Component
export default struct WatchHealthPanel {
  @Link homeStore: HomeStore;
  @Consume broadCast: BroadCast;
  @State healthData: WatchHealthData | null = null;
  @State stepsText: string = NO_DATA_PLACEHOLDER;
  @State heartRateText: string = NO_DATA_PLACEHOLDER;
  @State sleepText: string = NO_DATA_PLACEHOLDER;
  @State isSyncing: boolean = false;

  aboutToAppear(): void {
    if (this.homeStore.watchHealthData) {
      this.updateDisplayData(this.homeStore.watchHealthData);
    } else {
      this.resetDisplayData();
    }
  }

  syncAction(): void {
    if (this.isSyncing) {
      return;
    }
    this.isSyncing = true;
    HealthDataSrcMgr.getInstance().getHealthDataSource().getTodayHealthData()
      .then((data: WatchHealthData | null) => {
        if (data === null) {
          this.isSyncing = false;
          prompt.showToast({ message: Const.WATCH_SYNC_FAILED });
          return;
        }
        this.updateDisplayData(data);
        this.syncToTasks(data);
      })
      .catch(() => {
        this.isSyncing = false;
        Logger.error('WatchHealthPanel', 'getTodayHealthData failed.');
        prompt.showToast({ message: Const.WATCH_SYNC_FAILED });
      });
  }

  syncToTasks(data: WatchHealthData): void {
    this.homeStore.syncWatchData(data)
      .then((res: WatchSyncResult) => {
        this.updateDisplayData(data);
        this.isSyncing = false;
        prompt.showToast({ message: res.message });
        if (res.showAchievement) {
          if (res.achievementLevel) {
            this.broadCast.emit(BroadCastType.SHOW_ACHIEVEMENT_DIALOG, res.achievementLevel);
          } else {
            this.broadCast.emit(BroadCastType.SHOW_ACHIEVEMENT_DIALOG);
          }
        }
      })
      .catch(() => {
        this.isSyncing = false;
        Logger.error('WatchHealthPanel', 'syncWatchData failed.');
        prompt.showToast({ message: Const.WATCH_SYNC_FAILED });
      });
  }

  updateDisplayData(data: WatchHealthData): void {
    this.healthData = data;
    this.homeStore.watchHealthData = data;
    this.stepsText = `${data.steps}`;
    this.heartRateText = `${data.heartRate}`;
    this.sleepText = (data.sleepDurationMinutes / MINUTES_OF_HOUR).toFixed(1);
  }

  resetDisplayData(): void {
    this.healthData = null;
    this.stepsText = NO_DATA_PLACEHOLDER;
    this.heartRateText = NO_DATA_PLACEHOLDER;
    this.sleepText = NO_DATA_PLACEHOLDER;
  }

  build() {
    Column({ space: Const.DEFAULT_12 }) {
      Row() {
        Text($r('app.string.watch_panel_title'))
          .fontSize($r('app.float.default_16'))
          .fontWeight(Const.FONT_WEIGHT_500)
          .fontColor($r('app.color.titleColor'))
          .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
        Blank()
        Button($r('app.string.watch_sync_button'))
          .fontSize($r('app.float.default_12'))
          .height($r('app.float.default_28'))
          .backgroundColor($r('app.color.blueColor'))
          .enabled(!this.isSyncing)
          .onClick(() => this.syncAction())
      }
      .width(Const.THOUSANDTH_1000)

      Row() {
        Column({ space: Const.SPACE_4 }) {
          Text(this.stepsText)
            .fontSize($r('app.float.default_24'))
            .fontWeight(Const.FONT_WEIGHT_500)
            .fontColor($r('app.color.titleColor'))
            .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
          Text($r('app.string.watch_steps'))
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.titleColor'))
            .opacity(Const.OPACITY_6)
        }

        Column({ space: Const.SPACE_4 }) {
          Text(this.heartRateText)
            .fontSize($r('app.float.default_24'))
            .fontWeight(Const.FONT_WEIGHT_500)
            .fontColor($r('app.color.titleColor'))
            .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
          Text($r('app.string.watch_heart_rate'))
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.titleColor'))
            .opacity(Const.OPACITY_6)
        }

        Column({ space: Const.SPACE_4 }) {
          Text(this.sleepText)
            .fontSize($r('app.float.default_24'))
            .fontWeight(Const.FONT_WEIGHT_500)
            .fontColor($r('app.color.titleColor'))
            .fontFamily($r('app.string.HarmonyHeiTi_Medium'))
          Text($r('app.string.watch_sleep_duration'))
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.titleColor'))
            .opacity(Const.OPACITY_6)
        }
      }
      .width(Const.THOUSANDTH_1000)
      .justifyContent(FlexAlign.SpaceAround)

      if (this.healthData === null) {
        Text($r('app.string.watch_no_data'))
          .fontSize($r('app.float.default_12'))
          .fontColor($r('app.color.titleColor'))
          .opacity(Const.OPACITY_4)
      }
    }
    .width(Const.THOUSANDTH_1000)
    .padding($r('app.float.default_16'))
    .borderRadius($r('app.float.default_24'))
    .backgroundColor($r('app.color.white'))
  }
}

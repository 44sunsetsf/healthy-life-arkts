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

import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { TitleBar } from './TitleBarComponent';
import { AchievementMap, TaskMapById } from '../model/TaskInitList';
import { getAchievementLevel, ACHIEVEMENT_LEVEL_KEY } from '../model/AchieveModel';
import { AchievementInfoDialog } from './dialog/AchievementInfoDialog';
import { TaskAchievementStats, PercentRecordInfo } from '../viewmodel/AchievementStatsInfo';
import {
  FULL_ATTENDANCE_MILESTONES,
  TROPHY_LEVEL_STEPS,
  OVER_ACHIEVE_PERCENTS,
  OVER_ACHIEVE_TASK_IDS,
  getTrophyLevel,
  getTrophyProgress,
  getTrophyIcon,
  getPercentIcon,
  loadTaskStats,
  loadOverAchieveRecords
} from '../model/AchievementStatsModel';
import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';
import GlobalInfo from '../viewmodel/GlobalInfo';
import { ratio2percent, padTo2Digits } from '../common/utils/Utils';
import Logger from '../common/utils/Logger';

const SUB_TEXT_COLOR: string = '#99FFFFFF';
const CARD_BG_COLOR: string = '#1AFFFFFF';
const PROGRESS_COLOR: string = '#F6CD5C';
const MINI_BADGE_SIZE: number = 40;
const PERCENT_BADGE_WIDTH: string = '17%';
const UNIT_DAY: string = '天';
const UNIT_TIME: string = '次';

const RULE_FULL_TITLE: string = '健康全勤规则';
const RULE_FULL_CONTENT: string = '完成今日全部已启用任务，才计入 1 天健康全勤。\n达到 3、7、30、50、99 天可点亮里程碑奖章。\n达到 100 天后开启成长奖杯。\n\n成长奖杯等级：\nLV1：100 天\nLV2：300 天\nLV3：500 天\nLV4：1000 天';
const RULE_TASK_TITLE: string = '任务达成规则';
const RULE_TASK_CONTENT: string = '每个任务都会独立统计连续达成次数。\n任务在应执行日完成目标，即连续达成 +1。\n非执行日不计入，也不会影响连续统计。\n\n每个任务都有 3、7、30、50、99 和成长奖杯。';
const RULE_OVER_TITLE: string = '超额成就规则';
const RULE_OVER_CONTENT: string = '100% 表示目标达成。\n200%、300%、400%、500% 表示超额达成。\n超额奖章达成一次后永久保留。';

const EMPTY_FULL: string = '完成今日全部任务后，就可以开始点亮健康全勤奖章。';
const EMPTY_TASK: string = '完成单个任务目标后，就可以点亮对应任务奖章。';
const EMPTY_OVER: string = '任务完成量达到目标的 100% 后，将点亮目标达成奖章。';

// taskID -> 任务名（下标 0 占位）
const TASK_NAMES: string[] = ['', Const.GET_UP_TASK_NAME, Const.DRINK_TASK_NAME, Const.EAT_APPLE_TASK_NAME,
  Const.SMILE_TASK_NAME, Const.BRUSH_TEETH_TASK_NAME, Const.SLEEP_TASK_NAME];

@Component
export struct AchievementIndex {
  @StorageProp(ACHIEVEMENT_LEVEL_KEY) successiveDays: number = 0;
  @State currentTab: number = 0;
  @State checkInDays: number = 0;
  @State taskStatsList: TaskAchievementStats[] = [];
  @State percentRecords: PercentRecordInfo[] = [];
  @State dialogTitle: string = '';
  @State dialogContent: string = '';
  infoDialog: CustomDialogController = new CustomDialogController({
    builder: AchievementInfoDialog({ dialogTitle: $dialogTitle, dialogContent: $dialogContent }),
    autoCancel: true,
    customStyle: true
  });

  aboutToAppear() {
    Logger.debug('AchievementIndex', 'aboutToAppear');
    this.refreshData();
  }

  refreshData(): void {
    getAchievementLevel();
    GlobalInfoApi.query((res: GlobalInfo) => {
      this.checkInDays = res?.checkInDays || 0;
    });
    loadTaskStats((stats: TaskAchievementStats[]) => {
      this.taskStatsList = stats;
    });
    loadOverAchieveRecords(getContext(this), (records: PercentRecordInfo[]) => {
      this.percentRecords = records;
    });
  }

  getBadgeIcon(milestone: number, lit: boolean): Resource {
    let result = $r('app.string.empty');
    switch (milestone) {
      case 3:
        result = lit ? AchievementMap.on_3 : AchievementMap.off_3;
        break;
      case 7:
        result = lit ? AchievementMap.on_7 : AchievementMap.off_7;
        break;
      case 30:
        result = lit ? AchievementMap.on_30 : AchievementMap.off_30;
        break;
      case 50:
        result = lit ? AchievementMap.on_50 : AchievementMap.off_50;
        break;
      case 99:
        result = lit ? AchievementMap.on_99 : AchievementMap.off_99;
        break;
      default:
        break;
    }
    return result;
  }

  getVisibleTaskStats(): TaskAchievementStats[] {
    return this.taskStatsList.filter((stats: TaskAchievementStats) => stats.hasAnyRecord);
  }

  getOverTaskStats(): TaskAchievementStats[] {
    return this.taskStatsList.filter((stats: TaskAchievementStats) =>
      stats.hasAnyRecord && OVER_ACHIEVE_TASK_IDS.indexOf(stats.taskID) >= 0);
  }

  getUnitText(stats: TaskAchievementStats): string {
    return stats.isDaily ? UNIT_DAY : UNIT_TIME;
  }

  getStreakText(stats: TaskAchievementStats): string {
    return `当前连续达成：${stats.streak} ${this.getUnitText(stats)}`;
  }

  getTodayStateText(stats: TaskAchievementStats): string {
    if (!stats.todayHasTask) {
      return '今日无该任务';
    }
    return stats.todayDone ? '今日已完成' : '今日未完成';
  }

  getMaxPercent(stats: TaskAchievementStats): number {
    let max = stats.firstDoneDate !== '' ? 100 : 0;
    this.percentRecords.forEach((record: PercentRecordInfo) => {
      if (record.taskID === stats.taskID && record.percent > max) {
        max = record.percent;
      }
    });
    return max;
  }

  findPercentRecord(stats: TaskAchievementStats, percent: number): PercentRecordInfo | null {
    let found: PercentRecordInfo | null = null;
    this.percentRecords.forEach((record: PercentRecordInfo) => {
      if (record.taskID === stats.taskID && record.percent === percent) {
        found = record;
      }
    });
    if (found === null && percent === 100 && stats.firstDoneDate !== '') {
      // 100% 达成信息可直接由历史打卡记录推导
      let record = new PercentRecordInfo();
      record.taskID = stats.taskID;
      record.percent = 100;
      record.firstDate = stats.firstDoneDate;
      record.targetValue = stats.firstDoneTarget;
      record.finValue = stats.firstDoneFin;
      found = record;
    }
    return found;
  }

  getTaskUnit(taskID: number): string {
    return TaskMapById[taskID - 1]?.unit || '';
  }

  formatDateStr(dateStr: string): string {
    let date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      return dateStr;
    }
    return `${date.getFullYear()}-${padTo2Digits(date.getMonth() + 1)}-${padTo2Digits(date.getDate())}`;
  }

  trophyStageLabel(count: number): string {
    let progress = getTrophyProgress(count);
    if (progress.isMax) {
      return '已满级';
    }
    if (progress.level === 0) {
      return `未获得 → LV1`;
    }
    return `LV${progress.level} → LV${progress.level + 1}`;
  }

  trophyProgressText(count: number): string {
    let progress = getTrophyProgress(count);
    if (progress.isMax) {
      return `已达到最高等级 · 当前 ${count}`;
    }
    return `${progress.progressCurrent} / ${progress.progressTotal}`;
  }

  buildTrophyDialogContent(count: number, unit: string): string {
    let content = `等级规则：\nLV1：${TROPHY_LEVEL_STEPS[0]} ${unit}\nLV2：${TROPHY_LEVEL_STEPS[1]} ${unit}\n` +
      `LV3：${TROPHY_LEVEL_STEPS[2]} ${unit}\nLV4：${TROPHY_LEVEL_STEPS[3]} ${unit}\n\n当前连续达成：${count} ${unit}\n`;
    let progress = getTrophyProgress(count);
    if (progress.isMax) {
      content += '当前等级：LV4\n已达到最高等级';
    } else if (progress.level === 0) {
      content += `当前等级：未获得\n下一等级：LV1\n距离开启还差：${progress.progressTotal - progress.progressCurrent} ${unit}`;
    } else {
      content += `当前等级：LV${progress.level}\n下一等级：LV${progress.level + 1}\n` +
        `距离升级还差：${progress.progressTotal - progress.progressCurrent} ${unit}`;
    }
    return content;
  }

  openDialog(title: string, content: string): void {
    this.dialogTitle = title;
    this.dialogContent = content;
    this.infoDialog.open();
  }

  showMilestoneDialog(milestone: number): void {
    let lit = this.successiveDays >= milestone;
    let title = `连续${milestone}天全勤`;
    if (lit) {
      this.openDialog(title,
        `达成条件：\n连续${milestone}天完成今日全部任务。\n\n当前状态：已点亮\n当前连续全勤：${this.checkInDays} 天`);
    } else {
      let progress = Math.min(this.checkInDays, milestone);
      this.openDialog(title,
        `达成条件：\n连续${milestone}天完成今日全部任务。\n\n当前进度：${progress} / ${milestone}\n还差：${milestone - progress} 天`);
    }
  }

  showFullTrophyDialog(): void {
    this.openDialog('全勤成长奖杯',
      `完成今日全部任务，才计入 1 天健康全勤。\n\n${this.buildTrophyDialogContent(this.checkInDays, UNIT_DAY)}`);
  }

  showTaskMilestoneDialog(stats: TaskAchievementStats, milestone: number): void {
    let name = TASK_NAMES[stats.taskID];
    let unit = this.getUnitText(stats);
    let title = `${name}连续 ${milestone} ${unit}达成`;
    if (stats.streak >= milestone) {
      this.openDialog(title,
        `达成条件：\n${name}任务连续 ${milestone} 个执行日达到目标。\n\n当前状态：已点亮\n当前连续达成：${stats.streak} ${unit}`);
    } else {
      this.openDialog(title,
        `达成条件：\n${name}任务连续 ${milestone} 个执行日达到目标。\n\n当前进度：${stats.streak} / ${milestone}\n还差：${milestone - stats.streak} ${unit}`);
    }
  }

  showTaskTrophyDialog(stats: TaskAchievementStats): void {
    let name = TASK_NAMES[stats.taskID];
    this.openDialog(`${name}成长奖杯`, this.buildTrophyDialogContent(stats.streak, this.getUnitText(stats)));
  }

  showPercentDialog(stats: TaskAchievementStats, percent: number): void {
    let name = TASK_NAMES[stats.taskID];
    let unit = this.getTaskUnit(stats.taskID);
    let title = `${name} ${percent}% 达成`;
    let record = this.findPercentRecord(stats, percent);
    if (record !== null) {
      this.openDialog(title,
        `首次达成：${this.formatDateStr(record.firstDate)}\n当日目标：${record.targetValue} ${unit}\n` +
        `实际完成：${record.finValue} ${unit}\n完成比例：${percent}%`);
    } else if (percent <= this.getMaxPercent(stats)) {
      this.openDialog(title, `达成条件：\n单日${name}完成量达到目标的 ${percent}%。\n\n当前状态：已点亮`);
    } else {
      this.openDialog(title, `达成条件：\n单日${name}完成量达到目标的 ${percent}%。\n\n当前状态：未点亮`);
    }
  }

  @Builder TabItem(index: number, label: Resource) {
    Column({ space: Const.SPACE_4 }) {
      Text(label)
        .fontSize($r('app.float.default_16'))
        .fontColor(this.currentTab === index ? $r('app.color.white') : SUB_TEXT_COLOR)
        .fontWeight(this.currentTab === index ? Const.FONT_WEIGHT_500 : Const.FONT_WEIGHT_400)
      Row()
        .width(Const.DEFAULT_24)
        .height(3)
        .borderRadius(Const.DEFAULT_2)
        .backgroundColor(this.currentTab === index ? PROGRESS_COLOR : Color.Transparent)
    }
    .onClick(() => {
      this.currentTab = index;
      this.refreshData();
    })
  }

  @Builder DescLine(desc: string, ruleTitle: string, ruleContent: string) {
    Row({ space: Const.DEFAULT_8 }) {
      Text(desc)
        .fontSize($r('app.float.default_12'))
        .fontColor(SUB_TEXT_COLOR)
        .layoutWeight(1)
      Text('ⓘ')
        .fontSize($r('app.float.default_14'))
        .fontColor(SUB_TEXT_COLOR)
        .onClick(() => this.openDialog(ruleTitle, ruleContent))
    }
    .width(Const.FULL_WIDTH)
    .padding({ left: Const.ACHIEVE_TITLE_BAR_LEFT, right: Const.ACHIEVE_TITLE_BAR_LEFT, top: Const.DEFAULT_12 })
  }

  @Builder EmptyHint(text: string) {
    Text(text)
      .fontSize($r('app.float.default_12'))
      .fontColor(SUB_TEXT_COLOR)
      .width(Const.FULL_WIDTH)
      .textAlign(TextAlign.Center)
      .margin({ top: Const.DEFAULT_48 })
  }

  @Builder FullAttendanceContent() {
    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
      ForEach(FULL_ATTENDANCE_MILESTONES, (milestone: number) => {
        Column({ space: Const.DEFAULT_18 }) {
          Image(this.getBadgeIcon(milestone, this.successiveDays >= milestone))
            .width(Const.FULL_WIDTH)
            .height(Const.ACHIEVE_CARD_IMG_HEIGHT)
            .objectFit(ImageFit.Contain)
          Text($r('app.string.full_attendance_level', milestone))
            .lineHeight($r('app.float.default_16'))
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.white'))
        }
        .width(ratio2percent(Const.ACHIEVE_SPLIT_RATIO))
        .padding({ top: Const.ACHIEVE_CARD_TOP, bottom: Const.ACHIEVE_CARD_BOTTOM })
        .onClick(() => this.showMilestoneDialog(milestone))
      }, (milestone: number) => `full_${milestone}_${this.successiveDays}`)

      Column({ space: Const.SPACE_4 }) {
        Image(getTrophyIcon(getTrophyLevel(this.checkInDays)))
          .width(Const.FULL_WIDTH)
          .height(Const.ACHIEVE_CARD_IMG_HEIGHT)
          .objectFit(ImageFit.Contain)
        Text($r('app.string.trophy_full_title'))
          .fontSize($r('app.float.default_12'))
          .fontColor($r('app.color.white'))
          .margin({ top: Const.DEFAULT_12 })
        Text(this.trophyStageLabel(this.checkInDays))
          .fontSize($r('app.float.default_10'))
          .fontColor(SUB_TEXT_COLOR)
        if (!getTrophyProgress(this.checkInDays).isMax) {
          Progress({
            value: getTrophyProgress(this.checkInDays).progressCurrent,
            total: getTrophyProgress(this.checkInDays).progressTotal,
            type: ProgressType.Linear
          })
            .width('80%')
            .height(3)
            .color(PROGRESS_COLOR)
        }
        Text(this.trophyProgressText(this.checkInDays))
          .fontSize($r('app.float.default_10'))
          .fontColor(SUB_TEXT_COLOR)
      }
      .width(ratio2percent(Const.ACHIEVE_SPLIT_RATIO))
      .padding({ top: Const.ACHIEVE_CARD_TOP, bottom: Const.ACHIEVE_CARD_BOTTOM })
      .onClick(() => this.showFullTrophyDialog())
    }
    .width(Const.FULL_WIDTH)

    if (this.checkInDays === 0 && this.successiveDays === 0) {
      this.EmptyHint(EMPTY_FULL)
    }
  }

  @Builder TaskAchievementContent() {
    if (this.getVisibleTaskStats().length === 0) {
      this.EmptyHint(EMPTY_TASK)
    }
    Column({ space: Const.DEFAULT_12 }) {
      ForEach(this.getVisibleTaskStats(), (stats: TaskAchievementStats) => {
        Column() {
          Row() {
            Text(TaskMapById[stats.taskID - 1].taskName)
              .fontSize($r('app.float.default_16'))
              .fontWeight(Const.FONT_WEIGHT_500)
              .fontColor($r('app.color.white'))
            Blank()
            Text(this.getStreakText(stats))
              .fontSize($r('app.float.default_12'))
              .fontColor(SUB_TEXT_COLOR)
          }
          .width(Const.FULL_WIDTH)

          Text(this.getTodayStateText(stats))
            .fontSize($r('app.float.default_10'))
            .fontColor(stats.todayDone ? PROGRESS_COLOR : SUB_TEXT_COLOR)
            .width(Const.FULL_WIDTH)
            .margin({ top: Const.SPACE_4 })

          Row() {
            ForEach(FULL_ATTENDANCE_MILESTONES, (milestone: number) => {
              Column({ space: Const.SPACE_4 }) {
                Image(this.getBadgeIcon(milestone, stats.streak >= milestone))
                  .width(MINI_BADGE_SIZE)
                  .aspectRatio(1)
                  .objectFit(ImageFit.Contain)
                Text(`${milestone}`)
                  .fontSize($r('app.float.default_10'))
                  .fontColor(SUB_TEXT_COLOR)
              }
              .onClick(() => this.showTaskMilestoneDialog(stats, milestone))
            }, (milestone: number) => `mini_${stats.taskID}_${milestone}_${stats.streak}`)

            Column({ space: Const.SPACE_4 }) {
              Image(getTrophyIcon(getTrophyLevel(stats.streak)))
                .width(MINI_BADGE_SIZE)
                .aspectRatio(1)
                .objectFit(ImageFit.Contain)
              Text('奖杯')
                .fontSize($r('app.float.default_10'))
                .fontColor(SUB_TEXT_COLOR)
            }
            .onClick(() => this.showTaskTrophyDialog(stats))
          }
          .width(Const.FULL_WIDTH)
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: Const.DEFAULT_12 })

          Row({ space: Const.DEFAULT_8 }) {
            Text(`奖杯进度：${this.trophyStageLabel(stats.streak)}  ${this.trophyProgressText(stats.streak)}`)
              .fontSize($r('app.float.default_10'))
              .fontColor(SUB_TEXT_COLOR)
            if (!getTrophyProgress(stats.streak).isMax) {
              Progress({
                value: getTrophyProgress(stats.streak).progressCurrent,
                total: getTrophyProgress(stats.streak).progressTotal,
                type: ProgressType.Linear
              })
                .layoutWeight(1)
                .height(3)
                .color(PROGRESS_COLOR)
            }
          }
          .width(Const.FULL_WIDTH)
          .margin({ top: Const.DEFAULT_8 })
        }
        .width(Const.FULL_WIDTH)
        .padding(Const.DEFAULT_16)
        .borderRadius(Const.DEFAULT_16)
        .backgroundColor(CARD_BG_COLOR)
      }, (stats: TaskAchievementStats) => `task_${stats.taskID}_${stats.streak}_${stats.todayDone}`)
    }
    .width(Const.FULL_WIDTH)
    .padding({ left: Const.DEFAULT_10, right: Const.DEFAULT_10, top: Const.DEFAULT_12 })
  }

  @Builder OverAchievementContent() {
    if (this.getOverTaskStats().length === 0) {
      this.EmptyHint(EMPTY_OVER)
    }
    Column({ space: Const.DEFAULT_12 }) {
      ForEach(this.getOverTaskStats(), (stats: TaskAchievementStats) => {
        Column() {
          Row() {
            Text(TaskMapById[stats.taskID - 1].taskName)
              .fontSize($r('app.float.default_16'))
              .fontWeight(Const.FONT_WEIGHT_500)
              .fontColor($r('app.color.white'))
            Blank()
            Text(this.getMaxPercent(stats) > 0 ? `最高达成：${this.getMaxPercent(stats)}%` : '最高达成：--')
              .fontSize($r('app.float.default_12'))
              .fontColor(SUB_TEXT_COLOR)
          }
          .width(Const.FULL_WIDTH)

          Row() {
            ForEach(OVER_ACHIEVE_PERCENTS, (percent: number) => {
              Image(getPercentIcon(percent, percent <= this.getMaxPercent(stats)))
                .width(PERCENT_BADGE_WIDTH)
                .aspectRatio(1)
                .objectFit(ImageFit.Contain)
                .onClick(() => this.showPercentDialog(stats, percent))
            }, (percent: number) => `percent_${stats.taskID}_${percent}_${this.getMaxPercent(stats)}`)
          }
          .width(Const.FULL_WIDTH)
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: Const.DEFAULT_12 })
        }
        .width(Const.FULL_WIDTH)
        .padding(Const.DEFAULT_16)
        .borderRadius(Const.DEFAULT_16)
        .backgroundColor(CARD_BG_COLOR)
      }, (stats: TaskAchievementStats) => `over_${stats.taskID}_${this.getMaxPercent(stats)}`)
    }
    .width(Const.FULL_WIDTH)
    .padding({ left: Const.DEFAULT_10, right: Const.DEFAULT_10, top: Const.DEFAULT_12 })
  }

  build() {
    Column() {
      TitleBar()
      Row({ space: Const.DEFAULT_24 }) {
        this.TabItem(0, $r('app.string.achievement_tab_full'))
        this.TabItem(1, $r('app.string.achievement_tab_task'))
        this.TabItem(2, $r('app.string.achievement_tab_over'))
      }
      .width(Const.FULL_WIDTH)
      .padding({ left: Const.ACHIEVE_TITLE_BAR_LEFT, top: Const.DEFAULT_16 })

      if (this.currentTab === 0) {
        this.DescLine('完成今日全部任务，才计入 1 天健康全勤。', RULE_FULL_TITLE, RULE_FULL_CONTENT)
      } else if (this.currentTab === 1) {
        this.DescLine('单个任务连续完成目标，可点亮对应任务奖章。', RULE_TASK_TITLE, RULE_TASK_CONTENT)
      } else {
        this.DescLine('100% 为目标达成，200% 及以上为超额达成。', RULE_OVER_TITLE, RULE_OVER_CONTENT)
      }

      Scroll() {
        Column() {
          if (this.currentTab === 0) {
            this.FullAttendanceContent()
          } else if (this.currentTab === 1) {
            this.TaskAchievementContent()
          } else {
            this.OverAchievementContent()
          }
        }
        .width(Const.FULL_WIDTH)
        .padding({ bottom: Const.DEFAULT_24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .padding(Const.DEFAULT_10)
    .height(Const.FULL_HEIGHT)
    .width(Const.FULL_WIDTH)
    .backgroundColor($r('app.color.black'))
  }
}

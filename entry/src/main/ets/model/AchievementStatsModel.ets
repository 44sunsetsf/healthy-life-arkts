/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import dataRdb from '@ohos.data.relationalStore';
import data_preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import RdbUtils from '../common/database/rdb/RdbUtils';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { dateToStr } from '../common/utils/Utils';
import { TaskAchievementStats, TrophyProgressInfo, PercentRecordInfo } from '../viewmodel/AchievementStatsInfo';
import Logger from '../common/utils/Logger';

// 成就页展示用里程碑（73 天奖章按新需求不再展示；全局解锁逻辑 ACHIEVEMENT_LEVEL_LIST 不受影响）
export const FULL_ATTENDANCE_MILESTONES: number[] = [3, 7, 30, 50, 99];
// 成长奖杯等级门槛：LV1/LV2/LV3/LV4
export const TROPHY_LEVEL_STEPS: number[] = [100, 300, 500, 1000];
// 超额成就等级
export const OVER_ACHIEVE_PERCENTS: number[] = [100, 200, 300, 400, 500];
// 支持超额概念的任务：喝水/吃苹果/每日微笑/每日刷牙（早起、早睡一天只能完成一次，不适用）
export const OVER_ACHIEVE_TASK_IDS: number[] = [2, 3, 4, 5];

const STREAK_MAX_LOOKBACK: number = 1100; // LV4 需 1000 天，多留余量
const OVER_ACHIEVE_PREF_KEY: string = 'overAchievementRecords';

class TaskHistoryRow {
  isDone: boolean = false;
  isOpen: boolean = false;
  targetValue: string = '';
  finValue: string = '';
  frequency: string = '';
}

export function getTrophyLevel(count: number): number {
  let level = 0;
  for (let i = 0; i < TROPHY_LEVEL_STEPS.length; i++) {
    if (count >= TROPHY_LEVEL_STEPS[i]) {
      level = i + 1;
    }
  }
  return level;
}

export function getTrophyProgress(count: number): TrophyProgressInfo {
  let info = new TrophyProgressInfo();
  info.level = getTrophyLevel(count);
  if (info.level >= TROPHY_LEVEL_STEPS.length) {
    info.isMax = true;
    return info;
  }
  let lower = info.level === 0 ? 0 : TROPHY_LEVEL_STEPS[info.level - 1];
  let upper = TROPHY_LEVEL_STEPS[info.level];
  info.progressCurrent = count - lower;
  info.progressTotal = upper - lower;
  return info;
}

export function getTrophyIcon(level: number): Resource {
  let result = $r('app.media.achievement_trophy_off');
  switch (level) {
    case 1:
      result = $r('app.media.achievement_trophy_lv1');
      break;
    case 2:
      result = $r('app.media.achievement_trophy_lv2');
      break;
    case 3:
      result = $r('app.media.achievement_trophy_lv3');
      break;
    case 4:
      result = $r('app.media.achievement_trophy_lv4');
      break;
    default:
      break;
  }
  return result;
}

export function getPercentIcon(percent: number, isOn: boolean): Resource {
  let result = $r('app.string.empty');
  switch (percent) {
    case 100:
      result = isOn ? $r('app.media.achievement_percent_100_on') : $r('app.media.achievement_percent_100_off');
      break;
    case 200:
      result = isOn ? $r('app.media.achievement_percent_200_on') : $r('app.media.achievement_percent_200_off');
      break;
    case 300:
      result = isOn ? $r('app.media.achievement_percent_300_on') : $r('app.media.achievement_percent_300_off');
      break;
    case 400:
      result = isOn ? $r('app.media.achievement_percent_400_on') : $r('app.media.achievement_percent_400_off');
      break;
    case 500:
      result = isOn ? $r('app.media.achievement_percent_500_on') : $r('app.media.achievement_percent_500_off');
      break;
    default:
      break;
  }
  return result;
}

/**
 * 从 taskInfo 历史记录计算每个任务的连续达成统计（只读，不改动任何表结构）。
 */
export function loadTaskStats(callback: (stats: TaskAchievementStats[]) => void): void {
  let tableName = Const.TASK_INFO.tableName;
  if (!tableName) {
    callback([]);
    return;
  }
  RdbUtils.queryAll(tableName).then((resultSet: dataRdb.ResultSet) => {
    let historyMap = new Map<number, Map<string, TaskHistoryRow>>();
    let count = resultSet.rowCount;
    if (count > 0 && typeof count !== 'string') {
      resultSet.goToFirstRow();
      for (let i = 0; i < count; i++) {
        let date = resultSet.getString(resultSet.getColumnIndex('date'));
        if (date !== Const.GLOBAL_KEY) {
          let taskID = resultSet.getDouble(resultSet.getColumnIndex('taskID'));
          let row = new TaskHistoryRow();
          row.isDone = resultSet.getDouble(resultSet.getColumnIndex('isDone')) ? true : false;
          row.isOpen = resultSet.getDouble(resultSet.getColumnIndex('isOpen')) ? true : false;
          row.targetValue = resultSet.getString(resultSet.getColumnIndex('targetValue'));
          row.finValue = resultSet.getString(resultSet.getColumnIndex('finValue'));
          row.frequency = resultSet.getString(resultSet.getColumnIndex('frequency'));
          let taskRows = historyMap.get(taskID);
          if (!taskRows) {
            taskRows = new Map<string, TaskHistoryRow>();
            historyMap.set(taskID, taskRows);
          }
          taskRows.set(date, row);
        }
        resultSet.goToNextRow();
      }
    }
    resultSet.close();
    let result: TaskAchievementStats[] = [];
    for (let taskID = 1; taskID <= Const.TASK_NUM; taskID++) {
      result.push(calcTaskStats(taskID, historyMap.get(taskID)));
    }
    callback(result);
  }).catch((err: Error) => {
    Logger.error('AchievementStatsModel', `loadTaskStats failed: ${err.message}`);
    callback([]);
  });
}

function calcTaskStats(taskID: number, rows: Map<string, TaskHistoryRow> | undefined): TaskAchievementStats {
  let stats = new TaskAchievementStats();
  stats.taskID = taskID;
  if (!rows || rows.size === 0) {
    return stats;
  }
  rows.forEach((row: TaskHistoryRow, dateStr: string) => {
    if (row.isOpen) {
      stats.hasAnyRecord = true;
      if (!isEveryDayFrequency(row.frequency)) {
        stats.isDaily = false;
      }
      if (row.isDone) {
        // 记录首次达成 100% 的信息（供超额成就页使用）
        if (stats.firstDoneDate === '' || new Date(dateStr).getTime() < new Date(stats.firstDoneDate).getTime()) {
          stats.firstDoneDate = dateStr;
          stats.firstDoneTarget = row.targetValue;
          stats.firstDoneFin = row.finValue;
        }
      }
    }
  });

  let today = new Date();
  let todayRow = rows.get(dateToStr(today));
  stats.todayHasTask = todayRow !== undefined && todayRow.isOpen && isExecutionDay(todayRow.frequency, today);
  stats.todayDone = stats.todayHasTask && todayRow !== undefined && todayRow.isDone;

  // 从今天往前回溯：应执行日完成则 +1，应执行日未完成则中断；
  // 非执行日与任务未开启的日期跳过；今日未完成不打断连续统计。
  let day = new Date();
  for (let i = 0; i < STREAK_MAX_LOOKBACK; i++) {
    let dateStr = dateToStr(day);
    let row = rows.get(dateStr);
    let isToday = i === 0;
    if (row && !row.isOpen) {
      // 当日任务未开启，视为非执行日
    } else if (row && !isExecutionDay(row.frequency, day)) {
      // 非执行日不计入也不中断
    } else if (row && row.isDone) {
      stats.streak += 1;
    } else if (isToday) {
      // 今日尚未完成，不中断历史连续
    } else {
      break;
    }
    day.setDate(day.getDate() - 1);
  }
  return stats;
}

function isEveryDayFrequency(frequency: string): boolean {
  if (!frequency || frequency.length === 0) {
    return true;
  }
  let dayCount = 0;
  let parts = frequency.split(',');
  for (let i = 0; i < parts.length; i++) {
    if (!isNaN(Number(parts[i]))) {
      dayCount += 1;
    }
  }
  return dayCount >= Const.WEEK_DAY_NUM;
}

function isExecutionDay(frequency: string, date: Date): boolean {
  if (!frequency || frequency.length === 0) {
    return true;
  }
  let dayId = date.getDay() === 0 ? Const.WEEK_DAY_NUM : date.getDay();
  let parts = frequency.split(',');
  for (let i = 0; i < parts.length; i++) {
    if (Number(parts[i]) === dayId) {
      return true;
    }
  }
  return false;
}

/**
 * 读取超额成就首次达成记录（Preferences 持久化，不涉及数据库表结构）。
 */
export function loadOverAchieveRecords(context: common.Context, callback: (records: PercentRecordInfo[]) => void): void {
  let preferences = data_preferences.getPreferences(context, Const.H_STORE);
  preferences.then((res) => {
    res.get(OVER_ACHIEVE_PREF_KEY, '[]').then((value) => {
      let records: PercentRecordInfo[] = [];
      try {
        records = JSON.parse(value as string);
      } catch (err) {
        records = [];
      }
      callback(records);
    });
  }).catch((err: Error) => {
    Logger.error('AchievementStatsModel', `loadOverAchieveRecords failed: ${err.message}`);
    callback([]);
  });
}

/**
 * 记录一次超额达成（同一任务同一比例只记录首次）。
 *
 * TODO(接入点-任务打卡模块): 当前打卡流程会把 finValue 封顶在 targetValue，
 * 无法产生超过 100% 的完成量数据。待任务模块支持记录真实完成量后，
 * 在打卡处按「实际完成量 / 当日目标量」计算比例并调用本方法，
 * 即可点亮 200%-500% 超额奖章。成就页只负责读取与展示。
 */
export function recordOverAchievement(context: common.Context, record: PercentRecordInfo): void {
  loadOverAchieveRecords(context, (records: PercentRecordInfo[]) => {
    let exists = records.some((item: PercentRecordInfo) =>
      item.taskID === record.taskID && item.percent === record.percent);
    if (exists) {
      return;
    }
    records.push(record);
    let preferences = data_preferences.getPreferences(context, Const.H_STORE);
    preferences.then((res) => {
      res.put(OVER_ACHIEVE_PREF_KEY, JSON.stringify(records)).then(() => {
        res.flush();
      }).catch((err: Error) => {
        Logger.error('AchievementStatsModel', `recordOverAchievement save failed: ${err.message}`);
      });
    });
  });
}

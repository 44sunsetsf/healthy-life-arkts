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

/**
 * 单个任务的成就统计（由历史打卡记录计算得出）
 */
export class TaskAchievementStats {
  taskID: number = 0;
  streak: number = 0; // 连续达成次数（每日任务即连续天数）
  isDaily: boolean = true; // 是否每天执行（决定文案用"天"还是"次"）
  todayHasTask: boolean = false; // 今日是否为该任务的应执行日且已开启
  todayDone: boolean = false;
  hasAnyRecord: boolean = false; // 历史上是否启用过该任务（用于隐藏从未使用的任务）
  firstDoneDate: string = ''; // 首次达成 100% 的日期（超额成就用）
  firstDoneTarget: string = '';
  firstDoneFin: string = '';
}

/**
 * 成长奖杯升级进度
 */
export class TrophyProgressInfo {
  level: number = 0; // 0=未获得，1-4=LV1-LV4
  isMax: boolean = false;
  progressCurrent: number = 0; // 当前等级区间内已完成
  progressTotal: number = 0; // 当前等级区间总长度
}

/**
 * 超额成就达成记录（首次达成时间及当时目标/完成量）
 */
export class PercentRecordInfo {
  taskID: number = 0;
  percent: number = 0; // 100 / 200 / 300 / 400 / 500
  firstDate: string = '';
  targetValue: string = '';
  finValue: string = '';
}

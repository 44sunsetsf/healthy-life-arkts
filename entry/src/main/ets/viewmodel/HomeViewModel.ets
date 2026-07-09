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
import { isReachNewAchievement, ACHIEVEMENT_LEVEL_KEY } from '../model/AchieveModel';
import { TaskMapById, ITaskItem, ACHIEVEMENT_LEVEL_LIST } from '../model/TaskInitList';
import TaskInfo from './TaskInfo';
import DayInfo from './DayInfo';
import { dateToStr, weekDateFormat, padTo2Digits } from '../common/utils/Utils';
import { WeekDateModel, initializeOnStartUp, getPreviousWeek, getMonthCalendar, WEEK_DAY_NUM } from '../model/WeekCalendarModel';
import DatabaseApi from '../model/DatabaseModel';
import TaskInfoTableApi from '../common/database/tables/TaskInfoApi';
import DayInfoApi from '../common/database/tables/DayInfoApi';
import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';
import Logger from '../common/utils/Logger';
import GlobalInfo from './GlobalInfo';
import WeekCalendarInfo from './WeekCalendarInfo';
import AchievementInfo from './AchievementInfo';

export class ExpResult {
  expGained: number = 0;
  oldLevel: number = 0;
  newLevel: number = 0;
}

@Observed
export class HomeStore {
  public currentDate: Date;
  public dateArr: Array<WeekDateModel> = []; // data source list
  public selectedDay: number; // selected day of on week
  public showDate: number;
  public dateTitle: string;
  public selectedDayInfo: WeekDateModel = new WeekDateModel('', '', new Date()); // task info on selected day
  public showMonthView: boolean = false; // month calendar overlay visibility
  public monthDateArr: Array<WeekDateModel> = []; // month calendar data source
  public monthTitle: string = ''; // title of current month calendar
  public monthBaseDate: Date = new Date(); // first day of current month calendar

  constructor(currentDate: Date) {
    this.currentDate = currentDate;
    this.showDate = currentDate.getTime();
    this.dateTitle = weekDateFormat(currentDate.getTime());
    this.selectedDay = (new Date().getDay() + WEEK_DAY_NUM - 1) % WEEK_DAY_NUM;
  }

  public initData() {
    let weekCalendarInfo: WeekCalendarInfo = initializeOnStartUp(this.currentDate);
    this.dateArr = weekCalendarInfo.arr;
    Logger.info('this.currentDate', this.currentDate.toDateString());
    Logger.info('initWeekData dateArr', JSON.stringify(weekCalendarInfo.strArr))
    // get data form db
    DatabaseApi.query(dateToStr(new Date()), (taskList: TaskInfo[], dayInfo: DayInfo) => {
      Logger.info('Current Day Task Info: ', JSON.stringify(taskList));
      DayInfoApi.queryList(weekCalendarInfo.strArr, (res: DayInfo[]) => {
        let tempList = res.concat(dayInfo);
        Logger.info('initDayInfoList: ', JSON.stringify(res));
        for (let i = 0; i < this.dateArr.length; i++) {
          let tempDayInfo = tempList.find((item: DayInfo) => item.date === this.dateArr[i].dateStr) || new DayInfo(this.dateArr[i].dateStr, 0, 0);
          weekCalendarInfo.arr[i].dayInfo = tempDayInfo;
          if (this.dateArr[i].dateStr === dateToStr(new Date(this.showDate))) {
            // get tasks of showDate
            weekCalendarInfo.arr[i].taskList = taskList;
          }
        }
        this.dateArr = weekCalendarInfo.arr;
        setTimeout(() => {
          this.setSelectedShowDate(this.showDate);
        }, 0)
      })
    })
  }

  public getPreWeekData(date: Date, callback: Function) {
    let weekCalendarInfo: WeekCalendarInfo = getPreviousWeek(date);
    // get data form db
    DayInfoApi.queryList(weekCalendarInfo.strArr, (res: DayInfo[]) => {
      Logger.info('getPreWeekData->DayInfoList: ', JSON.stringify(res));
      if (res.length > 0) {
        for (let i = 0; i < weekCalendarInfo.arr.length; i++) {
          let dayInfo = res.find((item) => item.date === weekCalendarInfo.arr[i].dateStr);
          if (dayInfo) {
            weekCalendarInfo.arr[i].dayInfo = dayInfo;
          }
        }
      }
      this.dateArr = weekCalendarInfo.arr.concat(...this.dateArr);
      callback();
    })
  }

  private getMonthStartDate(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }

  private getEarliestMonthStartDate(): Date {
    let currentDate = new Date();
    return new Date(currentDate.getFullYear(), currentDate.getMonth() - 6, 1);
  }

  private getLatestMonthStartDate(): Date {
    let currentDate = new Date();
    return new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
  }

  private getValidMonthStartDate(date: Date): Date {
    let monthStartDate = this.getMonthStartDate(date);
    let earliestMonthStartDate = this.getEarliestMonthStartDate();
    let latestMonthStartDate = this.getLatestMonthStartDate();
    if (monthStartDate.getTime() < earliestMonthStartDate.getTime()) {
      return earliestMonthStartDate;
    }
    if (monthStartDate.getTime() > latestMonthStartDate.getTime()) {
      return latestMonthStartDate;
    }
    return monthStartDate;
  }

  private updateMonthData(baseDate: Date, callback: Function) {
    this.monthBaseDate = this.getValidMonthStartDate(baseDate);
    this.monthTitle = `${this.monthBaseDate.getFullYear()}年${padTo2Digits(this.monthBaseDate.getMonth() + 1)}月`;
    let monthInfo: WeekCalendarInfo = getMonthCalendar(new Date(this.monthBaseDate));
    DayInfoApi.queryList(monthInfo.strArr, (res: DayInfo[]) => {
      for (let i = 0; i < monthInfo.arr.length; i++) {
        if (monthInfo.arr[i].dateStr !== '') {
          let dayInfo = res.find((item: DayInfo) => item.date === monthInfo.arr[i].dateStr);
          monthInfo.arr[i].dayInfo = dayInfo || new DayInfo(monthInfo.arr[i].dateStr, 0, 0);
        }
      }
      this.monthDateArr = monthInfo.arr;
      callback();
    })
  }

  public openMonthView() {
    this.updateMonthData(new Date(this.showDate), () => {
      this.showMonthView = true;
    })
  }

  public closeMonthView() {
    this.showMonthView = false;
  }

  public canGoPreviousMonth(): boolean {
    return this.monthBaseDate.getTime() > this.getEarliestMonthStartDate().getTime();
  }

  public canGoNextMonth(): boolean {
    return this.monthBaseDate.getTime() < this.getLatestMonthStartDate().getTime();
  }

  public changeMonth(offset: number) {
    if (offset < 0 && !this.canGoPreviousMonth()) {
      return;
    }
    if (offset > 0 && !this.canGoNextMonth()) {
      return;
    }
    let nextMonthDate = new Date(this.monthBaseDate.getFullYear(), this.monthBaseDate.getMonth() + offset, 1);
    this.updateMonthData(nextMonthDate, () => {});
  }

  // check is current day
  public checkCurrentDay(): boolean {
    return dateToStr(new Date()) === this.selectedDayInfo?.dateStr;
  }

  public updateSelectedDayInfo(selectedDayInfo: WeekDateModel) {
    Logger.debug('updateSelectedDayInfo', JSON.stringify(selectedDayInfo));
    if (selectedDayInfo.taskList?.length === 0) {
      // get data form db
      TaskInfoTableApi.query(selectedDayInfo.dateStr, true, (res: TaskInfo[]) => {
        Logger.info('Selected TaskInfoList: ', JSON.stringify(res));
        selectedDayInfo.taskList = res;
        this.dateArr = this.dateArr.map((item: WeekDateModel) => {
          if(item.dateStr === selectedDayInfo.dateStr) {
            let taskListStr = JSON.stringify(res);
            item.taskList = JSON.parse(taskListStr);
            return item;
          } else {
            return item;
          }
        })
        this.selectedDayInfo = selectedDayInfo;
      });
    } else {
      this.selectedDayInfo = selectedDayInfo;
    }
    Logger.info("selectedDayTaskInfo: ", JSON.stringify(selectedDayInfo.taskList));
  }

  public updateTaskInfoList(editedTaskInfo: ITaskItem) {
    if (editedTaskInfo?.taskID) {
      // edited task
      let taskID = editedTaskInfo.taskID;
      let targetValue = editedTaskInfo.targetValue;
      let isAlarm = editedTaskInfo.isAlarm;
      let frequency = editedTaskInfo.frequency;
      let startTime = editedTaskInfo.startTime;
      let endTime = editedTaskInfo.endTime;
      let isOpen = editedTaskInfo.isOpen;
      let task = new TaskInfo(0, dateToStr(new Date()), taskID, targetValue, isAlarm,
        startTime, endTime, frequency, false, '', isOpen);
      this.dateArr = this.dateArr.map((item: WeekDateModel) => {
        if (task.date === item.dateStr) {
          Logger.info('item', JSON.stringify(item));
          let taskList: TaskInfo[] = item.taskList;
          const dayInfo: DayInfo = item.dayInfo;
          if (editedTaskInfo.isOpen) {
            // add task
            taskList = taskList.filter((taskItem) => taskItem.taskID != taskID)
              .concat(task)
              .sort((a, b) => a.taskID - b.taskID);
            let count: number = 0;
            taskList.forEach((taskItem: TaskInfo) => {
              if (taskItem.isDone) {
                count++;
              }
            });
            if (count > dayInfo.finTaskNum) {
              dayInfo.finTaskNum = count;
            }
          } else {
            // delete task
            let taskIndex = taskList.findIndex((taskItem) => taskItem.taskID === taskID);
            Logger.info('taskList[taskIndex]', JSON.stringify(taskList[taskIndex]));
            taskList = taskList.filter((taskItem) => taskItem.taskID != taskID);
          }
          dayInfo.targetTaskNum = Const.PROGRESS_TOTAL;
          if (dayInfo.finTaskNum > dayInfo.targetTaskNum) {
            dayInfo.finTaskNum = dayInfo.targetTaskNum;
          }
          DayInfoApi.updateData(dayInfo, () => {
          });
          Logger.debug("tempDayInfo", JSON.stringify(dayInfo));
          let weekDateModelStr = JSON.stringify(item);
          let currentDayInfo: WeekDateModel = JSON.parse(weekDateModelStr);
          currentDayInfo.date = item.date;
          currentDayInfo.taskList = taskList;
          currentDayInfo.dayInfo = dayInfo;
          if (this.checkCurrentDay()) {
            this.selectedDayInfo = currentDayInfo;
          }
          return currentDayInfo;
        }
        return item;
      }).slice(0);
    }
  }

  public setSelectedShowDate(showDateTime: number) {
    if (showDateTime > new Date().getTime()) {
      return;
    }
    this.showDate = showDateTime;
    this.dateTitle = weekDateFormat(this.showDate);
    let selectedInfo = this.dateArr.find((item: WeekDateModel) => item.dateStr === dateToStr(new Date(showDateTime)));
    if (selectedInfo) {
      this.updateSelectedDayInfo(selectedInfo);
    }
    Logger.info('dateTitle', this.dateTitle);
  }

  public getDonePercent(): string {
    let dayInfo = this.selectedDayInfo?.dayInfo;
    Logger.debug("dayInfo", JSON.stringify(dayInfo));
    if (dayInfo && (dayInfo?.finTaskNum || 0) > 0) {
      if (dayInfo.finTaskNum > dayInfo.targetTaskNum) {
        return `${Const.DEFAULT_100}`;
      }
      return `${Math.ceil(dayInfo.finTaskNum / dayInfo.targetTaskNum * Const.DEFAULT_100)}`;
    }
    return '0';
  }

  public getTaskListOfDay(): TaskInfo[] {
    Logger.info('getTaskListOfDay', JSON.stringify(this.selectedDayInfo));
    if (this.selectedDayInfo && this.selectedDayInfo.taskList.length > 0) {
      return this.selectedDayInfo.taskList;
    }
    return [];
  }

  static readonly EXP_PER_CLOCK: number = 20;
  static readonly EXP_PER_LEVEL: number = 100;

  public async taskClock(taskInfo: TaskInfo) {
    let taskItem = await this.updateTask(taskInfo);
    let dateStr = this.selectedDayInfo?.dateStr;
    if (!taskItem) {
      return {
        achievementLevel: 0,
        showAchievement: false
      } as AchievementInfo;
    }

    this.selectedDayInfo.taskList = this.selectedDayInfo.taskList.map((item) => {
      return item.taskID === taskItem?.taskID ? taskItem : item;
    });
    let achievementLevel: number = 0;
    let expGained: number = 0;
    let oldLevel: number = 0;
    let newLevel: number = 0;
    if (taskItem.isDone) {
      let expResult = await this.addExperience(HomeStore.EXP_PER_CLOCK);
      expGained = expResult.expGained;
      oldLevel = expResult.oldLevel;
      newLevel = expResult.newLevel;
      let dayInfo = await this.updateDayInfo();
      if (dayInfo && dayInfo?.finTaskNum === dayInfo?.targetTaskNum) {
        achievementLevel = await this.updateAchievement(this.selectedDayInfo.dayInfo);
      }
    }
    this.dateArr = this.dateArr.map((item: WeekDateModel) => dateStr === item.dateStr ? this.selectedDayInfo : item);
    return {
      achievementLevel: achievementLevel,
      showAchievement: ACHIEVEMENT_LEVEL_LIST.includes(achievementLevel),
      expGained: expGained,
      oldLevel: oldLevel,
      newLevel: newLevel,
      isLevelUp: newLevel > oldLevel
    } as AchievementInfo;
  }

  updateTask(task: TaskInfo): Promise<TaskInfo> {
    return new Promise((resolve, reject) => {
      let taskID = task.taskID;
      let targetValue = task.targetValue;
      let finValue = task.finValue;
      let updateTask = new TaskInfo(task.id, task.date, taskID, targetValue, task.isAlarm, task.startTime,
        task.endTime, task.frequency, task.isDone, finValue, task.isOpen);
      let step = TaskMapById[taskID - 1].step;
      let hasExceed = updateTask.isDone;
      if (step === 0) {
        updateTask.isDone = true;
        updateTask.finValue = targetValue;
      } else {
        let value = Number(finValue) + step;
        updateTask.isDone = updateTask.isDone || value >= Number(targetValue);
        updateTask.finValue = updateTask.isDone ? targetValue : `${value}`;
      }
      TaskInfoTableApi.updateDataByDate(updateTask, (res: number) => {
        if (!res || hasExceed) {
          Logger.error('taskClock-updateTask', JSON.stringify(res));
          reject(res);
        }
        resolve(updateTask);
      })
    })
  }

  updateDayInfo(): Promise<DayInfo> {
    let dayInfo: DayInfo = this.selectedDayInfo.dayInfo;
    dayInfo.finTaskNum += 1;
    dayInfo.targetTaskNum = Const.PROGRESS_TOTAL;
    return new Promise((resolve, reject) => {
      DayInfoApi.updateData(dayInfo, (res: number) => {
        if (!res) {
          Logger.error('taskClock-updateDayInfo', JSON.stringify(res));
          reject(res);
        }
        Logger.info('taskClock-updateDayInfo', JSON.stringify(dayInfo));
        // 同步界面数据
        let dayInfoStr = JSON.stringify(dayInfo);
        this.selectedDayInfo.dayInfo = JSON.parse(dayInfoStr);
        resolve(dayInfo);
      });
    });
  }

  updateAchievement(dayInfo: DayInfo): Promise<number> {
    Logger.debug('taskClock-updateAchievement', JSON.stringify(dayInfo));
    return new Promise((resolve, reject) => {
      let preDay = new Date();
      preDay.setDate(preDay.getDate() - 1);
      preDay = new Date(preDay);
      let preDayStr = dateToStr(preDay);
      Logger.info('taskClock-updateAchievement-1', `${preDayStr}`);
      DayInfoApi.query(preDayStr, (res: DayInfo) => {
        Logger.info('taskClock-updateAchievement-2', JSON.stringify(res));
        let isReset = res?.date === '' || res?.targetTaskNum > res?.finTaskNum;
        GlobalInfoApi.query((res: GlobalInfo) => {
          Logger.info('taskClock-globalInfoApi', JSON.stringify(res));
          let achievementInfo = res;
            isReset ? (achievementInfo.checkInDays = 1) : (achievementInfo.checkInDays += 1);
          let isNewAchieve = isReachNewAchievement(achievementInfo);
          if (isNewAchieve) {
            AppStorage.SetOrCreate(ACHIEVEMENT_LEVEL_KEY, achievementInfo.checkInDays);
            achievementInfo.achievements = achievementInfo.achievements + ',' + achievementInfo.checkInDays;
          }
          GlobalInfoApi.updateData(achievementInfo, (res: number) => {
            if (!res) {
              Logger.error('taskClock-updateAchievement', JSON.stringify(res));
              reject(res);
            }
            Logger.debug('taskClock-updateAchievement', JSON.stringify(achievementInfo));
              isNewAchieve ? resolve(achievementInfo.checkInDays) : resolve(0);
          });
        });
      })
    });
  }

  addExperience(exp: number): Promise<ExpResult> {
    return new Promise((resolve, reject) => {
      GlobalInfoApi.query((res: GlobalInfo) => {
        let oldExp = res.experience;
        let oldLevel = HomeStore.getLevel(oldExp);
        res.experience += exp;
        GlobalInfoApi.updateData(res, (flag: number) => {
          if (flag) {
            let newLevel = HomeStore.getLevel(res.experience);
            AppStorage.SetOrCreate('experienceOld', oldExp);
            AppStorage.SetOrCreate('experienceNew', res.experience);
            AppStorage.SetOrCreate('experienceCurrent', res.experience);
            let result = new ExpResult();
            result.expGained = exp;
            result.oldLevel = oldLevel;
            result.newLevel = newLevel;
            resolve(result);
          } else {
            reject(flag);
          }
        });
      });
    });
  }

  static getLevel(experience: number): number {
    return Math.floor(experience / HomeStore.EXP_PER_LEVEL) + 1;
  }

  static getLevelExp(experience: number): number {
    return experience % HomeStore.EXP_PER_LEVEL;
  }
}
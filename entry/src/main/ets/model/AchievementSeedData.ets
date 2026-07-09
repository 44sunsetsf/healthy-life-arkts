import dataRdb from '@ohos.data.relationalStore';
import data_preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import RdbUtils from '../common/database/rdb/RdbUtils';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { dateToStr } from '../common/utils/Utils';
import { PercentRecordInfo } from '../viewmodel/AchievementStatsInfo';
import Logger from '../common/utils/Logger';

const SEED_TAG: string = 'AchievementSeedData';
const OVER_ACHIEVE_PREF_KEY: string = 'overAchievementRecords';

const TAG = 'AchievementSeedData';
const SEED_DAYS = 1001;
const OVER_ACHIEVE_TASK_IDS: number[] = [2, 3, 4, 5];
const OVER_ACHIEVE_PERCENTS: number[] = [100, 200, 300, 400, 500];
const TARGET_VALUES: string[] = ['', '07:00', '8', '1', '1', '2', '22:00', '1'];

class TaskHistoryRow {
  date: string = '';
  taskID: number = 0;
  targetValue: string = '';
  isAlarm: boolean = false;
  startTime: string = '';
  endTime: string = '';
  frequency: string = '1,2,3,4,5,6,7';
  isDone: boolean = true;
  finValue: string = '';
  isOpen: boolean = true;
}

function toBucket(row: TaskHistoryRow): dataRdb.ValuesBucket {
  let bucket = {} as dataRdb.ValuesBucket;
  bucket['date'] = row.date;
  bucket['taskID'] = row.taskID;
  bucket['targetValue'] = row.targetValue;
  bucket['isAlarm'] = row.isAlarm ? 1 : 0;
  bucket['startTime'] = row.startTime;
  bucket['endTime'] = row.endTime;
  bucket['frequency'] = row.frequency;
  bucket['isDone'] = row.isDone ? 1 : 0;
  bucket['finValue'] = row.finValue;
  bucket['isOpen'] = row.isOpen ? 1 : 0;
  return bucket;
}

export function seedAchievementData(context: common.Context, callback: (success: boolean) => void): void {
  Logger.info(SEED_TAG, 'seedAchievementData start');
  let today = new Date();
  let batchBuckets: dataRdb.ValuesBucket[] = [];

  for (let i = 1; i < SEED_DAYS; i++) {
    let day = new Date(today);
    day.setDate(day.getDate() - i);
    let dateStr = dateToStr(day);
    for (let tid = 1; tid <= Const.TASK_NUM; tid++) {
      let row = new TaskHistoryRow();
      row.date = dateStr;
      row.taskID = tid;
      row.targetValue = TARGET_VALUES[tid];
      row.finValue = TARGET_VALUES[tid];
      row.isDone = true;
      row.isOpen = true;
      batchBuckets.push(toBucket(row));
    }
  }

  let globalBucket = {} as dataRdb.ValuesBucket;
  globalBucket['checkInDays'] = SEED_DAYS - 1;
  globalBucket['achievements'] = '3,7,30,50,99';
  globalBucket['firstDate'] = dateToStr(new Date(today.getFullYear(), today.getMonth(), today.getDate() - SEED_DAYS + 1));
  globalBucket['lastDate'] = dateToStr(today);

  let dayInfoBuckets: dataRdb.ValuesBucket[] = [];
  for (let i = 1; i < SEED_DAYS; i++) {
    let day = new Date(today);
    day.setDate(day.getDate() - i);
    let bucket = {} as dataRdb.ValuesBucket;
    bucket['date'] = dateToStr(day);
    bucket['targetTaskNum'] = Const.TASK_NUM;
    bucket['finTaskNum'] = Const.TASK_NUM;
    dayInfoBuckets.push(bucket);
  }

  let taskInfoPromise = RdbUtils.createDb().then((dbHelper) => {
    let tn = Const.TASK_INFO.tableName;
    if (!tn) {
      return;
    }
    let tableName: string = tn;
    let predicates = new dataRdb.RdbPredicates(tableName);
    return dbHelper.delete(predicates).then(() => {
      return dbHelper.insert(tableName, batchBuckets);
    });
  });

  let globalInfoPromise = RdbUtils.createDb().then((dbHelper) => {
    let tn = Const.GLOBAL_INFO.tableName;
    if (!tn) {
      return;
    }
    let tableName: string = tn;
    let predicates = new dataRdb.RdbPredicates(tableName);
    predicates.equalTo('id', 0);
    return dbHelper.update(globalBucket, predicates);
  });

  let dayInfoPromise = RdbUtils.createDb().then((dbHelper) => {
    let tn = Const.DAY_INFO.tableName;
    if (!tn) {
      return;
    }
    let tableName: string = tn;
    let predicates = new dataRdb.RdbPredicates(tableName);
    return dbHelper.delete(predicates).then(() => {
      return dbHelper.insert(tableName, dayInfoBuckets);
    });
  });

  let overAchievePromise = new Promise<void>((resolve) => {
    let records: PercentRecordInfo[] = [];
    for (let i = 0; i < OVER_ACHIEVE_TASK_IDS.length; i++) {
      let tid = OVER_ACHIEVE_TASK_IDS[i];
      let tv = TARGET_VALUES[tid];
      for (let j = 0; j < OVER_ACHIEVE_PERCENTS.length; j++) {
        let pct = OVER_ACHIEVE_PERCENTS[j];
        let rec = new PercentRecordInfo();
        rec.taskID = tid;
        rec.percent = pct;
        rec.firstDate = '2024-01-01';
        rec.targetValue = tv;
        let finNum = Number(tv) * pct / 100;
        rec.finValue = String(finNum);
        records.push(rec);
      }
    }
    let preferences = data_preferences.getPreferences(context, Const.H_STORE);
    preferences.then((res) => {
      res.put(OVER_ACHIEVE_PREF_KEY, JSON.stringify(records)).then(() => {
        res.flush();
        resolve();
      }).catch(() => {
        resolve();
      });
    }).catch(() => {
      resolve();
    });
  });

  Promise.all([taskInfoPromise, globalInfoPromise, dayInfoPromise, overAchievePromise]).then(() => {
    Logger.info(SEED_TAG, 'seedAchievementData done');
    AppStorage.SetOrCreate('AchievementLevelKey', 99);
    callback(true);
  }).catch((err: Error) => {
    Logger.error(SEED_TAG, `seedAchievementData failed: ${err.message}`);
    callback(false);
  });
}

export function clearAchievementData(context: common.Context, callback: (success: boolean) => void): void {
  Logger.info(SEED_TAG, 'clearAchievementData start');

  let taskInfoPromise = RdbUtils.createDb().then((dbHelper) => {
    let tn = Const.TASK_INFO.tableName;
    if (!tn) {
      return;
    }
    let tableName: string = tn;
    let predicates = new dataRdb.RdbPredicates(tableName);
    predicates.notEqualTo('date', Const.GLOBAL_KEY);
    return dbHelper.delete(predicates);
  });

  let dayInfoPromise = RdbUtils.createDb().then((dbHelper) => {
    let tn = Const.DAY_INFO.tableName;
    if (!tn) {
      return;
    }
    let tableName: string = tn;
    let predicates = new dataRdb.RdbPredicates(tableName);
    return dbHelper.delete(predicates);
  });

  let globalInfoPromise = RdbUtils.createDb().then((dbHelper) => {
    let tn = Const.GLOBAL_INFO.tableName;
    if (!tn) {
      return;
    }
    let tableName: string = tn;
    let resetBucket = {} as dataRdb.ValuesBucket;
    resetBucket['checkInDays'] = 0;
    resetBucket['achievements'] = '';
    let predicates = new dataRdb.RdbPredicates(tableName);
    predicates.equalTo('id', 0);
    return dbHelper.update(resetBucket, predicates);
  });

  let overAchievePromise = new Promise<void>((resolve) => {
    let preferences = data_preferences.getPreferences(context, Const.H_STORE);
    preferences.then((res) => {
      res.put(OVER_ACHIEVE_PREF_KEY, '[]').then(() => {
        res.flush();
        resolve();
      }).catch(() => {
        resolve();
      });
    }).catch(() => {
      resolve();
    });
  });

  Promise.all([taskInfoPromise, dayInfoPromise, globalInfoPromise, overAchievePromise]).then(() => {
    Logger.info(SEED_TAG, 'clearAchievementData done');
    AppStorage.SetOrCreate('AchievementLevelKey', 0);
    callback(true);
  }).catch((err: Error) => {
    Logger.error(SEED_TAG, `clearAchievementData failed: ${err.message}`);
    callback(false);
  });
}

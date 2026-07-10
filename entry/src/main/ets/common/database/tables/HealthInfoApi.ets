import dataRdb from '@ohos.data.relationalStore';
import { HealthCardRecord } from '../../../health/model/HealthDashboardModel';
import { columnHealthInfoList } from '../../../model/RdbColumnModel';
import { CommonConstants as Const } from '../../constants/CommonConstants';
import RdbUtils from '../rdb/RdbUtils';
import Logger from '../../utils/Logger';

class HealthInfoApi {
  saveData(record: HealthCardRecord, callback: () => void): void {
    this.ensureTable((isReady: boolean) => {
      if (!isReady) {
        callback();
        return;
      }
      this.query(record.date, (result: HealthCardRecord) => {
        if (result.date.length <= 0) {
          this.insertData(record, callback);
        } else {
          this.updateData(record, callback);
        }
      });
    });
  }

  query(date: string, callback: (data: HealthCardRecord) => void): void {
    let tableName = Const.HEALTH_INFO.tableName ? Const.HEALTH_INFO.tableName : '';
    if (tableName.length <= 0 || date.length <= 0) {
      callback(new HealthCardRecord());
      return;
    }
    this.ensureTable((isReady: boolean) => {
      if (!isReady) {
        callback(new HealthCardRecord());
        return;
      }
      let predicates: dataRdb.RdbPredicates = new dataRdb.RdbPredicates(tableName);
      predicates.equalTo('date', date);
      RdbUtils.query(predicates).then(resultSet => {
        if (resultSet.rowCount === 0) {
          callback(new HealthCardRecord());
          return;
        }
        resultSet.goToFirstRow();
        callback(this.readRecord(resultSet));
      }).catch((err: Error) => {
        Logger.error('HealthInfoTable', `query healthInfo error ${JSON.stringify(err)}`);
        callback(new HealthCardRecord());
      });
    });
  }

  private ensureTable(callback: (isReady: boolean) => void): void {
    let tableName = Const.HEALTH_INFO.tableName ? Const.HEALTH_INFO.tableName : '';
    RdbUtils.isCreateTable(tableName, columnHealthInfoList).then((result: boolean) => {
      callback(result);
    }).catch((err: Error) => {
      Logger.error('HealthInfoTable', `create healthInfo table error ${JSON.stringify(err)}`);
      callback(false);
    });
  }

  private insertData(record: HealthCardRecord, callback: () => void): void {
    RdbUtils.insert(Const.HEALTH_INFO.tableName ? Const.HEALTH_INFO.tableName : '', this.generateBucket(record))
      .then(() => {
        Logger.info('HealthInfoTable', `Insert healthInfo ${record.date} finished.`);
        callback();
      }).catch((err: Error) => {
      Logger.error('HealthInfoTable', `insert healthInfo error ${JSON.stringify(err)}`);
    });
  }

  private updateData(record: HealthCardRecord, callback: () => void): void {
    let predicates: dataRdb.RdbPredicates =
      new dataRdb.RdbPredicates(Const.HEALTH_INFO.tableName ? Const.HEALTH_INFO.tableName : '');
    predicates.equalTo('date', record.date);
    RdbUtils.update(this.generateBucket(record), predicates).then(() => {
      Logger.info('HealthInfoTable', `Update healthInfo ${record.date} finished.`);
      callback();
    }).catch((err: Error) => {
      Logger.error('HealthInfoTable', `update healthInfo error ${JSON.stringify(err)}`);
    });
  }

  private readRecord(resultSet: dataRdb.ResultSet): HealthCardRecord {
    let record = new HealthCardRecord();
    record.date = resultSet.getString(resultSet.getColumnIndex('date'));
    record.steps = resultSet.getDouble(resultSet.getColumnIndex('steps'));
    record.waterMl = resultSet.getDouble(resultSet.getColumnIndex('waterMl'));
    record.remainingCalories = resultSet.getDouble(resultSet.getColumnIndex('remainingCalories'));
    return record;
  }

  private generateBucket(record: HealthCardRecord): dataRdb.ValuesBucket {
    let valueBucket = {} as dataRdb.ValuesBucket;
    valueBucket.date = record.date;
    valueBucket.steps = record.steps;
    valueBucket.waterMl = record.waterMl;
    valueBucket.remainingCalories = record.remainingCalories;
    return valueBucket;
  }
}

let healthInfoApi = new HealthInfoApi();

export default healthInfoApi as HealthInfoApi;

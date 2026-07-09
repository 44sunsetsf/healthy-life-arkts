import dataRdb from '@ohos.data.relationalStore';
import UserInfo from '../../../viewmodel/UserInfo';
import { CommonConstants as Const } from '../../constants/CommonConstants';
import RdbUtils from '../rdb/RdbUtils';
import Logger from '../../utils/Logger';

class UserInfoApi {
  insertData(userInfo: UserInfo, callback: Function): void {
    const valueBucket = generateBucket(userInfo);
    RdbUtils.insert(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', valueBucket).then(result => {
      callback(result);
    }).catch((err: Error) => {
      Logger.error('UserInfoTable', `Insert userInfo failed: ${JSON.stringify(err)}`);
      callback(0);
    });
  }

  updateData(userInfo: UserInfo, callback: Function): void {
    const valueBucket = generateBucket(userInfo);
    let predicates = new dataRdb.RdbPredicates(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '');
    predicates.equalTo('username', userInfo.username);
    RdbUtils.update(valueBucket, predicates).then((result: number) => {
      callback(result);
    }).catch((err: Error) => {
      Logger.error('UserInfoTable', `Update userInfo failed: ${JSON.stringify(err)}`);
      callback(0);
    });
  }

  queryByUsername(username: string, callback: Function): void {
    let predicates = new dataRdb.RdbPredicates(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '');
    predicates.equalTo('username', username);
    RdbUtils.query(predicates).then(resultSet => {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        callback(this.readFromResultSet(resultSet));
      } else {
        callback(null);
      }
    }).catch((err: Error) => {
      Logger.error('UserInfoTable', `QueryByUsername failed: ${JSON.stringify(err)}`);
      callback(null);
    });
  }

  query(callback: Function): void {
    let predicates = new dataRdb.RdbPredicates(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '');
    predicates.equalTo('id', 0);
    RdbUtils.query(predicates).then(resultSet => {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        callback(this.readFromResultSet(resultSet));
      } else {
        callback(null);
      }
    }).catch((err: Error) => {
      Logger.error('UserInfoTable', `Query userInfo failed: ${JSON.stringify(err)}`);
      callback(null);
    });
  }

  insertOrUpdateData(userInfo: UserInfo, callback: Function): void {
    this.queryByUsername(userInfo.username, (result: UserInfo | null) => {
      if (result) {
        this.updateData(userInfo, callback);
      } else {
        this.insertData(userInfo, callback);
      }
    });
  }

  readFromResultSet(resultSet: dataRdb.ResultSet): UserInfo {
    let result = new UserInfo();
    result.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
    let usernameIdx = resultSet.getColumnIndex('username');
    result.username = usernameIdx >= 0 ? resultSet.getString(usernameIdx) : '';
    result.avatar = resultSet.getString(resultSet.getColumnIndex('avatar'));
    result.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'));
    result.signature = resultSet.getString(resultSet.getColumnIndex('signature'));
    result.gender = resultSet.getString(resultSet.getColumnIndex('gender'));
    result.birthday = resultSet.getString(resultSet.getColumnIndex('birthday'));
    result.height = resultSet.getString(resultSet.getColumnIndex('height'));
    result.weight = resultSet.getString(resultSet.getColumnIndex('weight'));
    return result;
  }
}

function generateBucket(userInfo: UserInfo): dataRdb.ValuesBucket {
  let valueBucket = {} as dataRdb.ValuesBucket;
  Const.USER_INFO.columns?.forEach((item: string) => {
    if (item === 'id') {
      return;
    }
    switch (item) {
      case 'username':
        valueBucket[item] = userInfo.username;
        break;
      case 'avatar':
        valueBucket[item] = userInfo.avatar;
        break;
      case 'nickname':
        valueBucket[item] = userInfo.nickname;
        break;
      case 'signature':
        valueBucket[item] = userInfo.signature;
        break;
      case 'gender':
        valueBucket[item] = userInfo.gender;
        break;
      case 'birthday':
        valueBucket[item] = userInfo.birthday;
        break;
      case 'height':
        valueBucket[item] = userInfo.height;
        break;
      case 'weight':
        valueBucket[item] = userInfo.weight;
        break;
      default:
        break;
    }
  });
  return valueBucket;
}

let userInfoApi = new UserInfoApi();

export default userInfoApi as UserInfoApi;

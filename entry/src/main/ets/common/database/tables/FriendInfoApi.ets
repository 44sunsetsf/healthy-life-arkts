import dataRdb from '@ohos.data.relationalStore';
import FriendInfo from '../../../viewmodel/FriendInfo';
import { CommonConstants as Const } from '../../constants/CommonConstants';
import RdbUtils from '../rdb/RdbUtils';
import Logger from '../../utils/Logger';

function readFriendFromResultSet(resultSet: dataRdb.ResultSet): FriendInfo {
  let item = new FriendInfo();
  item.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
  item.username = resultSet.getString(resultSet.getColumnIndex('username'));
  item.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'));
  item.password = resultSet.getString(resultSet.getColumnIndex('password'));
  item.experience = resultSet.getDouble(resultSet.getColumnIndex('experience'));
  item.isMe = resultSet.getDouble(resultSet.getColumnIndex('isMe')) === 1;
  return item;
}

class FriendInfoApi {
  insertData(friendInfo: FriendInfo, callback: Function): void {
    const valueBucket = generateBucket(friendInfo);
    RdbUtils.insert(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '', valueBucket).then(result => {
      callback(result);
    }).catch((err: Error) => {
      Logger.error('FriendInfoTable', `Insert failed: ${JSON.stringify(err)}`);
      callback(0);
    });
  }

  updateData(friendInfo: FriendInfo, callback: Function): void {
    const valueBucket = generateBucket(friendInfo);
    let predicates = new dataRdb.RdbPredicates(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '');
    predicates.equalTo('id', friendInfo.id);
    RdbUtils.update(valueBucket, predicates).then((result: number) => {
      callback(result);
    }).catch((err: Error) => {
      Logger.error('FriendInfoTable', `Update failed: ${JSON.stringify(err)}`);
      callback(0);
    });
  }

  queryAll(callback: Function): void {
    let predicates = new dataRdb.RdbPredicates(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '');
    RdbUtils.query(predicates).then(resultSet => {
      let list: FriendInfo[] = [];
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          list.push(readFriendFromResultSet(resultSet));
        } while (resultSet.goToNextRow());
      }
      callback(list);
    }).catch((err: Error) => {
      Logger.error('FriendInfoTable', `QueryAll failed: ${JSON.stringify(err)}`);
      callback([]);
    });
  }

  queryMe(callback: Function): void {
    let predicates = new dataRdb.RdbPredicates(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '');
    predicates.equalTo('isMe', 1);
    RdbUtils.query(predicates).then(resultSet => {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        callback(readFriendFromResultSet(resultSet));
      } else {
        callback(null);
      }
    }).catch((err: Error) => {
      Logger.error('FriendInfoTable', `QueryMe failed: ${JSON.stringify(err)}`);
      callback(null);
    });
  }

  queryByUsername(username: string, callback: Function): void {
    let predicates = new dataRdb.RdbPredicates(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '');
    predicates.equalTo('username', username);
    RdbUtils.query(predicates).then(resultSet => {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        callback(readFriendFromResultSet(resultSet));
      } else {
        callback(null);
      }
    }).catch((err: Error) => {
      Logger.error('FriendInfoTable', `QueryByUsername failed: ${JSON.stringify(err)}`);
      callback(null);
    });
  }

  login(username: string, password: string, callback: Function): void {
    let predicates = new dataRdb.RdbPredicates(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '');
    predicates.equalTo('username', username);
    predicates.equalTo('password', password);
    RdbUtils.query(predicates).then(resultSet => {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        callback(readFriendFromResultSet(resultSet));
      } else {
        callback(null);
      }
    }).catch((err: Error) => {
      Logger.error('FriendInfoTable', `Login failed: ${JSON.stringify(err)}`);
      callback(null);
    });
  }
}

function generateBucket(friendInfo: FriendInfo): dataRdb.ValuesBucket {
  let valueBucket = {} as dataRdb.ValuesBucket;
  Const.FRIEND_INFO.columns?.forEach((item: string) => {
    switch (item) {
      case 'id':
        if (friendInfo.id > 0) {
          valueBucket[item] = friendInfo.id;
        }
        break;
      case 'username':
        valueBucket[item] = friendInfo.username;
        break;
      case 'nickname':
        valueBucket[item] = friendInfo.nickname;
        break;
      case 'password':
        valueBucket[item] = friendInfo.password;
        break;
      case 'experience':
        valueBucket[item] = friendInfo.experience;
        break;
      case 'isMe':
        valueBucket[item] = friendInfo.isMe ? 1 : 0;
        break;
      default:
        break;
    }
  });
  return valueBucket;
}

let friendInfoApi = new FriendInfoApi();
export default friendInfoApi as FriendInfoApi;

import dataRdb from '@ohos.data.relationalStore';
import { CommonConstants as Const } from '../../constants/CommonConstants';
import RdbUtils from '../rdb/RdbUtils';
import Logger from '../../utils/Logger';

const TAG = 'ChatMsgTable';

export interface ChatMsgRow {
  id: number;
  role: string;
  content: string;
  timestamp: number;
}

class ChatMsgApi {

  insertData(role: string, content: string, timestamp: number, callback: Function): void {
    const valueBucket: dataRdb.ValuesBucket = {
      role: role,
      content: content,
      timestamp: timestamp
    } as dataRdb.ValuesBucket;
    const tableName = Const.CHAT_MSG.tableName ? Const.CHAT_MSG.tableName : 'chatMsg';
    RdbUtils.insert(tableName, valueBucket).then(result => {
      Logger.info(TAG, `insertData: role=${role}, len=${content.length}, result=${result}`);
      callback(result);
    }).catch((err: Error) => {
      Logger.error(TAG, `insertData failed: ${JSON.stringify(err)}`);
    });
  }

  queryAll(callback: Function): void {
    let tableName = Const.CHAT_MSG.tableName;
    if (!tableName) {
      Logger.error(TAG, 'queryAll: tableName is empty');
      callback([]);
      return;
    }
    Logger.debug(TAG, 'queryAll: start');
    RdbUtils.queryAll(tableName).then(resultSet => {
      let count = resultSet.rowCount;
      if (count === 0 || typeof count === 'string') {
        Logger.info(TAG, `queryAll: no results, count=${count}`);
        const result: ChatMsgRow[] = [];
        callback(result);
      } else {
        Logger.info(TAG, `queryAll: found ${count} rows`);
        resultSet.goToFirstRow();
        const result: ChatMsgRow[] = [];
        for (let i = 0; i < count; i++) {
          const row: ChatMsgRow = {
            id: resultSet.getDouble(resultSet.getColumnIndex('id')),
            role: resultSet.getString(resultSet.getColumnIndex('role')),
            content: resultSet.getString(resultSet.getColumnIndex('content')),
            timestamp: resultSet.getDouble(resultSet.getColumnIndex('timestamp'))
          } as ChatMsgRow;
          result[i] = row;
          resultSet.goToNextRow();
        }
        callback(result);
      }
    }).catch((err: Error) => {
      Logger.error(TAG, `queryAll failed: ${JSON.stringify(err)}`);
      callback([]);
    });
  }

  deleteAll(callback: Function): void {
    let tableName = Const.CHAT_MSG.tableName;
    if (!tableName) {
      Logger.error(TAG, 'deleteAll: tableName is empty');
      callback(0);
      return;
    }
    Logger.info(TAG, 'deleteAll: start');
    let predicates = new dataRdb.RdbPredicates(tableName);
    RdbUtils.del(predicates).then(result => {
      Logger.info(TAG, `deleteAll: deleted ${result} rows`);
      callback(result);
    }).catch((err: Error) => {
      Logger.error(TAG, `deleteAll failed: ${JSON.stringify(err)}`);
    });
  }
}

let chatMsgApi = new ChatMsgApi();

export default chatMsgApi as ChatMsgApi;

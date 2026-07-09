/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import UIAbility from '@ohos.app.ability.UIAbility';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import {
  columnDayInfoList,
  columnGlobalInfoList,
  columnTaskInfoInfoList,
  columnFormInfoList,
  columnUserInfoList,
  columnFriendInfoList
} from '../model/RdbColumnModel';
import RdbUtils from '../common/database/rdb/RdbUtils';
import Logger from '../common/utils/Logger';
import ColumnInfo from '../viewmodel/ColumnInfo';
import FormUtils from '../common/utils/FormUtils';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { GlobalContext } from '../common/utils/GlobalContext';
import FriendInfoApi from '../common/database/tables/FriendInfoApi';
import FriendInfo from '../viewmodel/FriendInfo';

export default class EntryAbility extends UIAbility {
  private static TAG: string = 'EntryAbility';

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    GlobalContext.getContext().setObject('want', want);
    GlobalContext.getContext().setObject('launchParam', launchParam);

    RdbUtils.initDb(this.context, Const.RDB_NAME.dbName ? Const.RDB_NAME.dbName : '');
    await RdbUtils.createDb();

    RdbUtils.createTable(Const.DAY_INFO.tableName ? Const.DAY_INFO.tableName : '', columnDayInfoList).then(() => {
      Logger.info(`RdbHelper createTable dayInfo success`);
    }).catch((err: Error) => {
      Logger.error(`RdbHelper dayInfo err : ${JSON.stringify(err)}`);
    });

    await RdbUtils.createTable(Const.GLOBAL_INFO.tableName ? Const.GLOBAL_INFO.tableName : '', columnGlobalInfoList)
      .then(() => {
        Logger.info(`RdbHelper createTable globalInfo success`);
      }).catch((err: Error) => {
        Logger.error(`RdbHelper globalInfo err : ${JSON.stringify(err)}`);
      });
    await RdbUtils.addTableColumn(Const.GLOBAL_INFO.tableName ? Const.GLOBAL_INFO.tableName : '',
      new ColumnInfo('experience', 'integer', -1, false, false, false)).then(() => {
      Logger.info(`RdbHelper addColumn experience success`);
    }).catch(() => {});
    RdbUtils.createTable(Const.TASK_INFO.tableName ? Const.TASK_INFO.tableName : '', columnTaskInfoInfoList).then(() => {
      Logger.info(`RdbHelper createTable taskInfo success`);
    }).catch((err: Error) => {
      Logger.error(`RdbHelper taskInfo err : ${JSON.stringify(err)}`);
    });
    RdbUtils.createTable(Const.FORM_INFO.tableName ? Const.FORM_INFO.tableName : '', columnFormInfoList)
      .catch((err: Error) => {
        Logger.error(`RdbHelper formInfo err : ${JSON.stringify(err)}`);
      });
    await RdbUtils.createTable(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', columnUserInfoList)
      .then(() => {
        Logger.info(`RdbHelper createTable userInfo success`);
      }).catch((err: Error) => {
        Logger.error(`RdbHelper userInfo createTable err : ${JSON.stringify(err)}`);
      });
    await RdbUtils.addTableColumn(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '',
      new ColumnInfo('signature', 'text', -1, false, false, false)).then(() => {
      Logger.info(`RdbHelper addColumn signature success`);
    }).catch(() => {});
    await RdbUtils.addTableColumn(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '',
      new ColumnInfo('username', 'text', -1, false, false, false)).then(() => {
      Logger.info(`RdbHelper addColumn username to userInfo success`);
    }).catch(() => {});

    await RdbUtils.createTable(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '', columnFriendInfoList)
      .then(() => {
        Logger.info(`RdbHelper createTable friendInfo success`);
      }).catch((err: Error) => {
        Logger.error(`RdbHelper friendInfo createTable err : ${JSON.stringify(err)}`);
      });
    await RdbUtils.addTableColumn(Const.FRIEND_INFO.tableName ? Const.FRIEND_INFO.tableName : '',
      new ColumnInfo('username', 'text', -1, false, false, false)).then(() => {
      Logger.info(`RdbHelper addColumn username success`);
    }).catch(() => {});

    this.initFriendData();
  }

  initFriendData() {
    FriendInfoApi.queryAll((list: FriendInfo[]) => {
      if (list.length === 0) {
        let initData: FriendInfo[] = [
          new FriendInfo(0, 'xiaoming', '小明', '123123', 780, false),
          new FriendInfo(0, 'xiaohong', '小红', '123123', 520, false),
          new FriendInfo(0, 'xiaogang', '小刚', '123123', 430, false),
          new FriendInfo(0, 'xiaomei', '小美', '123123', 310, false),
          new FriendInfo(0, 'xiaoqiang', '小强', '123123', 150, false),
          new FriendInfo(0, 'xxa', 'xxa', '123123', 0, true)
        ];
        for (let i = 0; i < initData.length; i++) {
          FriendInfoApi.insertData(initData[i], (res: number) => {
            Logger.info('EntryAbility', `insertFriend ${initData[i].nickname} result: ${res}`);
          });
        }
        return;
      }
      let usernameMap: Record<string, string> = {
        '小明': 'xiaoming',
        '小红': 'xiaohong',
        '小刚': 'xiaogang',
        '小美': 'xiaomei',
        '小强': 'xiaoqiang',
        '我': 'xxa',
        'xxa': 'xxa'
      };
      let nicknameMap: Record<string, string> = {
        '我': 'xxa'
      };
      for (let i = 0; i < list.length; i++) {
        let needUpdate = false;
        if (!list[i].username || list[i].username === '') {
          let mapped = usernameMap[list[i].nickname];
          list[i].username = mapped ? mapped : list[i].nickname;
          needUpdate = true;
        }
        if (nicknameMap[list[i].nickname]) {
          list[i].nickname = nicknameMap[list[i].nickname];
          needUpdate = true;
        }
        if (needUpdate) {
          FriendInfoApi.updateData(list[i], () => {
            Logger.info('EntryAbility', `updateFriend for ${list[i].username}`);
          });
        }
      }
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    GlobalContext.getContext().setObject('isForeground', true);
    windowStage.loadContent('pages/SplashPage', (err, data) => {
      if (err.code) {
        Logger.error('windowStage', 'Failed to load the content. Cause:' + JSON.stringify(err));
        return;
      }
      Logger.info('windowStage', 'Succeeded in loading the content. Data: ' + JSON.stringify(data));
    });
  }

  onForeground() {
    // Ability has brought to foreground
    GlobalContext.getContext().setObject('isForeground', true);
    GlobalContext.getContext().setObject('taskListChange', false);
  }

  onBackground() {
    // Ability has back to background
    FormUtils.backgroundUpdateCard(GlobalContext.getContext().getObject('taskListChange') as boolean);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam) {
    // Ability has new want
    GlobalContext.getContext().setObject('abilityWant', want);
    GlobalContext.getContext().setObject('launchParam', launchParam);
  }
};

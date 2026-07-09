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

import common from '@ohos.app.ability.common';
import data_preferences from '@ohos.data.preferences';
import Logger from '../common/utils/Logger';
import { CommonConstants as Const } from '../common/constants/CommonConstants';

// preferences key of the watch linkage switch
const PREF_KEY_WATCH_LINKAGE: string = 'isWatchLinkageEnabled';

/**
 * Persists the global watch linkage switch and mirrors it into
 * AppStorage key 'watchLinkageEnabled' for the UI.
 */
export class WatchSettingModel {
  public static loadToAppStorage(context: common.Context): void {
    let preferences = data_preferences.getPreferences(context, Const.H_STORE);
    preferences.then((res) => {
      res.get(PREF_KEY_WATCH_LINKAGE, false).then((value) => {
        AppStorage.SetOrCreate<boolean>('watchLinkageEnabled', value === true);
      });
    }).catch(() => {
      Logger.error('WatchSettingModel', 'load failed.');
    });
  }

  public static save(context: common.Context, value: boolean): void {
    let preferences = data_preferences.getPreferences(context, Const.H_STORE);
    preferences.then((res) => {
      res.put(PREF_KEY_WATCH_LINKAGE, value).then(() => {
        res.flush();
        Logger.info('WatchSettingModel', `watchLinkage saved: ${value}`);
      }).catch(() => {
        Logger.error('WatchSettingModel', 'save failed.');
      });
    });
  }
}

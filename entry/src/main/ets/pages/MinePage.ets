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

import { ListInfo } from '../view/ListInfo';
import { UserBaseInfo } from '../view/UserBaseInfo';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import UserInfoApi from '../common/database/tables/UserInfoApi';
import UserInfo from '../viewmodel/UserInfo';
import FriendInfoApi from '../common/database/tables/FriendInfoApi';
import FriendInfo from '../viewmodel/FriendInfo';
import { GlobalContext } from '../common/utils/GlobalContext';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import data_preferences from '@ohos.data.preferences';

const H_STORE: string = 'healthAppStore';
const IS_LOGIN: string = 'isLogin';

@Component
export struct MineIndex {
  @State nickname: string = Const.NICK_NAME;
  @State signature: string = Const.SIGNATURE;
  @State avatar: string = '';
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    this.loadUserInfo();
  }

  loadUserInfo() {
    let currentUser = GlobalContext.getContext().getObject('currentUser') as FriendInfo;
    if (currentUser && currentUser.username) {
      UserInfoApi.queryByUsername(currentUser.username, (result: UserInfo | null) => {
        if (result) {
          this.nickname = result.nickname || currentUser.nickname;
          this.signature = result.signature || '';
          this.avatar = result.avatar;
        } else {
          this.nickname = currentUser.nickname;
        }
      });
    }
  }

  handleLogout() {
    let preferences = data_preferences.getPreferences(this.context, H_STORE);
    preferences.then((res) => {
      res.put(IS_LOGIN, false).then(() => {
        res.flush();
        router.replaceUrl({ url: 'pages/LoginPage' });
      });
    });
  }

  build() {
    Column() {
      UserBaseInfo({
        nickname: this.nickname,
        signature: this.signature,
        avatar: this.avatar
      });

      ListInfo();

      Button('退出登录')
        .width('80%')
        .height(44)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor('#E84026')
        .borderRadius(22)
        .margin({ top: 32 ,bottom: 20})
        .onClick(() => {
          this.handleLogout();
        })
    }
    .height(Const.FULL_HEIGHT)
    .backgroundColor($r('app.color.mineBgColor'))
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
      if (isVisible && currentRatio > 0.0) {
        this.loadUserInfo();
      }
    })
  }
}
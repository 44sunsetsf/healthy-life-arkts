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

import { WatchSettingModel } from '../model/WatchSettingModel';

@Component
export struct WatchLinkageSetting {
  @StorageLink('watchLinkageEnabled') watchLinkageEnabled: boolean = false;

  build() {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Text($r('app.string.watch_linkage'))
        .fontSize($r('app.float.default_16'))
        .height($r('app.float.default_40'))

      Toggle({ type: ToggleType.Switch, isOn: this.watchLinkageEnabled })
        .selectedColor($r('app.color.blueColor'))
        .onChange((isOn: boolean) => {
          this.watchLinkageEnabled = isOn;
          WatchSettingModel.save(getContext(this), isOn);
        })
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius($r('app.float.default_24'))
    .height($r('app.float.default_48'))
    .margin({
      top: $r('app.float.default_24'),
      left: $r('app.float.default_12'),
      right: $r('app.float.default_12')
    })
    .padding({
      left: $r('app.float.default_24'),
      right: $r('app.float.default_24')
    })
  }
}

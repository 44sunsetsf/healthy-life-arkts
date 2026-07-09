/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { CommonConstants as Const } from '../../common/constants/CommonConstants';

/**
 * 成就页通用文本弹窗：奖章详情 / 成长奖杯等级 / 规则说明
 */
@CustomDialog
export struct AchievementInfoDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @Link dialogTitle: string;
  @Link dialogContent: string;

  build() {
    Column({ space: Const.DEFAULT_16 }) {
      Text(this.dialogTitle)
        .fontSize($r('app.float.default_18'))
        .fontWeight(Const.FONT_WEIGHT_500)
        .fontColor($r('app.color.white'))
      Text(this.dialogContent)
        .fontSize($r('app.float.default_14'))
        .fontColor('#CCFFFFFF')
        .lineHeight(22)
      Button('知道了')
        .fontSize($r('app.float.default_14'))
        .height(36)
        .width(Const.FULL_WIDTH)
        .backgroundColor('#33FFFFFF')
        .fontColor($r('app.color.white'))
        .onClick(() => {
          this.controller.close();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(Const.DEFAULT_24)
    .width('82%')
    .borderRadius(Const.DEFAULT_16)
    .backgroundColor('#2E2E38')
  }
}

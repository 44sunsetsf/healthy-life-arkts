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

let progressStorage = new LocalStorage();

@Entry(progressStorage)
@Component
struct ProgressCard {
  @LocalStorageProp('numerator') numerator: number = 0;
  @LocalStorageProp('denominator') denominator: number = 0;
  @LocalStorageProp('percent') percent: string = '0';

  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'EntryAbility';
  readonly FULL_WIDTH_PERCENT: string = '100%';
  readonly FULL_HEIGHT_PERCENT: string = '100%';
  readonly PROGRESS_TOTAL: number = 100;
  readonly TEXT_SLIGHTLY_BOLD: number = 500;
  readonly PERCENTAGE: string = '%';
  readonly SLASHES: string = '/';

  getProgressColor(): string {
    let p = Number.parseInt(this.percent);
    if (p >= 100) return '#4CAF50';
    if (p >= 60) return '#409EFF';
    if (p >= 30) return '#E6A23C';
    return '#F56C6C';
  }

  getStatusText(): string {
    let p = Number.parseInt(this.percent);
    if (p >= 100) return '已全部完成';
    if (p >= 60) return '进展良好';
    if (p >= 30) return '继续加油';
    return '刚刚开始';
  }

  build() {
    Column() {
      Text('今日进度')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width(this.FULL_WIDTH_PERCENT)
        .padding({ left: 12, top: 10, bottom: 4 })

      Stack() {
        Progress({ value: 0, total: this.PROGRESS_TOTAL, type: ProgressType.Ring })
          .value(Number.parseInt(this.percent))
          .width(80)
          .height(80)
          .style({ strokeWidth: 8 })
          .color(this.getProgressColor())
        Column() {
          Text(this.percent)
            .fontSize(20)
            .fontColor('#333333')
            .fontWeight(this.TEXT_SLIGHTLY_BOLD)
          Text(this.PERCENTAGE)
            .fontSize(10)
            .fontColor('#999999')
            .margin({ top: -2 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)

      Row() {
        Text(this.getStatusText())
          .fontSize(10)
          .fontColor(this.getProgressColor())
          .fontWeight(this.TEXT_SLIGHTLY_BOLD)
        Blank()
        Text(this.numerator.toString())
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(this.TEXT_SLIGHTLY_BOLD)
        Text(this.SLASHES + this.denominator)
          .fontSize(12)
          .fontColor('#999999')
          .fontWeight(FontWeight.Normal)
      }
      .width(this.FULL_WIDTH_PERCENT)
      .padding({ left: 12, right: 12, bottom: 10 })
    }
    .backgroundColor('#F5F7FA')
    .borderRadius(16)
    .width(this.FULL_WIDTH_PERCENT)
    .height(this.FULL_HEIGHT_PERCENT)
    .onClick(() => {
      postCardAction(this, {
        'action': this.ACTION_TYPE,
        'abilityName': this.ABILITY_NAME
      });
    })
  }
}
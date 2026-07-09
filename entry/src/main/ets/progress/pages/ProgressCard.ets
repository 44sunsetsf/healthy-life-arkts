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
  @LocalStorageProp('healthSteps') healthSteps: string = '0';
  @LocalStorageProp('healthWater') healthWater: string = '900';
  @LocalStorageProp('healthCalories') healthCalories: string = '1449';

  /*
   * The action type.
   */
  readonly ACTION_TYPE: string = 'router';

  /*
   * The ability name.
   */
  readonly ABILITY_NAME: string = 'EntryAbility';

  /*
   * The with percentage setting.
   */
  readonly FULL_WIDTH_PERCENT: string = '100%';

  /*
   * The height percentage setting.
   */
  readonly FULL_HEIGHT_PERCENT: string = '100%';

  /*
   * The progress layout height percentage setting.
   */
  readonly PROGRESS_LAYOUT_HEIGHT: string = '80%';

  /*
   * The finish results layout percentage setting.
   */
  readonly RESULTS_LAYOUT_HEIGHT: string = '20%';

  /*
   * The percent sign.
   */
  readonly PERCENTAGE: string = '%';

  /*
   * The slashes splicing.
   */
  readonly SLASHES: string = '/';

  /**
   * The progress total to 100.
   */
  readonly PROGRESS_TOTAL: number = 100;

  /**
   * The text slightly bold.
   */
  readonly TEXT_SLIGHTLY_BOLD: number = 500;

  build() {
    Column() {
      Row() {
        Text('今日健康')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .layoutWeight(1)
        Text(`${this.numerator}${this.SLASHES}${this.denominator}`)
          .fontSize(12)
          .fontColor('#72787E')
      }
      .width(this.FULL_WIDTH_PERCENT)
      .alignItems(VerticalAlign.Center)

      Row() {
        Stack() {
          Progress({ value: 0, total: this.PROGRESS_TOTAL, type: ProgressType.Ring })
            .value(Number.parseInt(this.percent))
            .width(68)
            .height(68)
            .color('#30C6B0')
            .backgroundColor('#E8F8F5')
            .style({ strokeWidth: 8 })
          Column() {
            Row() {
              Text(this.percent)
                .fontSize(18)
                .fontColor('#182431')
                .fontWeight(FontWeight.Bold)
              Text(this.PERCENTAGE)
                .fontSize(10)
                .fontColor('#182431')
                .fontWeight(this.TEXT_SLIGHTLY_BOLD)
                .margin({ top: 6 })
            }
            .justifyContent(FlexAlign.Center)
            Text('任务')
              .fontSize(10)
              .fontColor('#8A94A3')
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width(74)
        .height(74)

        Column({ space: 4 }) {
          Text(`${this.numerator}${this.SLASHES}${this.denominator}`)
            .fontSize(20)
            .fontColor('#182431')
            .fontWeight(FontWeight.Bold)
          Text('已完成任务')
            .fontSize(10)
            .fontColor('#8A94A3')
        }
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .layoutWeight(1)
      .width(this.FULL_WIDTH_PERCENT)
      .alignItems(VerticalAlign.Center)

      Row({ space: 4 }) {
        this.HealthMetric('步数', this.formatHealthValue(this.healthSteps, '步'))
        this.HealthMetric('饮水', this.formatHealthValue(this.healthWater, 'ml'))
        this.HealthMetric('还能吃', this.formatHealthValue(this.healthCalories, '千卡'))
      }
      .width(this.FULL_WIDTH_PERCENT)
      .margin({ top: 4 })
    }
    .padding(12)
    .backgroundColor('#F7FBFA')
    .width(this.FULL_WIDTH_PERCENT)
    .height(this.FULL_HEIGHT_PERCENT)
    .onClick(() => {
      postCardAction(this, {
        'action': this.ACTION_TYPE,
        'abilityName': this.ABILITY_NAME
      });
    })
  }

  formatHealthValue(value: string, unit: string): string {
    if (value === '--') {
      return '--';
    }
    return `${value}${unit}`;
  }

  @Builder HealthMetric(label: string, valueText: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(9)
        .fontColor('#8A94A3')
      Text(valueText)
        .fontSize(10)
        .fontColor('#182431')
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
    }
    .padding({ top: 4, bottom: 4, left: 2, right: 2 })
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#ECF7F5')
    .borderRadius(6)
  }
}

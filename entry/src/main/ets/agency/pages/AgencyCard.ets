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

let agencyStorage = new LocalStorage();

@Entry(agencyStorage)
@Component
struct AgencyCard {
  @LocalStorageProp('taskList') taskList: AgencyCardInfo[] = [];
  @LocalStorageProp('showWidget') showWidget: boolean = false;
  private iconList = {
    getup: $r('app.media.ic_task_morning'),
    drink: $r('app.media.ic_task_water'),
    apple: $r('app.media.ic_task_apple'),
    smile: $r('app.media.ic_task_smile'),
    clean: $r('app.media.ic_task_brush'),
    sleep: $r('app.media.ic_task_night'),
    run: $r('app.media.ic_task_morning')
  } as iconInfo;

  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'EntryAbility';
  readonly FULL_WIDTH_PERCENT: string = '100%';
  readonly FULL_HEIGHT_PERCENT: string = '100%';
  readonly EMPTY_IMAGE_WIDTH: string = '31%';
  readonly EMPTY_IMAGE_HEIGHT: string = '51%';
  readonly TEXT_MARGIN_TOP: string = '0.5%';
  readonly CROSS_BAR_SYMBOL: string = '--';
  readonly SLASHES: string = '/';
  readonly TARGET_VALUE_SPLICING: string = this.CROSS_BAR_SYMBOL + this.SLASHES;
  readonly LIST_SPACE: number = 8;
  readonly LIST_TWO_LANES: number = 2;
  readonly TEXT_OPACITY: number = 0.4;
  readonly TARGET_TEXT_OPACITY: number = 0.6;
  readonly TARGET_TEXT_WEIGHT: number = 1;
  readonly TEXT_SLIGHTLY_BOLD: number = 500;

  getIconByCardTaskType(key?: string): Resource {
    let result: Resource = $r('app.string.empty');
    switch (key) {
      case 'getup':
        result = $r('app.media.ic_task_morning');
        break;
      case 'drink':
        result = $r('app.media.ic_task_water');
        break;
      case 'apple':
        result = $r('app.media.ic_task_apple');
        break;
      case 'smile':
        result = $r('app.media.ic_task_smile');
        break;
      case 'clean':
        result = $r('app.media.ic_task_brush');
        break;
      case 'sleep':
        result = $r('app.media.ic_task_night');
        break;
      case 'run':
        result = $r('app.media.ic_task_morning');
        break;
      default:
        break;
    }
    return result;
  }

  getTaskBgColor(taskItem: AgencyCardInfo): string {
    if (taskItem.isDone) return 'rgba(76,175,80,0.12)';
    return 'rgba(255,255,255,0.90)';
  }

  getTaskIconBgColor(taskItem: AgencyCardInfo): string {
    if (taskItem.isDone) return 'rgba(76,175,80,0.20)';
    return 'rgba(64,158,255,0.12)';
  }

  build() {
    Column() {
      if (this.showWidget) {
        Column() {
          Text('今日任务')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width(this.FULL_WIDTH_PERCENT)
            .padding({ left: 12, top: 10, bottom: 4 })
        }
        .width(this.FULL_WIDTH_PERCENT)

        List({ space: this.LIST_SPACE }) {
          ForEach(this.taskList, (taskItem: AgencyCardInfo) => {
            ListItem() {
              this.AgencyComponent(taskItem)
            }
            .borderRadius(12)
            .backgroundColor(this.getTaskBgColor(taskItem))
          }, (taskItem: AgencyCardInfo) => JSON.stringify(taskItem))
        }
        .padding({
          left: 10,
          top: 4,
          right: 10,
          bottom: 10
        })
        .lanes(this.LIST_TWO_LANES)
        .width(this.FULL_WIDTH_PERCENT)
        .layoutWeight(1)
      } else {
        this.AgencyNoData()
      }
    }
    .width(this.FULL_WIDTH_PERCENT)
    .height(this.FULL_HEIGHT_PERCENT)
    .backgroundColor('#F5F7FA')
    .borderRadius(16)
  }

  @Builder AgencyNoData() {
    Column() {
      Image($r('app.media.ic_no_data'))
        .width(this.EMPTY_IMAGE_WIDTH)
        .height(this.EMPTY_IMAGE_HEIGHT)
        .objectFit(ImageFit.Contain)
        .opacity(0.6)
      Text('暂无任务，点击添加')
        .fontSize(12)
        .fontColor('#999999')
        .fontWeight(FontWeight.Normal)
        .margin({ top: 6 })
    }
    .justifyContent(FlexAlign.Center)
    .width(this.FULL_WIDTH_PERCENT)
    .height(this.FULL_HEIGHT_PERCENT)
    .backgroundColor('#F5F7FA')
    .borderRadius(16)
    .onClick(() => {
      this.jumpToAbility();
    })
  }

  @Builder AgencyComponent(taskItem: AgencyCardInfo) {
    Row() {
      Stack() {
        Circle()
          .width(28)
          .height(28)
          .fill(this.getTaskIconBgColor(taskItem))
        Image(this.getIconByCardTaskType(taskItem.taskType))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
      }
      .margin({ right: 6 })

      if (taskItem.isDone) {
        Text('已完成')
          .fontSize(10)
          .fontColor('#4CAF50')
          .fontWeight(this.TEXT_SLIGHTLY_BOLD)
          .layoutWeight(this.TARGET_TEXT_WEIGHT)
          .textAlign(TextAlign.End)
      } else if (taskItem.dateType) {
        Text(this.TARGET_VALUE_SPLICING + taskItem.targetValue)
          .fontSize(10)
          .fontColor('#666666')
          .opacity(this.TARGET_TEXT_OPACITY)
          .fontWeight(FontWeight.Normal)
          .layoutWeight(this.TARGET_TEXT_WEIGHT)
          .textAlign(TextAlign.End)
      } else {
        Row() {
          Text(taskItem.finValueIsNull ? this.CROSS_BAR_SYMBOL : taskItem.finValue)
            .fontSize(taskItem.finValueIsNull ? 10 : 12)
            .fontWeight(taskItem.finValueIsNull ? FontWeight.Normal : this.TEXT_SLIGHTLY_BOLD)
            .fontColor(taskItem.finValueIsNull ? '#999999' : '#333333')
          Text(this.SLASHES + taskItem.targetValue)
            .fontSize(10)
            .fontWeight(FontWeight.Normal)
            .fontColor('#999999')
          Text(taskItem.unit)
            .fontSize(9)
            .fontWeight(FontWeight.Normal)
            .fontColor('#999999')
        }
        .layoutWeight(this.TARGET_TEXT_WEIGHT)
        .justifyContent(FlexAlign.End)
      }
    }
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .width(this.FULL_WIDTH_PERCENT)
    .height(40)
    .onClick(() => {
      this.jumpToAbility();
    })
  }

  jumpToAbility() {
    postCardAction(this, {
      'action': this.ACTION_TYPE,
      'abilityName': this.ABILITY_NAME
    });
  }
}

class AgencyCardInfo {
  taskType?: string;
  targetValue?: string;
  finValue?: string;
  unit?: string;
  dateType?: boolean;
  hasTargetValue?: boolean;
  finValueIsNull?: boolean;
  isDone?: boolean;
}

interface iconInfo {
  getup: Resource;
  drink: Resource;
  apple: Resource;
  smile: Resource;
  clean: Resource;
  sleep: Resource;
  run: Resource;
}
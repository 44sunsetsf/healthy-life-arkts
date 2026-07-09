import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import { HealthDashboardData } from '../model/HealthDashboardModel';
import { HealthMockService } from '../service/HealthMockService';

@Component
export struct HealthPage {
  @State healthData: HealthDashboardData = new HealthDashboardData();
  @State foodInput: string = '';
  @State weightInput: string = '';
  @State showWeightInput: boolean = false;
  private healthService: HealthMockService = new HealthMockService();

  aboutToAppear() {
    this.healthData = this.healthService.createInitialData();
  }

  syncWatchData() {
    this.healthData = this.healthService.syncWatchData(this.healthData);
  }

  addWater(amountMl: number) {
    this.healthData = this.healthService.addWater(this.healthData, amountMl);
  }

  saveWeightRecord() {
    let weightValue = Number(this.weightInput.trim());
    this.healthData = this.healthService.setWeightRecord(this.healthData, this.weightInput);
    if (!Number.isNaN(weightValue) && weightValue >= 30 && weightValue <= 250) {
      this.weightInput = '';
      this.showWeightInput = false;
    }
  }

  toggleWeightInput() {
    this.showWeightInput = !this.showWeightInput;
    if (this.showWeightInput) {
      this.weightInput = this.formatOneDecimal(this.healthData.weightKg);
    }
  }

  analyzeFood() {
    this.healthData = this.healthService.analyzeFood(this.healthData, this.foodInput);
    this.foodInput = '';
  }

  toggleMood() {
    let next = this.healthService.addWater(this.healthData, 0);
    if (this.healthData.moodText === '平稳') {
      next.moodText = '开心';
    } else if (this.healthData.moodText === '开心') {
      next.moodText = '有压力';
    } else {
      next.moodText = '平稳';
    }
    this.healthData = next;
  }

  getWatchNumber(value: number): string {
    if (!this.healthData.hasWatchData) {
      return '--';
    }
    return value.toString();
  }

  getSleepText(): string {
    if (!this.healthData.hasWatchData) {
      return '--';
    }
    return `${this.formatOneDecimal(this.healthData.sleepHours)} 小时`;
  }

  getSleepRangeText(): string {
    if (!this.healthData.hasWatchData) {
      return '同步后显示';
    }
    return `${this.healthData.sleepStartText} - ${this.healthData.sleepEndText}`;
  }

  getRemainingCaloriesText(): string {
    return this.healthService.getRemainingCalories(this.healthData).toString();
  }

  getWaterPercent(): number {
    if (this.healthData.waterGoalMl <= 0) {
      return 0;
    }
    return Math.min(100, Math.floor(this.healthData.waterMl * 100 / this.healthData.waterGoalMl));
  }

  getStepPercent(): number {
    if (!this.healthData.hasWatchData) {
      return 0;
    }
    return Math.min(100, Math.floor(this.healthData.steps * 100 / this.healthData.stepGoal));
  }

  getCaloriePercent(): number {
    if (!this.healthData.hasWatchData) {
      return 0;
    }
    return Math.min(100, Math.floor(this.healthData.activeCalories * 100 / this.healthData.calorieGoal));
  }

  getExercisePercent(): number {
    if (!this.healthData.hasWatchData) {
      return 0;
    }
    return Math.min(100, Math.floor(this.healthData.exerciseMinutes * 100 / this.healthData.exerciseGoal));
  }

  getDietPercent(): number {
    let total = this.healthData.baseCalories + this.healthData.activeCalories;
    if (total <= 0) {
      return 0;
    }
    return Math.min(100, Math.floor(this.healthData.foodCalories * 100 / total));
  }

  getMoodFaceText(): string {
    if (this.healthData.moodText === '开心') {
      return '😊';
    }
    if (this.healthData.moodText === '有压力') {
      return '🙁';
    }
    return '🙂';
  }

  formatOneDecimal(value: number): string {
    let value10 = Math.round(value * 10);
    let integerPart = Math.floor(value10 / 10);
    let decimalPart = value10 % 10;
    return `${integerPart}.${decimalPart}`;
  }

  @Builder Header() {
    Column() {
      Row() {
        Column() {
          Text('健康')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
          Text(this.healthData.dateText)
            .fontSize(13)
            .fontColor('#6D7784')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('同步手表')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .height(38)
          .padding({ left: 14, right: 14 })
          .backgroundColor('#007DFF')
          .borderRadius(19)
          .onClick(() => {
            this.syncWatchData();
          })
      }
      .width(Const.FULL_WIDTH)
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        this.DayItem('一', '06')
        this.DayItem('二', '07')
        this.DayItem('三', '08')
        this.DayItem('四', '09')
        this.DayItem('五', '10')
        this.DayItem('六', '11')
        this.DayItem('日', '12')
      }
      .width(Const.FULL_WIDTH)
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 18 })
    }
    .width(Const.FULL_WIDTH)
    .padding({ left: 18, right: 18, top: 18, bottom: 12 })
  }

  @Builder DayItem(weekText: string, dayText: string) {
    Column() {
      Text(weekText)
        .fontSize(12)
        .fontColor(dayText === '09' ? '#182431' : '#9AA3AD')
      Text(dayText)
        .fontSize(16)
        .fontWeight(dayText === '09' ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(dayText === '09' ? '#182431' : '#9AA3AD')
        .margin({ top: 4 })
    }
    .width(42)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(dayText === '09' ? '#FFFFFF' : 'rgba(255,255,255,0)')
    .borderRadius(8)
  }

  @Builder DietCard() {
    Column() {
      Row() {
        Text('饮食分析')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .layoutWeight(1)
        Text(`更新：${this.healthData.updateText}`)
          .fontSize(12)
          .fontColor('#9AA3AD')
      }
      .width(Const.FULL_WIDTH)
      .alignItems(VerticalAlign.Center)

      Row() {
        Stack() {
          Progress({ value: this.getDietPercent(), total: 100, type: ProgressType.Ring })
            .width(86)
            .height(86)
            .color('#30C6B0')
            .backgroundColor('#F1F3F5')
            .style({ strokeWidth: 10 })
          Column() {
            Text(this.getRemainingCaloriesText())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
            Text('还能吃')
              .fontSize(12)
              .fontColor('#8A94A3')
          }
          .justifyContent(FlexAlign.Center)
        }
        .width(96)

        Column({ space: 8 }) {
          this.EnergyProteinRow()
          this.CarbsFatRow()
          this.FiberSodiumRow()
        }
        .layoutWeight(1)
        .margin({ left: 14 })
      }
      .width(Const.FULL_WIDTH)
      .margin({ top: 18 })
      .alignItems(VerticalAlign.Center)

      Text(`还能吃 ${this.getRemainingCaloriesText()} 千卡 = 基代 ${this.healthData.baseCalories} + 运动 ${this.healthData.activeCalories} - 饮食 ${this.healthData.foodCalories}`)
        .fontSize(13)
        .fontColor('#5F6977')
        .margin({ top: 14 })
        .width(Const.FULL_WIDTH)

      TextInput({ placeholder: '输入饮食，如：米饭 鸡蛋 青菜', text: this.foodInput })
        .height(40)
        .fontSize(14)
        .fontColor('#182431')
        .backgroundColor('#F6F8FA')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .margin({ top: 14 })
        .onChange((value: string) => {
          this.foodInput = value;
        })

      Row({ space: 10 }) {
        Button('AI 分析')
          .height(38)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#30C6B0')
          .borderRadius(19)
          .layoutWeight(1)
          .onClick(() => {
            this.analyzeFood();
          })
        Button('一句话记录')
          .height(38)
          .fontSize(14)
          .fontColor('#6E54D9')
          .backgroundColor('#F0ECFF')
          .borderRadius(19)
          .layoutWeight(1)
          .onClick(() => {
            this.foodInput = '米饭 鸡胸肉 青菜';
            this.healthData = this.healthService.analyzeFood(this.healthData, this.foodInput);
            this.foodInput = '';
          })
      }
      .width(Const.FULL_WIDTH)
      .margin({ top: 10 })

      Text(this.healthData.analysisText)
        .fontSize(13)
        .fontColor('#5F6977')
        .lineHeight(20)
        .width(Const.FULL_WIDTH)
        .margin({ top: 12 })
    }
    .width(Const.FULL_WIDTH)
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder EnergyProteinRow() {
    Row() {
      Text('热量')
        .fontSize(13)
        .fontColor('#9AA3AD')
        .width(44)
      Text(`${this.healthData.foodCalories} 千卡`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .layoutWeight(1)
      Text('蛋白质')
        .fontSize(13)
        .fontColor('#9AA3AD')
        .width(50)
      Text(`${this.formatOneDecimal(this.healthData.proteinG)} g`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .textAlign(TextAlign.End)
        .width(72)
    }
    .width(Const.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
  }

  @Builder CarbsFatRow() {
    Row() {
      Text('碳水')
        .fontSize(13)
        .fontColor('#9AA3AD')
        .width(44)
      Text(`${this.formatOneDecimal(this.healthData.carbsG)} g`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .layoutWeight(1)
      Text('脂肪')
        .fontSize(13)
        .fontColor('#9AA3AD')
        .width(50)
      Text(`${this.formatOneDecimal(this.healthData.fatG)} g`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .textAlign(TextAlign.End)
        .width(72)
    }
    .width(Const.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
  }

  @Builder FiberSodiumRow() {
    Row() {
      Text('纤维')
        .fontSize(13)
        .fontColor('#9AA3AD')
        .width(44)
      Text(`${this.formatOneDecimal(this.healthData.fiberG)} g`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .layoutWeight(1)
      Text('钠')
        .fontSize(13)
        .fontColor('#9AA3AD')
        .width(50)
      Text(`${this.healthData.sodiumMg} mg`)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .textAlign(TextAlign.End)
        .width(72)
    }
    .width(Const.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
  }

  @Builder WatchCard() {
    Column() {
      Row() {
        Column() {
          Text('手表运动信息')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
          Text(this.healthData.watchSourceText)
            .fontSize(12)
            .fontColor('#8A94A3')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: 8 }) {
          Text(this.healthData.hasWatchData ? '已同步' : '未同步')
            .fontSize(13)
            .fontColor(this.healthData.hasWatchData ? '#30C6B0' : '#9AA3AD')
          Button(this.healthData.hasWatchData ? '刷新' : '同步')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .height(30)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#007DFF')
            .borderRadius(15)
            .onClick(() => {
              this.syncWatchData();
            })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width(Const.FULL_WIDTH)
      .alignItems(VerticalAlign.Center)

      Row({ space: 12 }) {
        this.CalorieRingMetric()
        this.ExerciseRingMetric()
        this.ActiveHourRingMetric()
      }
      .width(Const.FULL_WIDTH)
      .margin({ top: 18 })

      Row({ space: 12 }) {
        this.StepMetric()
        this.HeartRateMetric()
        this.SleepMetric()
      }
      .width(Const.FULL_WIDTH)
      .margin({ top: 14 })
    }
    .width(Const.FULL_WIDTH)
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder CalorieRingMetric() {
    Column() {
      Stack() {
        Progress({ value: this.getCaloriePercent(), total: 100, type: ProgressType.Ring })
          .width(58)
          .height(58)
          .color('#FF6F61')
          .backgroundColor('#F1F3F5')
          .style({ strokeWidth: 7 })
        Text(this.healthData.hasWatchData ? this.healthData.activeCalories.toString() : '--')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
      }
      Text('热量')
        .fontSize(13)
        .fontColor('#5F6977')
        .margin({ top: 8 })
      Text('千卡')
        .fontSize(11)
        .fontColor('#9AA3AD')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder ExerciseRingMetric() {
    Column() {
      Stack() {
        Progress({ value: this.getExercisePercent(), total: 100, type: ProgressType.Ring })
          .width(58)
          .height(58)
          .color('#007DFF')
          .backgroundColor('#F1F3F5')
          .style({ strokeWidth: 7 })
        Text(this.healthData.hasWatchData ? this.healthData.exerciseMinutes.toString() : '--')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
      }
      Text('运动')
        .fontSize(13)
        .fontColor('#5F6977')
        .margin({ top: 8 })
      Text('分钟')
        .fontSize(11)
        .fontColor('#9AA3AD')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder ActiveHourRingMetric() {
    Column() {
      Stack() {
        Progress({ value: Math.min(100, Math.floor(this.healthData.activeHours * 100 / this.healthData.activeHourGoal)), total: 100, type: ProgressType.Ring })
          .width(58)
          .height(58)
          .color('#F5B83D')
          .backgroundColor('#F1F3F5')
          .style({ strokeWidth: 7 })
        Text(this.healthData.hasWatchData ? this.healthData.activeHours.toString() : '--')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
      }
      Text('站立')
        .fontSize(13)
        .fontColor('#5F6977')
        .margin({ top: 8 })
      Text('小时')
        .fontSize(11)
        .fontColor('#9AA3AD')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder StepMetric() {
    Column() {
      Text('步数')
        .fontSize(13)
        .fontColor('#8A94A3')
      Text(this.healthData.hasWatchData ? this.healthData.steps.toString() : '--')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .margin({ top: 6 })
      Text(`${this.getStepPercent()}% 目标`)
        .fontSize(11)
        .fontColor('#9AA3AD')
        .margin({ top: 4 })
    }
    .height(82)
    .layoutWeight(1)
    .padding({ top: 12, bottom: 10 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F6F8FA')
    .borderRadius(8)
  }

  @Builder HeartRateMetric() {
    Column() {
      Text('心率')
        .fontSize(13)
        .fontColor('#8A94A3')
      Text(this.healthData.hasWatchData ? this.healthData.heartRate.toString() : '--')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .margin({ top: 6 })
      Text('次/分')
        .fontSize(11)
        .fontColor('#9AA3AD')
        .margin({ top: 4 })
    }
    .height(82)
    .layoutWeight(1)
    .padding({ top: 12, bottom: 10 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F6F8FA')
    .borderRadius(8)
  }

  @Builder SleepMetric() {
    Column() {
      Text('睡眠')
        .fontSize(13)
        .fontColor('#8A94A3')
      Text(this.getSleepText())
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .margin({ top: 6 })
      Text(this.getSleepRangeText())
        .fontSize(11)
        .fontColor('#9AA3AD')
        .margin({ top: 4 })
    }
    .height(82)
    .layoutWeight(1)
    .padding({ top: 12, bottom: 10 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F6F8FA')
    .borderRadius(8)
  }

  @Builder WeightCard() {
    Column() {
      Row() {
        Text('体重记录')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .layoutWeight(1)
        Button('+')
          .fontSize(24)
          .fontColor('#6E54D9')
          .width(36)
          .height(36)
          .backgroundColor('#F0ECFF')
          .borderRadius(18)
          .onClick(() => {
            this.toggleWeightInput();
          })
      }
      .width(Const.FULL_WIDTH)
      .alignItems(VerticalAlign.Center)

      Row() {
        Circle()
          .width(8)
          .height(8)
          .fill('#64C8A1')
        Blank()
          .width('18%')
          .height(2)
          .backgroundColor('#64C8A1')
        Circle()
          .width(8)
          .height(8)
          .fill('#64C8A1')
        Blank()
          .width('18%')
          .height(2)
          .backgroundColor('#64C8A1')
        Circle()
          .width(8)
          .height(8)
          .fill('#64C8A1')
        Blank()
          .width('18%')
          .height(2)
          .backgroundColor('#64C8A1')
        Circle()
          .width(8)
          .height(8)
          .fill('#64C8A1')
      }
      .width(Const.FULL_WIDTH)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 24 })

      Row() {
        Text(`${this.formatOneDecimal(this.healthData.weightKg)}kg`)
          .fontSize(15)
          .fontColor('#6D7784')
          .layoutWeight(1)
        Text('7天')
          .fontSize(15)
          .fontColor('#6D7784')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(`${this.formatOneDecimal(this.healthData.weightMinKg)}-${this.formatOneDecimal(this.healthData.weightMaxKg)}kg`)
          .fontSize(15)
          .fontColor('#6D7784')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width(Const.FULL_WIDTH)
      .margin({ top: 20 })

      if (this.showWeightInput) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '输入体重(kg)', text: this.weightInput })
            .type(InputType.Number)
            .height(38)
            .fontSize(14)
            .fontColor('#182431')
            .backgroundColor('#F6F8FA')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.weightInput = value;
            })

          Button('保存')
            .height(38)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor('#6E54D9')
            .borderRadius(19)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              this.saveWeightRecord();
            })

          Button('取消')
            .height(38)
            .fontSize(13)
            .fontColor('#6E54D9')
            .backgroundColor('#F0ECFF')
            .borderRadius(19)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.weightInput = '';
              this.showWeightInput = false;
            })
        }
        .width(Const.FULL_WIDTH)
        .margin({ top: 14 })
      }
    }
    .width(Const.FULL_WIDTH)
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder MoodAndWaterRow() {
    Row({ space: 12 }) {
      Column() {
        Row() {
          Text('心情')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
            .layoutWeight(1)
          Text(this.healthData.moodText)
            .fontSize(14)
            .fontColor('#FF9D4D')
        }
        Row({ space: 8 }) {
          Text(this.getMoodFaceText())
            .fontSize(28)
          Text('点击记录心情')
            .fontSize(14)
            .fontColor('#9AA3AD')
        }
        .alignItems(VerticalAlign.Center)
        .margin({ top: 22 })
      }
      .height(126)
      .layoutWeight(1)
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .onClick(() => {
        this.toggleMood();
      })

      Column() {
        Row() {
          Text('喝水')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
            .layoutWeight(1)
          Button('+150ml')
            .fontSize(13)
            .fontColor('#6E54D9')
            .height(30)
            .padding({ left: 10, right: 10 })
            .backgroundColor('#F0ECFF')
            .borderRadius(15)
            .onClick(() => {
              this.addWater(150);
            })
        }

        Row({ space: 3 }) {
          ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (item: number) => {
            Blank()
              .width(6)
              .height(item * 10 <= this.getWaterPercent() ? 24 : 16)
              .backgroundColor(item * 10 <= this.getWaterPercent() ? '#6ACFE3' : '#EAF7FA')
              .borderRadius(3)
          }, (item: number) => item.toString())
        }
        .height(32)
        .alignItems(VerticalAlign.Bottom)
        .margin({ top: 20 })

        Row() {
          Text(`${this.healthData.waterMl}ml`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
          Text(` / ${this.healthData.waterGoalMl}ml`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
        }
        .width(Const.FULL_WIDTH)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
          .margin({ top: 8 })
      }
      .height(126)
      .layoutWeight(1)
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
    .width(Const.FULL_WIDTH)
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        this.Header()
        this.DietCard()
        this.WeightCard()
        this.WatchCard()
        this.MoodAndWaterRow()
      }
      .width(Const.FULL_WIDTH)
      .padding({ left: 12, right: 12, bottom: 24 })
    }
    .width(Const.FULL_WIDTH)
    .height(Const.FULL_HEIGHT)
    .backgroundColor('#EFF8F7')
    .scrollBar(BarState.Off)
  }
}

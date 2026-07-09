import { HomeStore } from '../../viewmodel/HomeViewModel';

@Component
export struct ExpGainPopup {
  @Prop expGained: number = 0;
  @State private offsetY: number = 50;
  @State private opacityValue: number = 0;
  @State private displayExp: number = 0;
  private onDismiss: Function = () => {};

  build() {
    Column() {
      Row() {
        Text('+')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text(`${this.displayExp}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text(' EXP')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .opacity(0.9)
      }
      .justifyContent(FlexAlign.Center)
      .padding({ left: 24, right: 24, top: 12, bottom: 12 })
      .borderRadius(24)
      .backgroundColor('rgba(255,165,0,0.90)')
      .shadow({ radius: 12, color: 'rgba(255,165,0,0.4)', offsetY: 4 })
    }
    .offset({ y: this.offsetY })
    .opacity(this.opacityValue)
    .onAppear(() => {
      this.startCountUp();
      animateTo({
        duration: 300,
        curve: Curve.EaseOut
      }, () => {
        this.offsetY = 0;
        this.opacityValue = 1;
      });
      setTimeout(() => {
        animateTo({
          duration: 300,
          curve: Curve.EaseIn
        }, () => {
          this.offsetY = -30;
          this.opacityValue = 0;
        });
        setTimeout(() => {
          this.onDismiss();
        }, 350);
      }, 1800);
    })
  }

  startCountUp() {
    let current = 0;
    let target = this.expGained;
    let step = Math.max(1, Math.floor(target / 15));
    let timer = setInterval(() => {
      current += step;
      if (current >= target) {
        current = target;
        clearInterval(timer);
      }
      this.displayExp = current;
    }, 40);
  }
}

@Component
export struct LevelUpPopup {
  @Prop newLevel: number = 1;
  @State private scaleValue: number = 0.3;
  @State private opacityValue: number = 0;
  @State private glowScale: number = 1;
  @State private glowOpacity: number = 0;
  private onDismiss: Function = () => {};

  build() {
    Column() {
      Stack() {
        Circle()
          .width(160)
          .height(160)
          .fill('rgba(255,215,0,0.15)')
          .scale({ x: this.glowScale, y: this.glowScale })
          .opacity(this.glowOpacity)

        Column() {
          Text('LEVEL UP!')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')
            .letterSpacing(2)
          Text(`LV.${this.newLevel}`)
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ top: 4 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(200)
      .height(200)
      .alignContent(Alignment.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.65)')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .scale({ x: this.scaleValue, y: this.scaleValue })
    .opacity(this.opacityValue)
    .onAppear(() => {
      animateTo({
        duration: 400,
        curve: Curve.FastOutSlowIn
      }, () => {
        this.scaleValue = 1;
        this.opacityValue = 1;
        this.glowScale = 2.5;
        this.glowOpacity = 0.6;
      });
      setTimeout(() => {
        animateTo({
          duration: 600,
          curve: Curve.EaseOut
        }, () => {
          this.glowScale = 3.5;
          this.glowOpacity = 0;
        });
      }, 500);
      setTimeout(() => {
        animateTo({
          duration: 300,
          curve: Curve.EaseIn
        }, () => {
          this.scaleValue = 1.2;
          this.opacityValue = 0;
        });
        setTimeout(() => {
          this.onDismiss();
        }, 350);
      }, 2200);
    })
  }
}

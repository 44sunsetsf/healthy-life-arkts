import { CommonConstants as Const } from '../../common/constants/CommonConstants';

@CustomDialog
export struct AchievementInfoDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @Link dialogTitle: string;
  @Link dialogContent: string;
  @Link dialogIcon: Resource;
  @State rotateAngle: number = 0;
  @State iconScale: number = 0.3;

  aboutToAppear() {
    setTimeout(() => {
      this.iconScale = 1;
      this.rotateAngle = 360;
    }, 50);
  }

  build() {
    Column() {
      Column() {
        Image(this.dialogIcon)
          .width(100)
          .height(100)
          .objectFit(ImageFit.Contain)
          .rotate({
            x: 0,
            y: 1,
            z: 0,
            angle: this.rotateAngle,
            centerX: '50%',
            centerY: '50%',
            perspective: 800
          })
          .scale({ x: this.iconScale, y: this.iconScale, centerX: '50%', centerY: '50%' })
          .animation({
            duration: 800,
            curve: Curve.EaseOut,
            playMode: PlayMode.Normal
          })
      }
      .width(Const.FULL_WIDTH)
      .height(110)
      .justifyContent(FlexAlign.Center)

      Text(this.dialogTitle)
        .fontSize($r('app.float.default_18'))
        .fontWeight(Const.FONT_WEIGHT_500)
        .fontColor('#3E2723')
        .margin({ top: Const.DEFAULT_8 })

      Text(this.dialogContent)
        .fontSize($r('app.float.default_14'))
        .fontColor('#5D4037')
        .lineHeight(22)
        .margin({ top: Const.DEFAULT_8 })
        .width(Const.FULL_WIDTH)

      Button('知道了')
        .fontSize($r('app.float.default_14'))
        .height(36)
        .width(Const.FULL_WIDTH)
        .backgroundColor('rgba(62,39,35,0.15)')
        .fontColor('#3E2723')
        .margin({ top: Const.DEFAULT_12 })
        .onClick(() => {
          this.controller.close();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(Const.DEFAULT_16)
    .width('82%')
    .borderRadius(Const.DEFAULT_16)
    .linearGradient({
      angle: 135,
      colors: [['#FFF8E1', 0], ['#FFE082', 0.4], ['#FFB74D', 0.8], ['#FF8A65', 1]]
    })
  }
}

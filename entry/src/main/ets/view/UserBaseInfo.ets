import { HomeStore } from '../viewmodel/HomeViewModel';
import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';
import GlobalInfo from '../viewmodel/GlobalInfo';

@Component
export struct UserBaseInfo {
  @Prop nickname: string = '';
  @Prop signature: string = '';
  @Prop avatar: string = '';
  @State displayLevel: number = 1;
  @State displayExp: number = 0;
  @StorageLink('experienceOld') experienceOld: number = 0;
  @StorageLink('experienceNew') @Watch('onExpNewChange') experienceNew: number = 0;
  @StorageLink('experienceCurrent') experienceCurrent: number = 0;
  private lastAnimatedNew: number = -1;

  aboutToAppear() {
    this.loadExpInfo();
  }

  onExpNewChange() {
    if (this.experienceNew > 0 && this.lastAnimatedNew !== this.experienceNew) {
      this.lastAnimatedNew = this.experienceNew;
      this.startExpAnimation(this.experienceOld, this.experienceNew);
    }
  }

  loadExpInfo() {
    GlobalInfoApi.query((result: GlobalInfo) => {
      if (result) {
        if (this.experienceNew > 0 && this.lastAnimatedNew !== this.experienceNew) {
          this.lastAnimatedNew = this.experienceNew;
          this.startExpAnimation(this.experienceOld, this.experienceNew);
        } else {
          this.displayLevel = HomeStore.getLevel(result.experience);
          this.displayExp = HomeStore.getLevelExp(result.experience);
          if (this.experienceNew === 0) {
            this.experienceOld = result.experience;
            this.experienceCurrent = result.experience;
          }
        }
      }
    });
  }

  startExpAnimation(oldExp: number, newExp: number) {
    let current = oldExp;
    let step = 1;
    let timer = setInterval(() => {
      current += step;
      if (current >= newExp) {
        current = newExp;
        clearInterval(timer);
      }
      this.displayLevel = HomeStore.getLevel(current);
      this.displayExp = HomeStore.getLevelExp(current);
    }, 20);
  }

  build() {
    Column() {
      Image(this.avatar ? this.avatar : $r('app.media.ic_user'))
        .objectFit(ImageFit.Cover)
        .height($r('app.float.default_66'))
        .width($r('app.float.default_66'))
        .borderRadius(33)
        .margin({ top: $r('app.float.default_71') })

      Column() {
        Text(`LV.${this.displayLevel}`)
          .fontSize($r('app.float.default_12'))
          .fontWeight(FontWeight.Bolder)
          .fontColor($r('app.color.leveColor'))
      }
      .width($r('app.float.default_44'))
      .height($r('app.float.default_16'))
      .margin({ top: $r('app.float.default_n8') })
      .border({ radius: $r('app.float.default_5') })
      .backgroundColor($r('app.color.leveBgColor'))
      .justifyContent(FlexAlign.Center)

      Text(this.nickname)
        .fontSize($r('app.float.default_20'))
        .fontFamily($r('app.string.Helvetica'))
        .margin({ bottom: $r('app.float.default_6') })
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.black'))

      Row() {
        Stack() {
          Row()
            .width('100%')
            .height(8)
            .borderRadius(4)
            .backgroundColor('rgba(0,0,0,0.08)')
          Row()
            .width(`${this.displayExp / HomeStore.EXP_PER_LEVEL * 100}%`)
            .height(8)
            .borderRadius(4)
            .backgroundColor($r('app.color.leveColor'))
        }
        .width('60%')
        .alignContent(Alignment.Start)

        Text(`${this.displayExp}/${HomeStore.EXP_PER_LEVEL}`)
          .fontSize(12)
          .fontColor($r('app.color.signatureColor'))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
      }
      .width('80%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: $r('app.float.default_6') })

      Text(this.signature || '暂无个性签名').fontSize($r('app.float.default_16')).fontWeight(FontWeight.Normal)
        .fontFamily($r('app.string.PingFangSC_Regular'))
        .fontColor($r('app.color.signatureColor'))
    }
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
      if (isVisible && currentRatio > 0.0) {
        if (this.experienceNew > 0 && this.lastAnimatedNew !== this.experienceNew) {
          this.lastAnimatedNew = this.experienceNew;
          this.startExpAnimation(this.experienceOld, this.experienceNew);
        } else if (this.experienceNew === 0) {
          this.loadExpInfo();
        }
      }
    })
  }
}

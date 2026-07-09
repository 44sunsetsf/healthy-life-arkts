import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import { GlobalContext } from '../../common/utils/GlobalContext';

@Component
export struct AiFloatBtn {
  @State posX: number = 310;
  @State posY: number = 80;
  private startX: number = 0;
  private startY: number = 0;
  private startPosX: number = 0;
  private startPosY: number = 0;
  private moved: boolean = false;

  handleClick(): void {
    const fn = GlobalContext.getContext().getObject('switchToAiTab') as Function;
    if (fn) {
      fn();
    }
  }

  build() {
    Stack() {
      Column() {
        Text('🐱')
          .fontSize('22fp')
      }
      .width(Const.DEFAULT_48)
      .height(Const.DEFAULT_48)
      .borderRadius(Const.BORDER_RADIUS_PERCENT_50)
      .backgroundColor('#FF9CBF')
      .border({ width: '2vp', color: '#FFD6E8' })
      .shadow({
        radius: $r('app.float.default_8'),
        color: '#40000000',
        offsetX: 0,
        offsetY: $r('app.float.default_4')
      })
      .justifyContent(FlexAlign.Center)
    }
    .width(Const.DEFAULT_56)
    .height(Const.DEFAULT_56)
    .zIndex(Const.HOME_BTN_Z + 1)
    .position({ x: this.posX, y: this.posY })
    .hitTestBehavior(HitTestMode.Block)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.startX = event.touches[0].screenX;
        this.startY = event.touches[0].screenY;
        this.startPosX = this.posX;
        this.startPosY = this.posY;
        this.moved = false;
      } else if (event.type === TouchType.Move) {
        const dx = event.touches[0].screenX - this.startX;
        const dy = event.touches[0].screenY - this.startY;
        if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
          this.moved = true;
        }
        if (this.moved) {
          this.posX = this.startPosX + dx;
          this.posY = this.startPosY + dy;
        }
      } else if (event.type === TouchType.Up) {
        if (!this.moved) {
          this.handleClick();
        }
      }
    })
  }
}

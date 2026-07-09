import router from '@ohos.router';
import prompt from '@ohos.prompt';
import common from '@ohos.app.ability.common';
import data_preferences from '@ohos.data.preferences';
import FriendInfoApi from '../common/database/tables/FriendInfoApi';
import FriendInfo from '../viewmodel/FriendInfo';
import { GlobalContext } from '../common/utils/GlobalContext';

const H_STORE: string = 'healthAppStore';
const IS_LOGIN: string = 'isLogin';
const LOGIN_USER: string = 'loginUser';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  build() {
    Column() {
      Text('健康生活')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.black'))
        .margin({ top: 120, bottom: 8 })

      Text('登录以继续')
        .fontSize(16)
        .fontColor($r('app.color.signatureColor'))
        .margin({ bottom: 48 })

      TextInput({ placeholder: '请输入账号' })
        .width('80%')
        .height(48)
        .fontSize(16)
        .padding({ left: 16, right: 16 })
        .borderRadius(24)
        .backgroundColor('#F5F5F5')
        .onChange((value: string) => {
          this.username = value;
        })

      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .width('80%')
        .height(48)
        .fontSize(16)
        .padding({ left: 16, right: 16 })
        .borderRadius(24)
        .backgroundColor('#F5F5F5')
        .margin({ top: 16 })
        .onChange((value: string) => {
          this.password = value;
        })

      Button('登录')
        .width('80%')
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.blueColor'))
        .borderRadius(24)
        .margin({ top: 32 })
        .onClick(() => {
          this.handleLogin();
        })

      Text('初始密码均为 123123')
        .fontSize(12)
        .fontColor($r('app.color.signatureColor'))
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.primaryBgColor'))
    .alignItems(HorizontalAlign.Center)
  }

  isValidUsername(username: string): boolean {
    let reg = /^[a-zA-Z0-9_]+$/;
    return reg.test(username);
  }

  handleLogin() {
    if (!this.username || !this.password) {
      prompt.showToast({ message: '请输入账号和密码' });
      return;
    }
    if (!this.isValidUsername(this.username)) {
      prompt.showToast({ message: '账号只能包含字母、数字和下划线' });
      return;
    }
    FriendInfoApi.login(this.username, this.password, (result: FriendInfo | null) => {
      if (result) {
        GlobalContext.getContext().setObject('currentUser', result);
        this.saveLoginState(result.username);
        router.replaceUrl({ url: 'pages/MainPage' });
      } else {
        prompt.showToast({ message: '账号或密码错误' });
      }
    });
  }

  saveLoginState(username: string) {
    let preferences = data_preferences.getPreferences(this.context, H_STORE);
    preferences.then((res) => {
      res.put(IS_LOGIN, true).then(() => {
        res.put(LOGIN_USER, username);
        res.flush();
      });
    });
  }
}

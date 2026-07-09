import router from '@ohos.router';
import prompt from '@system.prompt';
import picker from '@ohos.file.picker';
import Logger from '../common/utils/Logger';
import UserInfo from '../viewmodel/UserInfo';
import UserInfoApi from '../common/database/tables/UserInfoApi';
import FriendInfo from '../viewmodel/FriendInfo';
import { GlobalContext } from '../common/utils/GlobalContext';
import { CommonConstants as Const } from '../common/constants/CommonConstants';

@CustomDialog
struct NicknameDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @State editValue: string = '';
  onConfirm: (value: string) => void = () => {};

  build() {
    Column() {
      Text('修改昵称')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })

      TextInput({ text: this.editValue, placeholder: '请输入昵称' })
        .width('100%')
        .height(44)
        .onChange((value: string) => {
          this.editValue = value;
        })

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })
        Text('确定')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.onConfirm(this.editValue);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 16, bottom: 16 })
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(16)
    .padding({ left: 24, right: 24 })
  }
}

@CustomDialog
struct SignatureDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @State editValue: string = '';
  onConfirm: (value: string) => void = () => {};

  build() {
    Column() {
      Text('修改个性签名')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })

      TextInput({ text: this.editValue, placeholder: '请输入个性签名' })
        .width('100%')
        .height(44)
        .onChange((value: string) => {
          this.editValue = value;
        })

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })
        Text('确定')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.onConfirm(this.editValue);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 16, bottom: 16 })
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(16)
    .padding({ left: 24, right: 24 })
  }
}

@CustomDialog
struct GenderDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @State selectedGender: string = '';
  onConfirm: (value: string) => void = () => {};

  build() {
    Column() {
      Text('选择性别')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })

      Row() {
        Row() {
          Radio({ value: '男', group: 'genderGroup' })
            .checked(this.selectedGender === '男')
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.selectedGender = '男';
              }
            })
          Text('男')
            .fontSize(16)
            .margin({ left: 8 })
        }
        .margin({ right: 48 })

        Row() {
          Radio({ value: '女', group: 'genderGroup' })
            .checked(this.selectedGender === '女')
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.selectedGender = '女';
              }
            })
          Text('女')
            .fontSize(16)
            .margin({ left: 8 })
        }
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })
        Text('确定')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.onConfirm(this.selectedGender);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ bottom: 16 })
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(16)
    .padding({ left: 24, right: 24 })
  }
}

@CustomDialog
struct BirthdayDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  private selectedDate: Date = new Date();
  onConfirm: (value: string) => void = () => {};

  build() {
    Column() {
      Text('选择出生日期')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 8 })

      DatePicker({
        start: new Date('1900-01-01'),
        end: new Date(),
        selected: this.selectedDate
      })
        .onChange((value: DatePickerResult) => {
          let year = value.year as number;
          let month = (value.month as number) + 1;
          let day = value.day as number;
          this.selectedDate = new Date(year, month - 1, day);
        })

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })
        Text('确定')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            let d = this.selectedDate;
            let month = d.getMonth() + 1;
            let day = d.getDate();
            let dateStr = `${d.getFullYear()}-${month < 10 ? '0' + month : month}-${day < 10 ? '0' + day : day}`;
            this.onConfirm(dateStr);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ bottom: 16 })
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(16)
    .padding({ left: 24, right: 24 })
  }
}

@CustomDialog
struct HeightDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @State editValue: string = '';
  onConfirm: (value: string) => void = () => {};

  build() {
    Column() {
      Text('修改身高')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })

      TextInput({ text: this.editValue, placeholder: '请输入身高(cm)' })
        .width('100%')
        .height(44)
        .type(InputType.Number)
        .onChange((value: string) => {
          this.editValue = value;
        })

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })
        Text('确定')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.onConfirm(this.editValue);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 16, bottom: 16 })
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(16)
    .padding({ left: 24, right: 24 })
  }
}

@CustomDialog
struct WeightDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: '' });
  @State editValue: string = '';
  onConfirm: (value: string) => void = () => {};

  build() {
    Column() {
      Text('修改体重')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })

      TextInput({ text: this.editValue, placeholder: '请输入体重(kg)' })
        .width('100%')
        .height(44)
        .type(InputType.Number)
        .onChange((value: string) => {
          this.editValue = value;
        })

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.controller.close();
          })
        Text('确定')
          .fontSize(16)
          .fontColor($r('app.color.blueColor'))
          .onClick(() => {
            this.onConfirm(this.editValue);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 16, bottom: 16 })
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(16)
    .padding({ left: 24, right: 24 })
  }
}

@Entry
@Component
struct ProfilePage {
  @State avatar: string = '';
  @State nickname: string = '';
  @State signature: string = '';
  @State gender: string = '';
  @State birthday: string = '';
  @State userHeight: string = '';
  @State userWeight: string = '';

  private nicknameDialogController: CustomDialogController = new CustomDialogController({
    builder: NicknameDialog({
      editValue: this.nickname,
      onConfirm: (value: string) => {
        this.nickname = value;
      }
    })
  });

  private signatureDialogController: CustomDialogController = new CustomDialogController({
    builder: SignatureDialog({
      editValue: this.signature,
      onConfirm: (value: string) => {
        this.signature = value;
      }
    })
  });

  private genderDialogController: CustomDialogController = new CustomDialogController({
    builder: GenderDialog({
      selectedGender: this.gender,
      onConfirm: (value: string) => {
        this.gender = value;
      }
    })
  });

  private birthdayDialogController: CustomDialogController = new CustomDialogController({
    builder: BirthdayDialog({
      selectedDate: this.birthday ? new Date(this.birthday) : new Date(),
      onConfirm: (value: string) => {
        this.birthday = value;
      }
    })
  });

  private heightDialogController: CustomDialogController = new CustomDialogController({
    builder: HeightDialog({
      editValue: this.userHeight,
      onConfirm: (value: string) => {
        this.userHeight = value;
      }
    })
  });

  private weightDialogController: CustomDialogController = new CustomDialogController({
    builder: WeightDialog({
      editValue: this.userWeight,
      onConfirm: (value: string) => {
        this.userWeight = value;
      }
    })
  });

  aboutToAppear() {
    let currentUser = GlobalContext.getContext().getObject('currentUser') as FriendInfo;
    let username = currentUser ? currentUser.username : '';
    UserInfoApi.queryByUsername(username, (result: UserInfo | null) => {
      if (result) {
        this.avatar = result.avatar;
        this.nickname = result.nickname;
        this.signature = result.signature;
        this.gender = result.gender;
        this.birthday = result.birthday;
        this.userHeight = result.height;
        this.userWeight = result.weight;
      } else {
        if (currentUser) {
          this.nickname = currentUser.nickname;
        }
      }
    });
  }

  pickAvatar() {
    let documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 1;
    documentSelectOptions.fileSuffixFilters = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    let documentViewPicker = new picker.DocumentViewPicker();
    documentViewPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
      if (documentSelectResult && documentSelectResult.length > 0) {
        this.avatar = documentSelectResult[0];
      }
    }).catch((err: Error) => {
      Logger.error('ProfilePage', `pickAvatar error: ${JSON.stringify(err)}`);
    });
  }

  saveUserInfo() {
    let currentUser = GlobalContext.getContext().getObject('currentUser') as FriendInfo;
    let username = currentUser ? currentUser.username : '';
    let userInfo = new UserInfo(0, username, this.avatar, this.nickname, this.signature, this.gender, this.birthday, this.userHeight, this.userWeight);
    UserInfoApi.insertOrUpdateData(userInfo, (flag: number) => {
      if (flag) {
        prompt.showToast({ message: '保存成功' });
      } else {
        prompt.showToast({ message: '保存失败' });
      }
    });
  }

  build() {
    Column() {
      Navigation() {
        Column() {
          Column() {
            Row() {
              Text('头像')
                .fontSize(16)
                .fontColor($r('app.color.black'))
              Blank()
              Image(this.avatar ? this.avatar : $r('app.media.ic_user'))
                .width(48)
                .height(48)
                .borderRadius(24)
                .objectFit(ImageFit.Cover)
              Image($r('app.media.ic_right_grey'))
                .width(7)
                .height(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(72)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.pickAvatar();
            })

            Divider().margin({ left: 16 })

            Row() {
              Text('昵称')
                .fontSize(16)
                .fontColor($r('app.color.black'))
              Blank()
              Text(this.nickname || '未设置')
                .fontSize(14)
                .fontColor(this.nickname ? $r('app.color.black') : $r('app.color.statusTipColor'))
              Image($r('app.media.ic_right_grey'))
                .width(7)
                .height(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.nicknameDialogController.open();
            })

            Divider().margin({ left: 16 })

            Row() {
              Text('个性签名')
                .fontSize(16)
                .fontColor($r('app.color.black'))
              Blank()
              Text(this.signature || '未设置')
                .fontSize(14)
                .fontColor(this.signature ? $r('app.color.black') : $r('app.color.statusTipColor'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: '50%' })
              Image($r('app.media.ic_right_grey'))
                .width(7)
                .height(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.signatureDialogController.open();
            })

            Divider().margin({ left: 16 })

            Row() {
              Text('性别')
                .fontSize(16)
                .fontColor($r('app.color.black'))
              Blank()
              Text(this.gender || '未设置')
                .fontSize(14)
                .fontColor(this.gender ? $r('app.color.black') : $r('app.color.statusTipColor'))
              Image($r('app.media.ic_right_grey'))
                .width(7)
                .height(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.genderDialogController.open();
            })

            Divider().margin({ left: 16 })

            Row() {
              Text('出生日期')
                .fontSize(16)
                .fontColor($r('app.color.black'))
              Blank()
              Text(this.birthday || '未设置')
                .fontSize(14)
                .fontColor(this.birthday ? $r('app.color.black') : $r('app.color.statusTipColor'))
              Image($r('app.media.ic_right_grey'))
                .width(7)
                .height(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.birthdayDialogController.open();
            })

            Divider().margin({ left: 16 })

            Row() {
              Text('身高')
                .fontSize(16)
                .fontColor($r('app.color.black'))
              Blank()
              Text(this.userHeight ? `${this.userHeight} cm` : '未设置')
                .fontSize(14)
                .fontColor(this.userHeight ? $r('app.color.black') : $r('app.color.statusTipColor'))
              Image($r('app.media.ic_right_grey'))
                .width(7)
                .height(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.heightDialogController.open();
            })

            Divider().margin({ left: 16 })

            Row() {
              Text('体重')
                .fontSize(16)
                .fontColor($r('app.color.black'))
              Blank()
              Text(this.userWeight ? `${this.userWeight} kg` : '未设置')
                .fontSize(14)
                .fontColor(this.userWeight ? $r('app.color.black') : $r('app.color.statusTipColor'))
              Image($r('app.media.ic_right_grey'))
                .width(7)
                .height(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.weightDialogController.open();
            })
          }
          .backgroundColor($r('app.color.white'))
          .borderRadius(12)
          .margin({ top: 16, left: 16, right: 16 })

          Button('保存')
            .width('90%')
            .height(44)
            .fontSize(16)
            .fontColor($r('app.color.white'))
            .backgroundColor($r('app.color.blueColor'))
            .borderRadius(22)
            .margin({ top: 32 })
            .onClick(() => {
              this.saveUserInfo();
            })
        }
        .width('100%')
        .height('100%')
      }
      .size({ width: '100%', height: '100%' })
      .title('个人资料')
      .titleMode(NavigationTitleMode.Mini)
    }
    .height('100%')
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}

import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';
import GlobalInfo from '../viewmodel/GlobalInfo';
import { HomeStore } from '../viewmodel/HomeViewModel';
import UserInfoApi from '../common/database/tables/UserInfoApi';
import UserInfo from '../viewmodel/UserInfo';
import { CommonConstants as Const } from '../common/constants/CommonConstants';

interface RankItem {
  name: string;
  level: number;
  experience: number;
  isMe: boolean;
}

const MOCK_FRIENDS: RankItem[] = [
  { name: '小明', level: 8, experience: 780, isMe: false },
  { name: '小红', level: 6, experience: 520, isMe: false },
  { name: '小刚', level: 5, experience: 430, isMe: false },
  { name: '小美', level: 4, experience: 310, isMe: false },
  { name: '小强', level: 3, experience: 150, isMe: false },
];

@Component
export struct RankIndex {
  @State rankList: RankItem[] = [];
  @State myName: string = '';
  @StorageLink('experienceCurrent') @Watch('onExpChange') experienceCurrent: number = 0;

  aboutToAppear() {
    this.loadRankData();
  }

  onExpChange() {
    this.loadRankData();
  }

  loadRankData() {
    GlobalInfoApi.query((result: GlobalInfo) => {
      let myExp = result ? result.experience : 0;
      let myLevel = HomeStore.getLevel(myExp);
      let meItem: RankItem = { name: '我', level: myLevel, experience: myExp, isMe: true };
      UserInfoApi.query((userResult: UserInfo | null) => {
        if (userResult && userResult.nickname) {
          meItem.name = userResult.nickname;
          this.myName = userResult.nickname;
        }
        let list = [...MOCK_FRIENDS, meItem];
        list.sort((a, b) => b.experience - a.experience);
        this.rankList = list;
      });
    });
  }

  build() {
    Column() {
      Text('好友排名')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.black'))
        .margin({ top: 20, bottom: 16 })

      List({ space: 8 }) {
        ForEach(this.rankList, (item: RankItem, index: number) => {
          ListItem() {
            Row() {
              Text(`${(index as number) + 1}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor((index as number) < 3 ? $r('app.color.blueColor') : $r('app.color.black'))
                .width(36)
                .textAlign(TextAlign.Center)

              Image($r('app.media.ic_user'))
                .width(40)
                .height(40)
                .borderRadius(20)
                .objectFit(ImageFit.Cover)
                .margin({ left: 8, right: 12 })

              Column() {
                Text(item.name)
                  .fontSize(16)
                  .fontWeight(item.isMe ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor($r('app.color.black'))
                Text(`LV.${item.level}`)
                  .fontSize(12)
                  .fontColor($r('app.color.signatureColor'))
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(`${item.experience}经验`)
                .fontSize(14)
                .fontColor($r('app.color.signatureColor'))
            }
            .width('100%')
            .height(64)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor(item.isMe ? $r('app.color.primaryBgColor') : $r('app.color.white'))
            .borderRadius(12)
          }
        }, (item: RankItem, index: number) => `${index}`)
      }
      .width('92%')
      .margin({ left: '4%', right: '4%' })
    }
    .width(Const.FULL_WIDTH)
    .height(Const.FULL_HEIGHT)
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}

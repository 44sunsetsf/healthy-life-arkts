import GlobalInfoApi from '../common/database/tables/GlobalInfoApi';
import GlobalInfo from '../viewmodel/GlobalInfo';
import { HomeStore } from '../viewmodel/HomeViewModel';
import UserInfoApi from '../common/database/tables/UserInfoApi';
import UserInfo from '../viewmodel/UserInfo';
import { CommonConstants as Const } from '../common/constants/CommonConstants';

class RankItem {
  name: string = '';
  level: number = 0;
  experience: number = 0;
  isMe: boolean = false;
}

const MOCK_FRIENDS_DATA: string[][] = [
  ['小明', '8', '780', 'false'],
  ['小红', '6', '520', 'false'],
  ['小刚', '5', '430', 'false'],
  ['小美', '4', '310', 'false'],
  ['小强', '3', '150', 'false'],
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

  getRankBgColor(index: number): string {
    if (index === 0) return 'rgba(255,215,0,0.18)';
    if (index === 1) return 'rgba(192,192,192,0.18)';
    if (index === 2) return 'rgba(205,127,50,0.18)';
    return '#FFFFFF';
  }

  getRankBorderColor(index: number): string {
    if (index === 0) return 'rgba(255,215,0,0.6)';
    if (index === 1) return 'rgba(192,192,192,0.6)';
    if (index === 2) return 'rgba(205,127,50,0.6)';
    return 'rgba(0,0,0,0.05)';
  }

  getTrophyText(index: number): string {
    if (index === 0) return '\uD83E\uDD47';
    if (index === 1) return '\uD83E\uDD48';
    if (index === 2) return '\uD83E\uDD49';
    return `${index + 1}`;
  }

  loadRankData() {
    let mockFriends: RankItem[] = [];
    for (let i = 0; i < MOCK_FRIENDS_DATA.length; i++) {
      let item = new RankItem();
      item.name = MOCK_FRIENDS_DATA[i][0];
      item.level = Number(MOCK_FRIENDS_DATA[i][1]);
      item.experience = Number(MOCK_FRIENDS_DATA[i][2]);
      item.isMe = MOCK_FRIENDS_DATA[i][3] === 'true';
      mockFriends.push(item);
    }
    GlobalInfoApi.query((result: GlobalInfo) => {
      let myExp = result ? result.experience : 0;
      let myLevel = HomeStore.getLevel(myExp);
      let meItem = new RankItem();
      meItem.name = '我';
      meItem.level = myLevel;
      meItem.experience = myExp;
      meItem.isMe = true;
      UserInfoApi.query((userResult: UserInfo | null) => {
        if (userResult && userResult.nickname) {
          meItem.name = userResult.nickname;
          this.myName = userResult.nickname;
        }
        let list = [...mockFriends, meItem];
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
              Text(this.getTrophyText(index as number))
                .fontSize((index as number) < 3 ? 24 : 18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.black'))
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
            .backgroundColor(this.getRankBgColor(index as number))
            .borderRadius(12)
            .border({
              width: 1,
              color: this.getRankBorderColor(index as number),
              radius: 12
            })
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

import FriendInfoApi from '../common/database/tables/FriendInfoApi';
import FriendInfo from '../viewmodel/FriendInfo';
import UserInfoApi from '../common/database/tables/UserInfoApi';
import UserInfo from '../viewmodel/UserInfo';
import { HomeStore } from '../viewmodel/HomeViewModel';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import { GlobalContext } from '../common/utils/GlobalContext';

class RankItem {
  name: string = '';
  level: number = 0;
  experience: number = 0;
  username: string = '';
  avatar: string = '';
}

@Entry
@Component
struct RankPage {
  @State rankList: RankItem[] = [];
  @State currentUsername: string = '';

  aboutToAppear() {
    this.loadRankData();
  }

  getRankBgColor(index: number, isCurrentUser: boolean): string {
    if (isCurrentUser) return 'rgba(64,158,255,0.10)';
    if (index === 0) return 'rgba(255,215,0,0.18)';
    if (index === 1) return 'rgba(192,192,192,0.18)';
    if (index === 2) return 'rgba(205,127,50,0.18)';
    return '#FFFFFF';
  }

  getRankBorderWidth(index: number): number {
    if (index === 0) return 2.5;
    if (index === 1) return 2.5;
    if (index === 2) return 2.5;
    return 1;
  }

  getRankBorderColor(index: number, isCurrentUser: boolean): string {
    if (index === 0) return 'rgba(255,215,0,0.6)';
    if (index === 1) return 'rgba(192,192,192,0.6)';
    if (index === 2) return 'rgba(205,127,50,0.6)';
    if (isCurrentUser) return 'rgba(64,158,255,0.5)';
    return 'rgba(0,0,0,0.05)';
  }

  getTrophyText(index: number): string {
    if (index === 0) return '🥇';
    if (index === 1) return '🥈';
    if (index === 2) return '🥉';
    return `${index + 1}`;
  }

  loadRankData() {
    let currentUser = GlobalContext.getContext().getObject('currentUser') as FriendInfo;
    this.currentUsername = currentUser ? currentUser.username : '';
    FriendInfoApi.queryAll((list: FriendInfo[]) => {
      let rankItems: RankItem[] = [];
      let pending = list.length;
      for (let i = 0; i < list.length; i++) {
        let item = new RankItem();
        item.name = list[i].nickname;
        item.level = HomeStore.getLevel(list[i].experience);
        item.experience = list[i].experience;
        item.username = list[i].username;
        let username = list[i].username;
        UserInfoApi.queryByUsername(username, (userInfo: UserInfo | null) => {
          item.avatar = userInfo ? userInfo.avatar : '';
          rankItems.push(item);
          pending--;
          if (pending === 0) {
            rankItems.sort((a, b) => b.experience - a.experience);
            this.rankList = rankItems;
          }
        });
      }
    });
  }

  build() {
    Column() {
      Navigation() {
        Column() {
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

                  Image(item.avatar ? item.avatar : $r('app.media.ic_user'))
                    .width(40)
                    .height(40)
                    .borderRadius(20)
                    .objectFit(ImageFit.Cover)
                    .margin({ left: 8, right: 12 })

                  Column() {
                    Text(item.name)
                      .fontSize(16)
                      .fontWeight(item.username === this.currentUsername ? FontWeight.Bold : FontWeight.Normal)
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
                .backgroundColor(this.getRankBgColor(index as number, item.username === this.currentUsername))
                .borderRadius(12)
                .border({
                  width: this.getRankBorderWidth(index as number),
                  color: this.getRankBorderColor(index as number, item.username === this.currentUsername),
                  radius: 12
                })
              }
            }, (item: RankItem, index: number) => `${index}`)
          }
          .width('92%')
          .margin({ left: '4%', right: '4%', top: 8 })
        }
        .width('100%')
        .height('100%')
      }
      .size({ width: '100%', height: '100%' })
      .title('好友排名')
      .titleMode(NavigationTitleMode.Mini)
    }
    .height('100%')
    .backgroundColor($r('app.color.primaryBgColor'))
  }
}

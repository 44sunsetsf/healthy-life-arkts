export default class FriendInfo {
  id: number;
  username: string;
  nickname: string;
  password: string;
  experience: number;
  isMe: boolean;

  constructor(id: number = 0, username: string = '', nickname: string = '', password: string = '123123',
    experience: number = 0, isMe: boolean = false) {
    this.id = id;
    this.username = username;
    this.nickname = nickname;
    this.password = password;
    this.experience = experience;
    this.isMe = isMe;
  }
}

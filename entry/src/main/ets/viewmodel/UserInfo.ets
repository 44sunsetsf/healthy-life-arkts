export default class UserInfo {
  id: number;
  username: string;
  avatar: string;
  nickname: string;
  signature: string;
  gender: string;
  birthday: string;
  height: string;
  weight: string;

  constructor(id: number = 0, username: string = '', avatar: string = '', nickname: string = '', signature: string = '',
    gender: string = '', birthday: string = '', height: string = '', weight: string = '') {
    this.id = id;
    this.username = username;
    this.avatar = avatar;
    this.nickname = nickname;
    this.signature = signature;
    this.gender = gender;
    this.birthday = birthday;
    this.height = height;
    this.weight = weight;
  }
}

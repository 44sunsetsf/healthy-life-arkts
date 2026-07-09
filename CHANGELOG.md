# 健康生活项目改动日志

---

## 一、Bug 修复

### 1. 首次添加任务默认状态为已完成的 Bug

**问题描述**：用户首次添加习惯任务时，当天任务自动标记为"已完成"。

**根因**：`HomeViewModel.ets` 的 `updateTaskInfoList` 方法中创建新任务时 `isDone` 硬编码为 `true`，`finValue` 设为 `targetValue`。UI 显示的是内存中的数据，即使数据库写入 `isDone=false`，该方法直接在内存中覆盖。

**文件**: `entry/src/main/ets/viewmodel/HomeViewModel.ets`

```typescript
// 修改前
let task = new TaskInfo(0, dateToStr(new Date()), taskID, targetValue, isAlarm,
  startTime, endTime, frequency, true, targetValue, isOpen);

// 修改后
let task = new TaskInfo(0, dateToStr(new Date()), taskID, targetValue, isAlarm,
  startTime, endTime, frequency, false, '', isOpen);
```

**文件**: `entry/src/main/ets/viewmodel/TaskViewModel.ets:132`

```typescript
// 修改前
taskInfo.isDone = true;

// 修改后
taskInfo.isDone = false;
```

---

### 2. 设置提醒频率时，已设置的频率未默认勾选

**问题描述**：编辑已有任务时，打开频率设置对话框，之前已选中的频率未勾选。

**根因**：`FrequencyDialog` 的 `frequencyChooseRange` 由 `frequencyRange()` 生成，所有 `isChecked` 初始为 `false`，未读取 `settingParams.frequency` 已有值。`Toggle` 组件也没有绑定 `isOn` 参数。

**文件**: `entry/src/main/ets/view/dialog/TaskSettingDialog.ets`

```typescript
// 修改前
private frequencyChooseRange: FrequencyContentType[] = frequencyRange();

// 修改后
private frequencyChooseRange: FrequencyContentType[] = FrequencyDialog.initFrequencyChooseRange(this.settingParams?.frequency);

static initFrequencyChooseRange(frequencyStr: string): FrequencyContentType[] {
  const range = frequencyRange();
  if (!frequencyStr || frequencyStr === '') {
    return range;
  }
  const selectedIds = frequencyStr.split(',').map(item => Number(item.trim()));
  range.forEach((item) => {
    if (selectedIds.includes(item.id)) {
      item.isChecked = true;
    }
  });
  return range;
}
```

```typescript
// 修改前
Toggle({ type: ToggleType.Checkbox })
  .onChange((isOn) => {
    item.isChecked = isOn;
  })

// 修改后
Toggle({ type: ToggleType.Checkbox, isOn: item.isChecked })
  .onChange((isOn) => {
    item.isChecked = isOn;
  })
```

---

### 3. 个人资料保存功能异常

**问题描述**：点击保存按钮后数据未能写入数据库。

**根因**：
1. `UserInfoApi` 的 `insertData`/`updateData`/`query` 方法缺少 `.catch()` 错误处理，异常被静默吞掉。
2. `ProfilePage.saveUserInfo` 中先 query 再 insert/update 的异步嵌套存在竞态。

**文件**: `entry/src/main/ets/common/database/tables/UserInfoApi.ets`

```typescript
// 修改前
insertData(userInfo: UserInfo, callback: Function): void {
  const valueBucket = generateBucket(userInfo);
  RdbUtils.insert(Const.USER_INFO.tableName, valueBucket).then(result => {
    callback(result);
  });
  Logger.info('UserInfoTable', 'Insert userInfo finished.');
}

// 修改后
insertData(userInfo: UserInfo, callback: Function): void {
  const valueBucket = generateBucket(userInfo);
  RdbUtils.insert(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', valueBucket).then(result => {
    callback(result);
  }).catch((err: Error) => {
    Logger.error('UserInfoTable', `Insert userInfo failed: ${JSON.stringify(err)}`);
    callback(0);
  });
}
```

新增 `insertOrUpdateData` 方法，将查询-判断-写入封装在同一次调用链内：

```typescript
// 新增
insertOrUpdateData(userInfo: UserInfo, callback: Function): void {
  this.query((result: UserInfo | null) => {
    if (result) {
      this.updateData(userInfo, callback);
    } else {
      this.insertData(userInfo, callback);
    }
  });
}
```

**文件**: `entry/src/main/ets/pages/ProfilePage.ets`

```typescript
// 修改前
saveUserInfo() {
  let userInfo = new UserInfo(0, this.avatar, this.nickname, this.gender, this.birthday, this.userHeight, this.userWeight);
  UserInfoApi.query((result: UserInfo | null) => {
    if (result) {
      UserInfoApi.updateData(userInfo, (flag: number) => {
        if (flag) { prompt.showToast({ message: '保存成功' }); }
      });
    } else {
      UserInfoApi.insertData(userInfo, (flag: number) => {
        if (flag) { prompt.showToast({ message: '保存成功' }); }
      });
    }
  });
}

// 修改后
saveUserInfo() {
  let userInfo = new UserInfo(0, this.avatar, this.nickname, this.signature, this.gender, this.birthday, this.userHeight, this.userWeight);
  UserInfoApi.insertOrUpdateData(userInfo, (flag: number) => {
    if (flag) {
      prompt.showToast({ message: '保存成功' });
    } else {
      prompt.showToast({ message: '保存失败' });
    }
  });
}
```

---

### 4. "我的"页面显示死数据

**问题描述**：从个人资料页保存后返回"我的"页面，头像/昵称/签名仍显示初始常量值。

**根因**：`MineIndex` 是 `@Component`（非 `@Entry`），`onPageShow` 生命周期钩子仅对 `@Entry` 页面有效，组件不会被触发刷新。

**文件**: `entry/src/main/ets/pages/MinePage.ets`

```typescript
// 修改前
@Component
export struct MineIndex {
  @State nickname: string = Const.NICK_NAME;
  @State signature: string = Const.SIGNATURE;

  aboutToAppear() {
    UserInfoApi.query((result: UserInfo | null) => {
      if (result) {
        this.nickname = result.nickname || Const.NICK_NAME;
        this.signature = result.signature || Const.SIGNATURE;
      }
    });
  }

  onPageShow() { ... } // 无效，@Component 无此生命周期

  build() {
    Column() {
      UserBaseInfo({ nickname: this.nickname, signature: this.signature });
      ListInfo();
    }
  }
}

// 修改后
@Component
export struct MineIndex {
  @State nickname: string = Const.NICK_NAME;
  @State signature: string = '';
  @State avatar: string = '';

  loadUserInfo() {
    UserInfoApi.query((result: UserInfo | null) => {
      if (result) {
        this.nickname = result.nickname || Const.NICK_NAME;
        this.signature = result.signature || '';
        this.avatar = result.avatar;
      }
    });
  }

  build() {
    Column() {
      UserBaseInfo({ nickname: this.nickname, signature: this.signature, avatar: this.avatar });
      ListInfo();
    }
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
      if (isVisible && currentRatio > 0.0) {
        this.loadUserInfo();
      }
    })
  }
}
```

---

### 5. 数据库列迁移失败 (错误码 14800013 + 14800021)

**问题描述**：查询报 14800013（列不存在），插入报 14800021（约束失败）。旧数据库 `userInfo` 表缺少 `signature` 列。

**根因**：`createTable` 使用 `create table if not exists`，表已存在时不报错走 `.then()`，但也不会重建表。之前将 `addTableColumn` 仅放在 `.catch()` 中，永远不会执行。且 `addTableColumn` 是 fire-and-forget 异步调用，存在时序竞争。

**文件**: `entry/src/main/ets/entryability/EntryAbility.ets`

```typescript
// 修改前
RdbUtils.createTable(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', columnUserInfoList)
  .then(() => {
    Logger.info(`RdbHelper createTable userInfo success`);
  })
  .catch((err: Error) => {
    // addTableColumn 仅在 catch 中，createTable 因 if not exists 永远走 then
    RdbUtils.addTableColumn(...).catch(() => {});
  });

// 修改后 — 用 await 确保顺序，创建表后始终尝试添加列
await RdbUtils.createTable(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', columnUserInfoList)
  .then(() => {
    Logger.info(`RdbHelper createTable userInfo success`);
  }).catch((err: Error) => {
    Logger.error(`RdbHelper userInfo createTable err : ${JSON.stringify(err)}`);
  });
await RdbUtils.addTableColumn(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '',
  new ColumnInfo('signature', 'text', -1, false, false, false)).then(() => {
  Logger.info(`RdbHelper addColumn signature success`);
}).catch(() => {});
```

---

### 6. 编译错误修复

**错误1**：`UserInfoApi.ets` — `Const.USER_INFO.tableName` 可能为 `undefined`

```typescript
// 修改前
RdbUtils.insert(Const.USER_INFO.tableName, valueBucket)
new dataRdb.RdbPredicates(Const.USER_INFO.tableName)

// 修改后（与其他 Api 文件写法一致）
RdbUtils.insert(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', valueBucket)
new dataRdb.RdbPredicates(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '')
```

**错误2**：`ProfilePage.ets` — DatePicker 返回值类型可能为 `undefined`

```typescript
// 修改前
let month = (value.month as number) + 1;

// 修改后
let year = value.year as number;
let month = (value.month as number) + 1;
let day = value.day as number;
```

**错误3**：`ProfilePage.ets` — `height`/`weight` 与 `CustomComponent` 基类属性冲突

```typescript
// 修改前
@State height: string = '';
@State weight: string = '';

// 修改后
@State userHeight: string = '';
@State userWeight: string = '';
```

---

### 7. 签名为空时显示"暂无个性签名"

**文件**: `entry/src/main/ets/view/UserBaseInfo.ets`

```typescript
// 修改前
Text(this.signature).fontSize($r('app.float.default_16')).fontWeight(FontWeight.Normal)

// 修改后
Text(this.signature || '暂无个性签名').fontSize($r('app.float.default_16')).fontWeight(FontWeight.Normal)
```

---

### 8. 每日刷牙和每日微笑无法修改目标设置

**问题描述**：编辑"每日微笑"或"每日刷牙"任务时，目标设置项不可点击。

**根因**：`TaskDetailComponent.ets` 中 `.enabled()` 硬编码排除了 `taskType.smile` 和 `taskType.brushTeeth`。同时 `TargetSettingDialog` 中 `TextPicker` 只区分了喝水和苹果范围，没有为微笑/刷牙提供次数选择。

**文件1**: `entry/src/main/ets/view/task/TaskDetailComponent.ets`

```typescript
// 修改前
.enabled(
  this.settingParams?.isOpen
  && this.settingParams?.taskID !== taskType.smile
  && this.settingParams?.taskID !== taskType.brushTeeth
)

// 修改后
.enabled(
  this.settingParams?.isOpen
)
```

**文件2**: `entry/src/main/ets/viewmodel/TaskViewModel.ets`

```typescript
// 新增
export const createTimesRange = () => {
  const timesRangeArr: Array<string> = [];
  for (let i = 1; i <= Const.TIMES_50; i++) {
    timesRangeArr.push(`${i} 次`);
  }
  return timesRangeArr;
}
```

**文件3**: `entry/src/main/ets/view/dialog/TaskSettingDialog.ets`

```typescript
// 修改前
TextPicker({ range: this.settingParams?.taskID === taskType.drinkWater ? this.drinkRange : this.appleRange })

// 修改后
let range: string[] = this.appleRange;
if (this.settingParams?.taskID === taskType.drinkWater) {
  range = this.drinkRange;
} else if (this.settingParams?.taskID === taskType.smile || this.settingParams?.taskID === taskType.brushTeeth) {
  range = this.timesRange;
}
TextPicker({ range: range })
```

---

## 二、新增功能

### 1. 个人资料展示和编辑功能

**功能描述**：点击"我的"页面中的"个人资料"进入个人资料页面，可展示并修改头像、昵称、性别、出生日期、身高、体重。支持保存到数据库持久化。

#### 新增文件

**文件**: `entry/src/main/ets/viewmodel/UserInfo.ets`

```typescript
export default class UserInfo {
  id: number;
  avatar: string;
  nickname: string;
  signature: string;
  gender: string;
  birthday: string;
  height: string;
  weight: string;

  constructor(id: number = 0, avatar: string = '', nickname: string = '', signature: string = '',
    gender: string = '', birthday: string = '', height: string = '', weight: string = '') {
    this.id = id;
    this.avatar = avatar;
    this.nickname = nickname;
    this.signature = signature;
    this.gender = gender;
    this.birthday = birthday;
    this.height = height;
    this.weight = weight;
  }
}
```

**文件**: `entry/src/main/ets/common/database/tables/UserInfoApi.ets`

```typescript
class UserInfoApi {
  insertData(userInfo: UserInfo, callback: Function): void { ... }
  updateData(userInfo: UserInfo, callback: Function): void { ... }
  query(callback: Function): void { ... }
  insertOrUpdateData(userInfo: UserInfo, callback: Function): void { ... }
}
```

**文件**: `entry/src/main/ets/pages/ProfilePage.ets`

- 页面结构：Navigation + 表单列表（头像/昵称/个性签名/性别/出生日期/身高/体重）+ 保存按钮
- 5个 CustomDialog：NicknameDialog、SignatureDialog、GenderDialog、BirthdayDialog、HeightDialog、WeightDialog
- 头像点击调用 DocumentViewPicker 选择图片
- 保存调用 `UserInfoApi.insertOrUpdateData`

#### 修改文件

**文件**: `entry/src/main/ets/common/constants/CommonConstants.ets`

```typescript
// 新增
static readonly USER_INFO = {
  tableName: 'userInfo',
  columns: ['id', 'avatar', 'nickname', 'signature', 'gender', 'birthday', 'height', 'weight']
} as CommonConstantsInfo
```

**文件**: `entry/src/main/ets/model/RdbColumnModel.ets`

```typescript
// 新增
export const columnUserInfoList: Array<ColumnInfo> = [
  new ColumnInfo('id', 'integer', -1, true, true, false),
  new ColumnInfo('avatar', 'text', -1, false, false, false),
  new ColumnInfo('nickname', 'text', -1, false, false, false),
  new ColumnInfo('signature', 'text', -1, false, false, false),
  new ColumnInfo('gender', 'text', -1, false, false, false),
  new ColumnInfo('birthday', 'text', -1, false, false, false),
  new ColumnInfo('height', 'text', -1, false, false, false),
  new ColumnInfo('weight', 'text', -1, false, false, false)
];
```

**文件**: `entry/src/main/ets/entryability/EntryAbility.ets`

- 导入 `columnUserInfoList`、`ColumnInfo`
- onCreate 中新增 `await createTable('userInfo', columnUserInfoList)` + `await addTableColumn('signature')` 列迁移

**文件**: `entry/src/main/ets/view/ListInfo.ets`

```typescript
// 新增
import router from '@ohos.router';

// ForEach 内新增 .onClick
.onClick(() => {
  if (item.id === '1') {
    router.pushUrl({ url: 'pages/ProfilePage' });
  }
})
```

**文件**: `entry/src/main/resources/base/profile/main_pages.json`

```json
// 新增
"pages/ProfilePage"
```

---

### 2. 个性签名功能

**功能描述**：个人资料页新增"个性签名"编辑项；"我的"页面根据数据库内容显示签名，未设置时显示"暂无个性签名"。

**文件**: `entry/src/main/ets/viewmodel/UserInfo.ets` — 新增 `signature` 字段

**文件**: `entry/src/main/ets/common/constants/CommonConstants.ets` — `USER_INFO.columns` 新增 `'signature'`

**文件**: `entry/src/main/ets/model/RdbColumnModel.ets` — `columnUserInfoList` 新增 `signature` 列定义

**文件**: `entry/src/main/ets/common/database/tables/UserInfoApi.ets` — query 和 generateBucket 新增 signature 读写

**文件**: `entry/src/main/ets/pages/ProfilePage.ets` — 新增 SignatureDialog + 个性签名编辑行

**文件**: `entry/src/main/ets/view/UserBaseInfo.ets`

```typescript
// 修改前
Text(this.signature).fontSize($r('app.float.default_16')).fontWeight(FontWeight.Normal)

// 修改后
Text(this.signature || '暂无个性签名').fontSize($r('app.float.default_16')).fontWeight(FontWeight.Normal)
```

---

### 3. "我的"页面显示用户头像、昵称、个性签名

**功能描述**：从数据库读取用户个人信息，动态显示头像、昵称和签名。

**文件**: `entry/src/main/ets/view/UserBaseInfo.ets`

```typescript
// 修改前
@Prop nickname: string = '';
@Prop signature: string = '';
Image($r('app.media.ic_user'))
  .objectFit(ImageFit.Contain)

// 修改后
@Prop nickname: string = '';
@Prop signature: string = '';
@Prop avatar: string = '';
Image(this.avatar ? this.avatar : $r('app.media.ic_user'))
  .objectFit(ImageFit.Cover)
  .borderRadius(33)
```

**文件**: `entry/src/main/ets/pages/MinePage.ets`

```typescript
// 修改前 — 使用硬编码常量
@State nickname: string = Const.NICK_NAME;
@State signature: string = Const.SIGNATURE;
UserBaseInfo({ nickname: this.nickname, signature: this.signature });

// 修改后 — 从数据库读取，onVisibleAreaChange 自动刷新
@State nickname: string = Const.NICK_NAME;
@State signature: string = '';
@State avatar: string = '';
UserBaseInfo({ nickname: this.nickname, signature: this.signature, avatar: this.avatar });
```

---

### 4. 头像从文件系统上传图片

**功能描述**：点击头像可从文件系统选择图片文件，限制只能选择 jpg/jpeg/png/gif/bmp/webp 格式。

**文件**: `entry/src/main/ets/pages/ProfilePage.ets`

```typescript
// 修改前 — PhotoViewPicker 只能从相册选择
pickAvatar() {
  let photoSelectOptions = new picker.PhotoSelectOptions();
  photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
  photoSelectOptions.maxSelectNumber = 1;
  let photoViewPicker = new picker.PhotoViewPicker();
  photoViewPicker.select(photoSelectOptions).then((photoSelectResult: picker.PhotoSelectResult) => {
    if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
      this.avatar = photoSelectResult.photoUris[0];
    }
  }).catch(...);
}

// 修改后 — DocumentViewPicker 从文件系统选择，fileSuffixFilters 限制图片格式
pickAvatar() {
  let documentSelectOptions = new picker.DocumentSelectOptions();
  documentSelectOptions.maxSelectNumber = 1;
  documentSelectOptions.fileSuffixFilters = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
  let documentViewPicker = new picker.DocumentViewPicker();
  documentViewPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
    if (documentSelectResult && documentSelectResult.length > 0) {
      this.avatar = documentSelectResult[0];
    }
  }).catch(...);
}
```

---

### 5. 微笑/刷牙目标次数选择

**功能描述**：每日微笑和每日刷牙任务新增目标次数选择器（1-50次），使用"次"作为单位。

**文件**: `entry/src/main/ets/viewmodel/TaskViewModel.ets` — 新增 `createTimesRange()`

**文件**: `entry/src/main/ets/view/dialog/TaskSettingDialog.ets` — 新增 `timesRange` 属性，TextPicker 区分任务类型选择不同范围

---

### 9. 已打卡任务卡片按钮显示为灰色"已打卡"

**问题描述**：任务打卡后再次点击，弹出的卡片中打卡按钮仍为白色可点击状态，用户无法区分是否已打卡。

**根因**：`TaskDetailDialog` 中 `showButton` 始终为 `true`，未根据 `currentTask.isDone` 动态调整按钮状态。`TaskClock` 组件只渲染了一个打卡按钮，没有已打卡的灰色状态。

**文件**: `entry/src/main/ets/view/dialog/TaskDetailDialog.ets`

```typescript
// 修改前 — TaskDetailDialog
@State showButton: boolean = true;
TaskClock({
  confirm: () => { ... },
  cancel: () => { ... },
  showButton: this.showButton
})

// 修改后 — 传入 isDone 状态
TaskClock({
  confirm: () => { ... },
  cancel: () => { ... },
  isDone: this.currentTask?.isDone || false
})
```

```typescript
// 修改前 — TaskClock
showButton: boolean = false;
Button() {
  Text($r('app.string.clock_in'))
    ...
}
.backgroundColor('rgba(255,255,255,0.40)')
.visibility(!this.showButton ? Visibility.None : Visibility.Visible)
.onClick(() => { this.confirm(); })

// 修改后 — 根据 isDone 显示不同按钮
isDone: boolean = false;
if (this.isDone) {
  Button() {
    Text($r('app.string.task_done'))  // "已完成"
      ...
  }
  .backgroundColor('rgba(200,200,200,0.50)')  // 灰色背景
  .enabled(false)  // 禁用点击
} else {
  Button() {
    Text($r('app.string.clock_in'))  // "打卡"
      ...
  }
  .backgroundColor('rgba(255,255,255,0.40)')
  .onClick(() => { this.confirm(); })
}
```

---

### 10. 微笑/刷牙目标设置文字颜色修复

**问题描述**：开启每日微笑或每日刷牙后，目标设置项文字和箭头仍为灰色，让用户感觉无法点击。

**根因**：`TaskEditListItem.ets` 中 `targetSettingStyle` 的 `fontColor` 条件硬编码排除了微笑和刷牙任务。

**文件**: `entry/src/main/ets/view/task/TaskEditListItem.ets`

```typescript
// 修改前
@Extend(Text) function targetSettingStyle(isOpen: boolean, taskID: number) {
  .fontColor(isOpen && taskID !== taskType.smile && taskID !== taskType.brushTeeth ?
  $r('app.color.titleColor') :
  $r('app.color.disabledColor'))
}

// 修改后
@Extend(Text) function targetSettingStyle(isOpen: boolean, taskID: number) {
  .fontColor(isOpen ?
  $r('app.color.titleColor') :
  $r('app.color.disabledColor'))
}
```

---

### 11. TargetSettingDialog 编译错误修复

**问题描述**：ArkUI 的 `build()` 中不允许声明局部变量和赋值语句（错误码 10905209/10905204）。

**根因**：在 `else` 分支中使用 `let range` 变量赋值和 `if` 逻辑分支，不符合 ArkUI 声明式 UI 语法规范。

**文件**: `entry/src/main/ets/view/dialog/TaskSettingDialog.ets`

```typescript
// 修改前 — else 分支中用变量赋值
} else {
  let range: string[] = this.appleRange;
  if (this.settingParams?.taskID === taskType.drinkWater) {
    range = this.drinkRange;
  } else if (...) {
    range = this.timesRange;
  }
  TextPicker({ range: range })
    ...
}

// 修改后 — 拆分为独立的 if-else if-else 分支
} else if (this.settingParams?.taskID === taskType.drinkWater) {
  TextPicker({ range: this.drinkRange })
    ...
} else if (this.settingParams?.taskID === taskType.smile || this.settingParams?.taskID === taskType.brushTeeth) {
  TextPicker({ range: this.timesRange })
    ...
} else {
  TextPicker({ range: this.appleRange })
    ...
}
```

---

### 12. 经验值系统

**功能描述**：打卡任务后获得20经验值，每100经验值升一级。我的页面动态显示等级和经验值，新增排名导航栏展示好友排名。

**文件**: `entry/src/main/ets/viewmodel/GlobalInfo.ets` — 新增 `experience` 字段

**文件**: `entry/src/main/ets/common/constants/CommonConstants.ets` — `GLOBAL_INFO.columns` 新增 `'experience'`

**文件**: `entry/src/main/ets/model/RdbColumnModel.ets` — `columnGlobalInfoList` 新增 `experience` 列

**文件**: `entry/src/main/ets/common/database/tables/GlobalInfoApi.ets` — query 和 generateBucket 新增 experience 读写

**文件**: `entry/src/main/ets/entryability/EntryAbility.ets` — onCreate 中 await addTableColumn('experience')

**文件**: `entry/src/main/ets/viewmodel/HomeViewModel.ets`

```typescript
// 新增常量和方法
static readonly EXP_PER_CLOCK: number = 20;
static readonly EXP_PER_LEVEL: number = 100;

// taskClock 中打卡完成后增加经验值
if (taskItem.isDone) {
  await this.addExperience(HomeStore.EXP_PER_CLOCK);
  ...
}

// 新增方法
addExperience(exp: number): Promise<void>
static getLevel(experience: number): number
static getLevelExp(experience: number): number
```

**文件**: `entry/src/main/ets/view/UserBaseInfo.ets` — 等级从固定 "LV.7" 改为动态显示，新增经验值显示和动画

```typescript
// 修改前
Text('LV.7')

// 修改后
Text(`LV.${this.displayLevel}`)
Row() {
  Text(`${this.displayExp}`)
  Text(`/${HomeStore.EXP_PER_LEVEL}经验`)
}
```

### 13. 排名功能

**功能描述**：新增底部导航"排名"Tab，展示用户与5个好友的等级排名列表（好友数据写死），按经验值降序排列。

**新增文件**: `entry/src/main/ets/pages/RankPage.ets` — 排名页面，包含5个写死好友数据 + 当前用户，按经验值排序

**文件**: `entry/src/main/ets/model/NavItemModel.ets` — TabId 新增 RANK，NavList 新增排名导航项

**文件**: `entry/src/main/ets/pages/MainPage.ets` — 新增 RankIndex TabContent

**文件**: `entry/src/main/resources/base/element/string.json` — 新增 `tab_rank` 字符串资源

**文件**: `entry/src/main/resources/base/profile/main_pages.json` — 移除 `pages/RankPage`（作为 TabContent 嵌入不需要路由）

---

### 14. 经验值动画和排名数据刷新修复

**问题描述**：打卡后经验值无动画增加，排名页数据不变。

**根因**：打卡发生在 Home tab，经验值变化无法跨组件传递到 Mine tab 的 UserBaseInfo 和 Rank tab 的 RankIndex。

**修复方案**：使用 `AppStorage` 跨组件共享经验值变化。

**文件**: `entry/src/main/ets/viewmodel/HomeViewModel.ets` — `addExperience` 写入 `AppStorage` 存储 `experienceOld`/`experienceNew`/`experienceCurrent`

```typescript
// 新增
AppStorage.SetOrCreate('experienceOld', oldExp);
AppStorage.SetOrCreate('experienceNew', res.experience);
AppStorage.SetOrCreate('experienceCurrent', res.experience);
```

**文件**: `entry/src/main/ets/view/UserBaseInfo.ets` — 用 `@StorageLink` 监听经验值变化，`onVisibleAreaChange` 时调用 `startExpAnimation` 触发递增动画

**文件**: `entry/src/main/ets/pages/RankPage.ets` — 用 `@StorageLink('experienceCurrent') @Watch('onExpChange')` 监听变化自动刷新排名数据

---

### 15. 经验值动画起点修正 + 打卡按钮响应式修复

**问题描述**：
1. 首次打卡时经验值动画从0跳起，而非从当前经验值开始递增
2. `TaskClock.isDone` 为普通属性（非响应式），打卡后对话框内按钮不会从"打卡"变为"已完成"
3. 经验值动画完全不触发（核心问题）

**根因**：
1. `loadExpInfo` 初始化时只设置了 `experienceCurrent`，未设置 `experienceOld`，导致首次打卡时 `experienceOld` 为默认值 0
2. `TaskClock` 的 `isDone` 是 `boolean` 类型普通属性，不是 `@State` 或 `@Prop`，值变化不会触发 UI 重新渲染
3. **动画仅依赖 `onVisibleAreaChange` 触发**，但打卡时用户在 Home Tab，Mine Tab 不可见，`onVisibleAreaChange` 不会触发。且 Tabs 懒加载时非当前 Tab 组件可能未创建，`@StorageLink` 未绑定，`AppStorage` 写入后无人监听

**修复方案**：使用 `@Watch` 监听 `experienceNew` 变化直接启动动画，不再仅依赖 `onVisibleAreaChange`

**文件**: `entry/src/main/ets/view/UserBaseInfo.ets`

```typescript
// 修改前
@StorageLink('experienceNew') experienceNew: number = 0;
// 动画仅在 onVisibleAreaChange 中触发

// 修改后
@StorageLink('experienceNew') @Watch('onExpNewChange') experienceNew: number = 0;

onExpNewChange() {
  if (this.experienceNew > 0 && this.lastAnimatedNew !== this.experienceNew) {
    this.lastAnimatedNew = this.experienceNew;
    this.startExpAnimation(this.experienceOld, this.experienceNew);
  }
}

// loadExpInfo 中也增加动画触发逻辑（处理 Tab 懒加载首次创建场景）
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
```

**文件**: `entry/src/main/ets/view/dialog/TaskDetailDialog.ets`

```typescript
// 修改前 — TaskClock
isDone: boolean = false;
.onClick(() => {
  GlobalContext.getContext().setObject('taskListChange', true);
  this.confirm();
})

// 修改后 — isDone 改为 @State 响应式，打卡时同步更新
@State isDone: boolean = false;
.onClick(() => {
  GlobalContext.getContext().setObject('taskListChange', true);
  this.isDone = true;
  this.confirm();
})
```

---

## 二、新增功能（续）

### 16. 打卡经验增加弹窗 + Level Up 升级动画

**功能描述**：打卡成功后在当前页面（首页）立即弹出经验增加动画弹窗（显示 `+20 EXP` 数字递增），如果经验增加导致升级则紧接着弹出 Level Up 升级动画弹窗。

**新增文件**: `entry/src/main/ets/view/dialog/ExpGainPopup.ets`

- `ExpGainPopup` 组件：橙色圆角胶囊弹窗，从下方滑入，数字从0递增到实际获得经验值，1.8秒后淡出上移消失
- `LevelUpPopup` 组件：金色光晕背景 + "LEVEL UP!" + "LV.X" 大字，弹簧缩放动画进入，金色光晕扩散消失，2.2秒后淡出消失

**文件**: `entry/src/main/ets/viewmodel/AchievementInfo.ets`

```typescript
// 新增字段
expGained: number = 0;
oldLevel: number = 0;
newLevel: number = 0;
isLevelUp: boolean = false;
```

**文件**: `entry/src/main/ets/viewmodel/HomeViewModel.ets`

```typescript
// addExperience 返回值从 Promise<void> 改为 Promise<{expGained, oldLevel, newLevel}>
addExperience(exp: number): Promise<{ expGained: number, oldLevel: number, newLevel: number }>

// taskClock 返回的 AchievementInfo 填充 expGained/oldLevel/newLevel/isLevelUp
```

**文件**: `entry/src/main/ets/view/HomeComponent.ets`

```typescript
// 打卡成功后触发弹窗
onConfirm(task: TaskInfo) {
  this.homeStore.taskClock(task).then((res: AchievementInfo) => {
    if (res.expGained > 0) {
      this.expGained = res.expGained;
      this.showExpPopup = true;
    }
    if (res.isLevelUp) {
      this.levelUpLevel = res.newLevel;
      setTimeout(() => { this.showLevelUpPopup = true; }, 2200);
    }
    // ...achievement logic
  })
}

// build() Stack 中条件渲染弹窗（hitTestBehavior: Transparent 不拦截触摸）
if (this.showExpPopup) { ExpGainPopup(...) }
if (this.showLevelUpPopup) { LevelUpPopup(...) }
```

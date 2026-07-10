# Bug 修复汇总

本文档记录了健康生活项目中修复的全部 10 个 Bug，并附带修改前后的代码对比。

---

## Bug 1：首次添加任务默认状态为已完成

**问题描述**：用户首次添加习惯任务时，当天任务自动标记为"已完成"。

**根因**：创建新任务时 `isDone` 硬编码为 `true`，`finValue` 设为 `targetValue`。

**修复代码**：

`HomeViewModel.ets`：

```typescript
// 修改前
let task = new TaskInfo(0, dateToStr(new Date()), taskID, targetValue, isAlarm,
  startTime, endTime, frequency, true, targetValue, isOpen);

// 修改后
let task = new TaskInfo(0, dateToStr(new Date()), taskID, targetValue, isAlarm,
  startTime, endTime, frequency, false, '', isOpen);
```

`TaskViewModel.ets`：

```typescript
// 修改前
taskInfo.isDone = true;

// 修改后
taskInfo.isDone = false;
```

---

## Bug 2：提醒频率未默认勾选

**问题描述**：编辑已有任务时，打开频率设置对话框，之前已选中的频率未勾选。

**根因**：`FrequencyDialog` 的所有 `isChecked` 初始为 `false`，未读取已有频率。`Toggle` 组件未绑定 `isOn` 参数。

**修复代码**：

`TaskSettingDialog.ets`：

```typescript
// 修改前
private frequencyChooseRange: FrequencyContentType[] = frequencyRange();

// 修改后
private frequencyChooseRange: FrequencyContentType[] =
  FrequencyDialog.initFrequencyChooseRange(this.settingParams?.frequency);

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
  .onChange((isOn) => { item.isChecked = isOn; })

// 修改后
Toggle({ type: ToggleType.Checkbox, isOn: item.isChecked })
  .onChange((isOn) => { item.isChecked = isOn; })
```

---

## Bug 3：个人资料保存失败

**问题描述**：编辑个人资料后保存，数据未成功写入数据库。

**根因**：`UserInfoApi` 缺少 `.catch()` 错误处理，异常被静默吞掉。先 query 再 insert/update 的异步嵌套存在竞态。

**修复代码**：

`UserInfoApi.ets`：

```typescript
// 修改前
insertData(userInfo: UserInfo, callback: Function): void {
  const valueBucket = generateBucket(userInfo);
  RdbUtils.insert(Const.USER_INFO.tableName, valueBucket).then(result => {
    callback(result);
  });
}

// 修改后 — 增加 .catch() 错误处理
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

新增 `insertOrUpdateData` 方法，封装查询-判断-写入：

```typescript
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

`ProfilePage.ets`：

```typescript
// 修改前
saveUserInfo() {
  UserInfoApi.query((result: UserInfo | null) => {
    if (result) {
      UserInfoApi.updateData(userInfo, (flag: number) => { ... });
    } else {
      UserInfoApi.insertData(userInfo, (flag: number) => { ... });
    }
  });
}

// 修改后
saveUserInfo() {
  let userInfo = new UserInfo(0, username, this.avatar, this.nickname, this.signature,
    this.gender, this.birthday, this.userHeight, this.userWeight);
  UserInfoApi.insertOrUpdateData(userInfo, (flag: number) => {
    if (flag) { prompt.showToast({ message: '保存成功' }); }
    else { prompt.showToast({ message: '保存失败' }); }
  });
}
```

---

## Bug 4："我的"页面显示死数据

**问题描述**："我的"页面始终显示固定的假数据，不会根据当前登录用户变化。

**根因**：`MineIndex` 是 `@Component`（非 `@Entry`），`onPageShow` 生命周期钩子仅对 `@Entry` 页面有效，组件不会被触发刷新。

**修复代码**：

`MinePage.ets`：

```typescript
// 修改前
@Component
export struct MineIndex {
  @State nickname: string = Const.NICK_NAME;
  @State signature: string = Const.SIGNATURE;

  aboutToAppear() {
    UserInfoApi.query((result: UserInfo | null) => { ... });
  }

  onPageShow() { ... } // 无效，@Component 无此生命周期

  build() {
    Column() {
      UserBaseInfo({ nickname: this.nickname, signature: this.signature });
      ListInfo();
    }
  }
}

// 修改后 — 使用 onVisibleAreaChange 替代无效的 onPageShow
@Component
export struct MineIndex {
  @State nickname: string = Const.NICK_NAME;
  @State signature: string = '';
  @State avatar: string = '';

  loadUserInfo() {
    let currentUser = GlobalContext.getContext().getObject('currentUser') as FriendInfo;
    if (currentUser && currentUser.username) {
      UserInfoApi.queryByUsername(currentUser.username, (result: UserInfo | null) => {
        if (result) {
          this.nickname = result.nickname || currentUser.nickname;
          this.signature = result.signature || '';
          this.avatar = result.avatar;
        } else {
          this.nickname = currentUser.nickname;
        }
      });
    }
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

## Bug 5：数据库升级后新增字段缺失

**问题描述**：应用升级后新增的数据库字段（如 signature、username）在旧数据库中不存在，导致查询报错。

**根因**：`create table if not exists` 表已存在时走 `.then()` 不走 `.catch()`，之前将 `addTableColumn` 仅放在 `.catch()` 中，永远不会执行。

**修复代码**：

`EntryAbility.ets`：

```typescript
// 修改前 — addTableColumn 仅在 catch 中，createTable 因 if not exists 永远走 then
RdbUtils.createTable(Const.USER_INFO.tableName, columnUserInfoList)
  .then(() => { ... })
  .catch((err: Error) => {
    RdbUtils.addTableColumn(...).catch(() => {});
  });

// 修改后 — 用 await 确保顺序，创建表后始终尝试添加列
await RdbUtils.createTable(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', columnUserInfoList)
  .then(() => { Logger.info('createTable userInfo success'); })
  .catch((err: Error) => { Logger.error(`createTable err: ${JSON.stringify(err)}`); });

await RdbUtils.addTableColumn(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '',
  new ColumnInfo('signature', 'text', -1, false, false, false)).then(() => {
  Logger.info('addColumn signature success');
}).catch(() => {});
```

---

## Bug 6：编译错误（类型安全/属性冲突）

**问题描述**：部分代码存在空值未保护和属性名与基类冲突的编译错误。

**修复代码**：

错误1 — 空值保护（`UserInfoApi.ets`）：

```typescript
// 修改前
RdbUtils.insert(Const.USER_INFO.tableName, valueBucket)

// 修改后
RdbUtils.insert(Const.USER_INFO.tableName ? Const.USER_INFO.tableName : '', valueBucket)
```

错误2 — 属性名冲突（`ProfilePage.ets`）：

```typescript
// 修改前 — height/weight 与 CustomComponent 基类属性冲突
@State height: string = '';
@State weight: string = '';

// 修改后
@State userHeight: string = '';
@State userWeight: string = '';
```

---

## Bug 7：签名为空时显示异常

**问题描述**：用户未设置个性签名时，签名区域显示空白或异常。

**修复代码**：

`UserBaseInfo.ets`：

```typescript
// 修改前
Text(this.signature).fontSize($r('app.float.default_16'))

// 修改后
Text(this.signature || '暂无个性签名').fontSize($r('app.float.default_16'))
```

---

## Bug 8：微笑/刷牙目标设置禁用

**问题描述**：微笑和刷牙两类任务无法设置目标次数，文字和箭头显示为灰色。

**根因**：`.enabled()` 和 `fontColor` 条件中硬编码排除了 `taskType.smile` 和 `taskType.brushTeeth`。

**修复代码**：

`TaskDetailComponent.ets`：

```typescript
// 修改前
.enabled(
  this.settingParams?.isOpen
  && this.settingParams?.taskID !== taskType.smile
  && this.settingParams?.taskID !== taskType.brushTeeth
)

// 修改后
.enabled(this.settingParams?.isOpen)
```

`TaskEditListItem.ets`：

```typescript
// 修改前
.fontColor(isOpen && taskID !== taskType.smile && taskID !== taskType.brushTeeth ?
  $r('app.color.titleColor') : $r('app.color.disabledColor'))

// 修改后
.fontColor(isOpen ? $r('app.color.titleColor') : $r('app.color.disabledColor'))
```

`TaskSettingDialog.ets`：

```typescript
// 修改前
TextPicker({ range: this.settingParams?.taskID === taskType.drinkWater ? this.drinkRange : this.appleRange })

// 修改后 — 拆分为 if-else if-else 分支，支持微笑/刷牙的次数范围
if (this.settingParams?.taskID === taskType.drinkWater) {
  TextPicker({ range: this.drinkRange })
} else if (this.settingParams?.taskID === taskType.smile || this.settingParams?.taskID === taskType.brushTeeth) {
  TextPicker({ range: this.timesRange })
} else {
  TextPicker({ range: this.appleRange })
}
```

---

## Bug 9：已打卡任务卡片按钮状态

**问题描述**：完成任务打卡后，任务卡片上的按钮仍显示可点击状态，未变为"已完成"。

**根因**：`TaskClock` 组件只渲染了一个打卡按钮，没有已打卡的灰色状态，且 `isDone` 非响应式。

**修复代码**：

`TaskDetailDialog.ets`：

```typescript
// 修改前
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

`TaskClock` 组件：

```typescript
// 修改前
showButton: boolean = false;
Button() {
  Text($r('app.string.clock_in'))
}
.backgroundColor('rgba(255,255,255,0.40)')
.visibility(!this.showButton ? Visibility.None : Visibility.Visible)
.onClick(() => { this.confirm(); })

// 修改后 — 根据 isDone 显示不同按钮
isDone: boolean = false;
if (this.isDone) {
  Button() {
    Text($r('app.string.task_done'))
  }
  .backgroundColor('rgba(200,200,200,0.50)')
  .enabled(false)
} else {
  Button() {
    Text($r('app.string.clock_in'))
  }
  .backgroundColor('rgba(255,255,255,0.40)')
  .onClick(() => { this.confirm(); })
}
```

---

## Bug 10：经验值动画不触发

**问题描述**：打卡获得经验值后，切换到"我的"页面时经验值数字没有递增动画。

**根因**：仅依赖 `onVisibleAreaChange` 检测，但打卡时"我的"Tab 不可见，`@StorageLink` 虽已写入但无人监听。需要 `@Watch` 监听 AppStorage 中经验值的变化。

**修复代码**：

`UserBaseInfo.ets`：

```typescript
// 修改前 — 仅 onVisibleAreaChange，打卡时 Mine Tab 不可见无法触发
@StorageLink('experienceNew') experienceNew: number = 0;

// 修改后 — 增加 @Watch 监听
@StorageLink('experienceNew') @Watch('onExpNewChange') experienceNew: number = 0;

onExpNewChange() {
  if (this.experienceNew > 0 && this.lastAnimatedNew !== this.experienceNew) {
    this.lastAnimatedNew = this.experienceNew;
    this.startExpAnimation(this.experienceOld, this.experienceNew);
  }
}

startExpAnimation(oldExp: number, newExp: number) {
  let current = oldExp;
  let timer = setInterval(() => {
    current += 1;
    if (current >= newExp) {
      current = newExp;
      clearInterval(timer);
    }
    this.displayLevel = HomeStore.getLevel(current);
    this.displayExp = HomeStore.getLevelExp(current);
  }, 20);
}
```

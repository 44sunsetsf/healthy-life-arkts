# Task Card Progress Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a per-task progress bar to each `TaskCard` in the home page's task list, so users can see at a glance how close each of the day's 6 health tasks (早起/喝水/吃苹果/微笑/刷牙/早睡) is to completion.

**Architecture:** `TaskCardComponent.ets` changes from a single-row layout to a two-row `Column` layout. Row 1 is the existing icon/name/value text (unchanged). Row 2 is a new ArkUI native `Progress` component (`ProgressType.Capsule`), whose fill percentage is computed from the existing `TaskInfo.isDone` / `finValue` / `targetValue` fields already present on every task — no data model or database changes. `HomeComponent.ets` is updated to give the now-taller card more height.

**Tech Stack:** ArkTS / ArkUI declarative UI (HarmonyOS). Native `Progress` component, same API already used in `entry/src/main/ets/progress/pages/ProgressCard.ets`.

## Global Constraints

- Do not modify `WeekCalendarComponent.ets` (the week calendar strip) — out of scope per approved design spec `docs/superpowers/specs/2026-07-09-task-progress-bar-design.md`.
- Do not modify `TaskInfo`, the database schema, or `taskClock`/`updateTask` logic in `HomeViewModel.ets`.
- Reuse existing color resources only: fill color `$r('app.color.blueColor')` (#007DFF), track color `$r('app.color.progress_background_color')` (#08000000). Do not add new colors.
- Reuse existing sizing constants (`CommonConstants.ets`'s `Const.DEFAULT_100`, `Const.DEFAULT_6`, `Const.THOUSANDTH_1000`, etc.) and the `app.float.default_*` dimen resource naming convention (`entry/src/main/resources/base/element/dimen.json`) — do not hardcode raw numbers in component styles.
- **No automated test harness exists in this repository** (no jest/testing-library-style setup for ArkTS components, and no `hvigorw` wrapper or configured HarmonyOS SDK is available in this shell). All verification in this plan is manual, via the DevEco Studio Previewer. Every task's "test" step is a manual visual-verification checklist, not a command to run.

---

### Task 1: Add progress bar to TaskCard and resize the card

**Files:**
- Modify: `entry/src/main/resources/base/element/dimen.json` (add one entry)
- Modify: `entry/src/main/ets/view/home/TaskCardComponent.ets` (full file, currently 82 lines)
- Modify: `entry/src/main/ets/view/HomeComponent.ets:134` (single `.height(...)` call)

**Interfaces:**
- Consumes: `TaskInfo` class (`entry/src/main/ets/viewmodel/TaskInfo.ets`) — fields `isDone: boolean`, `finValue: string`, `targetValue: string`. No changes to this class.
- Consumes: `CommonConstants` (`entry/src/main/ets/common/constants/CommonConstants.ets`) — `Const.DEFAULT_100 = 100`, `Const.DEFAULT_6 = 6`, `Const.THOUSANDTH_1000 = '100%'`, `Const.THOUSANDTH_50 = '5%'`, `Const.THOUSANDTH_33 = '3.3%'`. No changes to this class.
- Produces: no new exports. `TaskCard` component's external props (`taskInfoStr`, `clickAction`) are unchanged, so `HomeComponent.ets` call site keeps the same props and only changes the `.height(...)` resource it passes in.

- [ ] **Step 1: Add a new dimen resource for the taller card height**

Open `entry/src/main/resources/base/element/dimen.json`. Find the `default_72` entry (around line 108) and add a new `default_88` entry right after it, before `default_100`:

```json
    {
      "name": "default_72",
      "value": "72vp"
    },
    {
      "name": "default_88",
      "value": "88vp"
    },
    {
      "name": "default_100",
      "value": "100vp"
    },
```

This follows the file's existing naming convention (`default_<N>` → `<N>vp`) and existing ascending order.

- [ ] **Step 2: Read the current TaskCardComponent.ets to confirm line numbers before editing**

Run: `grep -n "" entry/src/main/ets/view/home/TaskCardComponent.ets`

Expected: 82 lines, matching the content shown in Step 3 below (the file has not changed since this plan was written). If the file differs, stop and re-read it before proceeding — the edit in Step 3 assumes this exact starting content.

- [ ] **Step 3: Replace the whole file with the two-row layout**

Replace the entire contents of `entry/src/main/ets/view/home/TaskCardComponent.ets` with:

```typescript
/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { TaskMapById } from '../../model/TaskInitList';
import HealthText from '../../view/HealthTextComponent';
import { CommonConstants as Const } from '../../common/constants/CommonConstants';
import TaskInfo from '../../viewmodel/TaskInfo';

@Styles function allSize () {
  .width(Const.THOUSANDTH_1000)
  .height(Const.THOUSANDTH_1000)
}

@Extend(Text) function labelTextStyle () {
  .fontSize($r('app.float.default_16'))
  .fontWeight(Const.FONT_WEIGHT_500)
  .opacity(Const.OPACITY_6)
  .fontFamily($r('app.string.HarmonyHeiTi'))
}

@Component
export struct TaskCard {
  @Prop taskInfoStr: string = '';
  clickAction: Function = (isClick: boolean) => {};
  @State taskInfo: TaskInfo = new TaskInfo(-1, '', -1, '', false, '', '', '', false, '', false);

  aboutToAppear() {
    this.taskInfo = JSON.parse(this.taskInfoStr);
  }

  @Builder targetValueBuilder() {
    if (this.taskInfo.isDone) {
      HealthText({ title: '', titleResource: $r('app.string.task_done') })
    } else {
      Row() {
        HealthText({
          title: this.taskInfo.finValue || `--`,
          fontSize: $r('app.float.default_24')
        })
        Text(` / ${this.taskInfo.targetValue} ${TaskMapById[this.taskInfo.taskID - 1].unit}`)
          .labelTextStyle()
          .fontWeight(Const.FONT_WEIGHT_400)
      }
    }
  }

  // Percentage (0-100) this task is complete, for the Progress bar's value.
  // isDone tasks (including time-based ones like getup/sleepEarly, whose
  // targetValue is a time string such as "08: 00" and cannot be parsed as
  // a number) always resolve to 100. Numeric accumulation tasks (drinkWater,
  // eatApple, and future step-based tasks) resolve to their fin/target ratio.
  progressPercent(): number {
    if (this.taskInfo.isDone) {
      return Const.DEFAULT_100;
    }
    const target = Number(this.taskInfo.targetValue);
    const fin = Number(this.taskInfo.finValue);
    if (!target || Number.isNaN(fin)) {
      return 0;
    }
    return Math.min(Const.DEFAULT_100, Math.floor(fin / target * Const.DEFAULT_100));
  }

  build() {
    Column() {
      Row() {
        Row({ space: Const.DEFAULT_6 }) {
          Image(TaskMapById[this.taskInfo.taskID - 1].icon)
            .width($r('app.float.default_36')).height($r('app.float.default_36'))
            .objectFit(ImageFit.Contain)
          HealthText({
            title: '',
            titleResource: TaskMapById[this.taskInfo.taskID - 1].taskName,
            fontFamily: $r('app.string.HarmonyHeiTi')
          })
        }

        this.targetValueBuilder();
      }
      .width(Const.THOUSANDTH_1000)
      .justifyContent(FlexAlign.SpaceBetween)

      Progress({ value: 0, total: Const.DEFAULT_100, type: ProgressType.Capsule })
        .value(this.progressPercent())
        .width(Const.THOUSANDTH_1000)
        .height($r('app.float.default_6'))
        .color($r('app.color.blueColor'))
        .backgroundColor($r('app.color.progress_background_color'))
        .margin({ top: $r('app.float.default_8') })
    }
    .allSize()
    .justifyContent(FlexAlign.Center)
    .borderRadius($r('app.float.default_24'))
    .padding({ left: Const.THOUSANDTH_50, right: Const.THOUSANDTH_33 })
    .backgroundColor($r('app.color.white'))
    .onClick(() => this.clickAction(true))
    .gesture(LongPressGesture().onAction(() => this.clickAction(false)))
  }
}
```

What changed vs. the original file:
- `build()`'s outer container changed from `Row()` to `Column()`, keeping all the same style modifiers (`.allSize()`, `.borderRadius(...)`, `.padding(...)`, `.backgroundColor(...)`, `.onClick(...)`, `.gesture(...)`).
- The original single `Row` (icon + name + value text) is now the first child of that `Column`, with `.width(Const.THOUSANDTH_1000)` and `.justifyContent(FlexAlign.SpaceBetween)` added directly to it (previously these two modifiers were on the outer `Row`).
- Outer container gets `.justifyContent(FlexAlign.Center)` added so the two rows sit centered within the taller card instead of stretching.
- New `progressPercent()` method added.
- New `Progress(...)` component added as the second child of the `Column`, styled per the design spec (Capsule type, blueColor fill, progress_background_color track, 6vp tall, 8vp top margin, full width).

- [ ] **Step 4: Point HomeComponent.ets at the new card height**

In `entry/src/main/ets/view/HomeComponent.ets`, find this block (around line 129-134):

```typescript
                TaskCard({
                  taskInfoStr: JSON.stringify(item),
                  clickAction: (isClick: boolean) => this.taskItemAction(item, isClick)
                })
                  .margin({ bottom: Const.DEFAULT_12 })
                  .height($r('app.float.default_64'))
```

Change `.height($r('app.float.default_64'))` to `.height($r('app.float.default_88'))`:

```typescript
                TaskCard({
                  taskInfoStr: JSON.stringify(item),
                  clickAction: (isClick: boolean) => this.taskItemAction(item, isClick)
                })
                  .margin({ bottom: Const.DEFAULT_12 })
                  .height($r('app.float.default_88'))
```

- [ ] **Step 5: Confirm `TaskCard` has no other call sites that assumed the old height or single-row layout**

Run: `grep -rn "TaskCard\b" entry/src/main/ets --include="*.ets" | grep -v build`

Expected output: only two matches — the `import` and usage in `entry/src/main/ets/view/HomeComponent.ets`, and the `export struct TaskCard` declaration in `entry/src/main/ets/view/home/TaskCardComponent.ets` itself. If any other file references `TaskCard` or `default_64` in a way that assumed the old single-row card, stop and re-evaluate before continuing (this plan does not cover fixing other call sites).

- [ ] **Step 6: Manual verification in DevEco Studio Previewer**

Open the project in DevEco Studio, open `entry/src/main/ets/pages/MainPage.ets` (or the Home page entry point) in the Previewer, and check the task list section for the current day. Since a fresh install has no clocked-in tasks yet, verify these states by clocking tasks in through the UI (tapping a card triggers the existing clock-in dialog — unchanged by this plan) and observing the card after each action:

| Task | Action | Expected progress bar |
|---|---|---|
| 早起 (getup) | Before clocking in | Empty bar (0%) |
| 早起 (getup) | After clocking in | Full bar (100%), text shows "已完成" |
| 喝水 (drinkWater) | Before any clock-in | Empty bar (0%) |
| 喝水 (drinkWater) | After 1 of N clock-ins (not yet target) | Partially filled bar matching `finValue/targetValue`, text still shows "`finValue` / `targetValue` L" |
| 喝水 (drinkWater) | After reaching target | Full bar (100%), text shows "已完成" |
| 早睡 (sleepEarly) | Before clocking in | Empty bar (0%) — confirms the time-string `targetValue` ("08: 00"-style) does not crash `progressPercent()` or produce `NaN`/negative width |

Also verify:
- Card height increase does not clip any text or icon, and does not break the task list's scroll behavior (scroll up/down through all 6 cards).
- Tapping a card still opens the clock-in dialog; long-pressing a card still navigates to the edit page (both gestures unchanged by this plan, but confirm they still fire correctly on the taller card).

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/resources/base/element/dimen.json entry/src/main/ets/view/home/TaskCardComponent.ets entry/src/main/ets/view/HomeComponent.ets
git commit -m "$(cat <<'EOF'
feat: show per-task progress bar on home task cards

Adds a capsule progress bar to each TaskCard reflecting isDone/
finValue/targetValue, and grows the card to fit it. Calendar strip
is unchanged.
EOF
)"
```

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

/**
 * Result of syncing watch health data into today's tasks.
 */
export class WatchSyncResult {
  public synced: boolean = false; // whether any task was written
  public completedTaskNames: Array<string> = [];
  public waterUpdated: boolean = false; // water progressed but target not reached
  public waterFinValue: string = '';
  public achievementLevel: number = 0;
  public showAchievement: boolean = false;
  public message: string = '';
}

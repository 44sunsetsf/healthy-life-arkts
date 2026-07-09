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

import { WatchHealthData } from '../../viewmodel/WatchHealthData';
import { IHealthDataSource } from './IHealthDataSource';

/**
 * Placeholder for the real Huawei Health Service Kit implementation.
 *
 * TODO(real device): implement with @kit.HealthServiceKit
 * 1. Create the app in AGC and apply for Health Kit read scopes
 *    (step count, heart rate, sleep, hydration).
 * 2. Call healthStore.requestAuthorizations(...) before the first query.
 * 3. Query today's daily aggregates and map them into WatchHealthData.
 * 4. Switch USE_MOCK_HEALTH_SOURCE to false in HealthDataSrcMgr.
 * Requires a real HarmonyOS device with the Huawei Health app installed
 * and a paired watch/band; not available on the emulator.
 */
export default class HealthKitDataSource implements IHealthDataSource {
  getSourceName(): string {
    return 'HealthKit';
  }

  isAvailable(): Promise<boolean> {
    return Promise.resolve(false);
  }

  getTodayHealthData(): Promise<WatchHealthData | null> {
    return Promise.resolve<WatchHealthData | null>(null);
  }
}

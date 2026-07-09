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
import { dateToStr, padTo2Digits } from '../../common/utils/Utils';
import Logger from '../../common/utils/Logger';

const MOCK_SYNC_DELAY: number = 400; // ms, simulate bluetooth transfer latency
const MINUTES_OF_HOUR: number = 60;
const MINUTES_OF_DAY: number = 24 * 60;
const MAX_MOCK_STEPS: number = 16000;
const MAX_MOCK_WATER_LITERS: number = 2.5;

/**
 * Mock watch data source for emulator development: returns plausible
 * random data so the auto check-in flow can be exercised end to end.
 */
export default class MockHealthDataSource implements IHealthDataSource {
  private cachedDateStr: string = '';
  private cachedData: WatchHealthData | null = null;

  getSourceName(): string {
    return 'MockWatch';
  }

  isAvailable(): Promise<boolean> {
    return Promise.resolve(true);
  }

  getTodayHealthData(): Promise<WatchHealthData | null> {
    return new Promise((resolve: (value: WatchHealthData | null) => void) => {
      setTimeout(() => {
        let data = this.getOrUpdateTodayData();
        Logger.info('MockHealthDataSource', JSON.stringify(data));
        resolve(data);
      }, MOCK_SYNC_DELAY);
    });
  }

  private getOrUpdateTodayData(): WatchHealthData {
    let today = dateToStr(new Date());
    if (this.cachedDateStr !== today || this.cachedData === null) {
      this.cachedDateStr = today;
      this.cachedData = this.buildInitialData(today);
      return this.cloneData(this.cachedData);
    }
    this.increaseDailyData(this.cachedData);
    return this.cloneData(this.cachedData);
  }

  private buildInitialData(today: string): WatchHealthData {
    let data = new WatchHealthData();
    data.dateStr = today;
    data.steps = 4000 + this.randomInt(8001); // 4000 - 12000
    data.heartRate = 62 + this.randomInt(31); // 62 - 92
    let sleepStartHour = 21 + this.randomInt(2); // 21:00 - 22:59, sometimes misses a 22:00 target
    let sleepStartMinute = this.randomInt(MINUTES_OF_HOUR);
    let sleepEndHour = 6 + this.randomInt(2); // 06:00 - 07:59
    let sleepEndMinute = this.randomInt(MINUTES_OF_HOUR);
    data.sleepStartTime = this.buildTimeStr(sleepStartHour, sleepStartMinute);
    data.sleepEndTime = this.buildTimeStr(sleepEndHour, sleepEndMinute);
    let startMinutes = sleepStartHour * MINUTES_OF_HOUR + sleepStartMinute;
    let endMinutes = sleepEndHour * MINUTES_OF_HOUR + sleepEndMinute;
    data.sleepDurationMinutes = (MINUTES_OF_DAY - startMinutes) + endMinutes;
    data.waterIntakeLiters = (2 + this.randomInt(6)) * 0.25; // 0.5 - 1.75 L
    return data;
  }

  private increaseDailyData(data: WatchHealthData): void {
    data.steps = Math.min(MAX_MOCK_STEPS, data.steps + 120 + this.randomInt(681)); // +120 - 800
    data.heartRate = 62 + this.randomInt(31); // current heart rate can fluctuate
    if (data.waterIntakeLiters < MAX_MOCK_WATER_LITERS) {
      data.waterIntakeLiters = Math.min(MAX_MOCK_WATER_LITERS, data.waterIntakeLiters + 0.25);
    }
  }

  private cloneData(source: WatchHealthData): WatchHealthData {
    let data = new WatchHealthData();
    data.dateStr = source.dateStr;
    data.steps = source.steps;
    data.heartRate = source.heartRate;
    data.sleepStartTime = source.sleepStartTime;
    data.sleepEndTime = source.sleepEndTime;
    data.sleepDurationMinutes = source.sleepDurationMinutes;
    data.waterIntakeLiters = source.waterIntakeLiters;
    return data;
  }

  private randomInt(bound: number): number {
    return Math.floor(Math.random() * bound);
  }

  private buildTimeStr(hour: number, minute: number): string {
    return `${padTo2Digits(hour)}:${padTo2Digits(minute)}`;
  }
}

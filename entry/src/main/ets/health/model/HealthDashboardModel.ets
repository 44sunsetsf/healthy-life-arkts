export class HealthDashboardData {
  dateKey: string = '';
  hasWatchData: boolean = false;
  syncCount: number = 0;
  dateText: string = '';
  updateText: string = '未同步';
  watchSourceText: string = 'Huawei FIT 4 演示数据';
  steps: number = 0;
  stepGoal: number = 8000;
  heartRate: number = 0;
  sleepHours: number = 0;
  sleepStartText: string = '23:18';
  sleepEndText: string = '07:03';
  activeCalories: number = 0;
  calorieGoal: number = 200;
  exerciseMinutes: number = 0;
  exerciseGoal: number = 30;
  activeHours: number = 0;
  activeHourGoal: number = 12;
  waterMl: number = 900;
  waterGoalMl: number = 2000;
  baseCalories: number = 1072;
  foodCalories: number = 0;
  proteinG: number = 0;
  carbsG: number = 0;
  fatG: number = 0;
  fiberG: number = 0;
  sodiumMg: number = 0;
  weightKg: number = 71.4;
  weightMinKg: number = 71.0;
  weightMaxKg: number = 71.7;
  moodText: string = '平稳';
  analysisText: string = '输入今天吃了什么，点击分析后会给出一条演示建议。';
}

export class HealthCalendarDay {
  dateKey: string = '';
  dateText: string = '';
  weekText: string = '';
  dayText: string = '';
  dayOffset: number = 0;
  isToday: boolean = false;
  isFuture: boolean = false;
}

export class FoodAnalysisResult {
  calories: number = 0;
  proteinG: number = 0;
  carbsG: number = 0;
  fatG: number = 0;
  fiberG: number = 0;
  sodiumMg: number = 0;
  matchedFoodText: string = '';
  advice: string = '';
}

export class HealthCardRecord {
  date: string = '';
  steps: number = 0;
  waterMl: number = 0;
  remainingCalories: number = 0;
}

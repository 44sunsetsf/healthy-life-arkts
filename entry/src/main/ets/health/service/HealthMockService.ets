import { FoodAnalysisResult, HealthDashboardData } from '../model/HealthDashboardModel';

const DEFAULT_SLEEP_HOURS: number = 7.75;
const DEFAULT_WATER_GOAL: number = 2000;
const WATER_LIMIT: number = 4000;
const SYNC_STEP_BASE: number = 2218;
const SYNC_STEP_INC: number = 520;
const BMR_WEIGHT_FACTOR: number = 15.1;
const BMR_WEIGHT_OFFSET: number = 371;

export class HealthMockService {
  createInitialData(): HealthDashboardData {
    let data = new HealthDashboardData();
    data.dateText = this.formatDate(new Date());
    data.waterGoalMl = DEFAULT_WATER_GOAL;
    data.baseCalories = this.calculateBaseCalories(data.weightKg);
    data.analysisText = '输入今天吃了什么，点击分析后会给出一条演示建议。';
    return data;
  }

  syncWatchData(source: HealthDashboardData): HealthDashboardData {
    let next = this.copyData(source);
    next.hasWatchData = true;
    next.syncCount = source.syncCount + 1;
    let baseSteps = source.steps;
    if (baseSteps <= 0) {
      baseSteps = SYNC_STEP_BASE;
    }
    next.steps = baseSteps + SYNC_STEP_INC + next.syncCount * 86;
    next.heartRate = 68 + next.syncCount % 5 * 2;
    next.sleepHours = DEFAULT_SLEEP_HOURS;
    next.sleepStartText = '23:18';
    next.sleepEndText = '07:03';
    next.activeCalories = Math.min(480, 120 + Math.floor(next.steps * 0.035));
    next.exerciseMinutes = Math.min(90, 8 + Math.floor(next.steps / 420));
    next.activeHours = Math.min(next.activeHourGoal, 3 + Math.floor(next.steps / 1200));
    next.updateText = this.formatUpdateTime(new Date());
    next.analysisText = this.buildDailyAdvice(next);
    return next;
  }

  addWater(source: HealthDashboardData, amountMl: number): HealthDashboardData {
    let next = this.copyData(source);
    next.waterMl = Math.min(WATER_LIMIT, source.waterMl + amountMl);
    next.analysisText = this.buildDailyAdvice(next);
    return next;
  }

  setWeightRecord(source: HealthDashboardData, inputText: string): HealthDashboardData {
    let next = this.copyData(source);
    let inputWeight = Number(inputText.trim());
    if (Number.isNaN(inputWeight) || inputWeight < 30 || inputWeight > 250) {
      next.analysisText = '请输入 30-250kg 的有效体重。';
      return next;
    }
    next.weightKg = this.roundOneDecimal(inputWeight);
    next.baseCalories = this.calculateBaseCalories(next.weightKg);
    if (next.weightKg > next.weightMaxKg) {
      next.weightMaxKg = next.weightKg;
    }
    if (next.weightKg < next.weightMinKg) {
      next.weightMinKg = next.weightKg;
    }
    next.analysisText = `已手动记录体重 ${this.formatOneDecimal(next.weightKg)}kg，基础代谢更新为 ${next.baseCalories} 千卡。`;
    return next;
  }

  analyzeFood(source: HealthDashboardData, inputText: string): HealthDashboardData {
    let next = this.copyData(source);
    let result = this.createFoodAnalysis(inputText);
    next.foodCalories += result.calories;
    next.proteinG += result.proteinG;
    next.carbsG += result.carbsG;
    next.fatG += result.fatG;
    next.fiberG += result.fiberG;
    next.sodiumMg += result.sodiumMg;
    next.updateText = this.formatUpdateTime(new Date());
    next.analysisText = result.advice;
    return next;
  }

  getRemainingCalories(data: HealthDashboardData): number {
    let remaining = data.baseCalories + data.activeCalories - data.foodCalories;
    if (remaining < 0) {
      return 0;
    }
    return remaining;
  }

  private createFoodAnalysis(inputText: string): FoodAnalysisResult {
    let result = new FoodAnalysisResult();
    let text = inputText.trim();
    if (text.length <= 0) {
      result.advice = '还没有输入饮食内容，先记录一餐再分析。';
      return result;
    }

    let matched = false;
    if (this.addKnownFood(result, text, '牛肉', 250, 26, 0, 15, 0, 72, 100)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '米饭', 116, 2.6, 25.9, 0.3, 0.3, 2, 150)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '鸡胸肉', 165, 31, 0, 3.6, 0, 74, 100)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '鸡肉', 188, 24, 0, 10, 0, 70, 100)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '鸡蛋', 144, 13.3, 2.8, 8.8, 0, 131, 50)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '青菜', 22, 1.6, 3.6, 0.3, 1.2, 32, 100)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '蔬菜', 25, 1.5, 4.5, 0.3, 1.6, 30, 100)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '面条', 110, 3.6, 24, 0.6, 0.8, 3, 200)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '牛奶', 54, 3.1, 3.4, 3.2, 0, 40, 250)) {
      matched = true;
    }
    if (this.addKnownFood(result, text, '豆腐', 84, 8.1, 3.4, 4.2, 0.4, 7, 100)) {
      matched = true;
    }
    if (!matched) {
      this.addFallbackNutrition(result, text);
    }

    result.advice = this.buildFoodAdvice(result);
    return result;
  }

  private addKnownFood(result: FoodAnalysisResult, text: string, foodName: string, caloriesPer100g: number,
    proteinPer100g: number, carbsPer100g: number, fatPer100g: number, fiberPer100g: number,
    sodiumPer100g: number, defaultAmountG: number): boolean {
    if (text.indexOf(foodName) < 0) {
      return false;
    }
    let amountG = this.extractFoodWeight(text, foodName);
    if (amountG <= 0) {
      amountG = defaultAmountG;
    }
    this.addNutrition(result, amountG, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g, fiberPer100g,
      sodiumPer100g);
    this.appendMatchedFood(result, foodName, amountG);
    return true;
  }

  private addNutrition(result: FoodAnalysisResult, amountG: number, caloriesPer100g: number, proteinPer100g: number,
    carbsPer100g: number, fatPer100g: number, fiberPer100g: number, sodiumPer100g: number): void {
    let factor = amountG / 100;
    result.calories += Math.round(caloriesPer100g * factor);
    result.proteinG += this.roundOneDecimal(proteinPer100g * factor);
    result.carbsG += this.roundOneDecimal(carbsPer100g * factor);
    result.fatG += this.roundOneDecimal(fatPer100g * factor);
    result.fiberG += this.roundOneDecimal(fiberPer100g * factor);
    result.sodiumMg += Math.round(sodiumPer100g * factor);
  }

  private appendMatchedFood(result: FoodAnalysisResult, foodName: string, amountG: number): void {
    if (result.matchedFoodText.length > 0) {
      result.matchedFoodText += '、';
    }
    result.matchedFoodText += `${foodName}${Math.round(amountG)}g`;
  }

  private extractFoodWeight(text: string, foodName: string): number {
    let foodIndex = text.indexOf(foodName);
    if (foodIndex < 0) {
      return 0;
    }
    let amountAfter = this.extractNumberAfter(text, foodIndex + foodName.length);
    if (amountAfter > 0) {
      return amountAfter;
    }
    return this.extractNumberBefore(text, foodIndex - 1);
  }

  private extractNumberAfter(text: string, startIndex: number): number {
    let index = startIndex;
    while (index < text.length) {
      let value = text.charAt(index);
      if (value === ' ' || value === '　' || value === ':' || value === '：') {
        index++;
      } else {
        break;
      }
    }

    let numberText = '';
    while (index < text.length) {
      let value = text.charAt(index);
      if (this.isNumberChar(value)) {
        numberText += value;
        index++;
      } else {
        break;
      }
    }
    return this.parsePositiveNumber(numberText);
  }

  private extractNumberBefore(text: string, startIndex: number): number {
    let index = startIndex;
    while (index >= 0) {
      let value = text.charAt(index);
      if (value === ' ' || value === '　' || value === 'g' || value === 'G' || value === '克') {
        index--;
      } else {
        break;
      }
    }

    let numberText = '';
    while (index >= 0) {
      let value = text.charAt(index);
      if (this.isNumberChar(value)) {
        numberText = value + numberText;
        index--;
      } else {
        break;
      }
    }
    return this.parsePositiveNumber(numberText);
  }

  private isNumberChar(value: string): boolean {
    return value === '0' || value === '1' || value === '2' || value === '3' || value === '4' ||
    value === '5' || value === '6' || value === '7' || value === '8' || value === '9' || value === '.';
  }

  private parsePositiveNumber(value: string): number {
    if (value.length <= 0) {
      return 0;
    }
    let result = Number(value);
    if (Number.isNaN(result) || result <= 0) {
      return 0;
    }
    return result;
  }

  private addFallbackNutrition(result: FoodAnalysisResult, text: string): void {
    result.calories = 160;
    result.proteinG = 5;
    result.carbsG = 18;
    result.fatG = 5;
    result.fiberG = 1;
    result.sodiumMg = 120;

    if (this.hasProteinFood(text)) {
      result.calories += 180;
      result.proteinG += 18;
      result.fatG += 7;
    }
    if (this.hasStapleFood(text)) {
      result.calories += 220;
      result.carbsG += 45;
      result.sodiumMg += 80;
    }
    if (this.hasVegetableFood(text)) {
      result.calories += 60;
      result.fiberG += 5;
      result.carbsG += 10;
    }
    if (this.hasSweetFood(text)) {
      result.calories += 210;
      result.carbsG += 32;
      result.fatG += 8;
    }
  }

  private hasProteinFood(text: string): boolean {
    return text.indexOf('鸡') >= 0 || text.indexOf('蛋') >= 0 || text.indexOf('鱼') >= 0 ||
    text.indexOf('牛') >= 0 || text.indexOf('肉') >= 0 || text.indexOf('奶') >= 0 ||
    text.indexOf('豆') >= 0;
  }

  private hasStapleFood(text: string): boolean {
    return text.indexOf('米') >= 0 || text.indexOf('饭') >= 0 || text.indexOf('面') >= 0 ||
    text.indexOf('包') >= 0 || text.indexOf('粉') >= 0 || text.indexOf('饼') >= 0 ||
    text.indexOf('粥') >= 0;
  }

  private hasVegetableFood(text: string): boolean {
    return text.indexOf('菜') >= 0 || text.indexOf('沙拉') >= 0 || text.indexOf('水果') >= 0 ||
    text.indexOf('苹果') >= 0 || text.indexOf('香蕉') >= 0 || text.indexOf('番茄') >= 0;
  }

  private hasSweetFood(text: string): boolean {
    return text.indexOf('奶茶') >= 0 || text.indexOf('蛋糕') >= 0 || text.indexOf('甜') >= 0 ||
    text.indexOf('饼干') >= 0 || text.indexOf('可乐') >= 0;
  }

  private buildFoodAdvice(result: FoodAnalysisResult): string {
    let prefix = '';
    if (result.matchedFoodText.length > 0) {
      prefix = `已估算 ${result.matchedFoodText}。`;
    }
    if (result.calories >= 650) {
      return `${prefix}这餐热量偏高，下一餐可以减少主食和甜饮，优先补水和蔬菜。`;
    }
    if (result.proteinG < 12) {
      return `${prefix}这餐蛋白质偏少，可以补充鸡蛋、牛奶、鱼肉或豆制品。`;
    }
    if (result.fiberG < 4) {
      return `${prefix}这餐膳食纤维偏少，建议加一份蔬菜或水果。`;
    }
    return `${prefix}这一餐结构比较均衡，继续保持饮水和适量活动。`;
  }

  private buildDailyAdvice(data: HealthDashboardData): string {
    if (!data.hasWatchData) {
      return '点击同步手表数据后，会生成步数、心率、睡眠和运动消耗。';
    }
    if (data.waterMl < 1200) {
      return '今天饮水偏少，可以先补充一杯水，目标是逐步接近 2000ml。';
    }
    if (data.steps < 5000) {
      return '步数还不高，饭后散步 15 分钟可以帮助完成今天的运动目标。';
    }
    return '今天活动量不错，睡眠数据保持稳定，继续按节奏补水即可。';
  }

  private copyData(source: HealthDashboardData): HealthDashboardData {
    let data = new HealthDashboardData();
    data.hasWatchData = source.hasWatchData;
    data.syncCount = source.syncCount;
    data.dateText = source.dateText;
    data.updateText = source.updateText;
    data.watchSourceText = source.watchSourceText;
    data.steps = source.steps;
    data.stepGoal = source.stepGoal;
    data.heartRate = source.heartRate;
    data.sleepHours = source.sleepHours;
    data.sleepStartText = source.sleepStartText;
    data.sleepEndText = source.sleepEndText;
    data.activeCalories = source.activeCalories;
    data.calorieGoal = source.calorieGoal;
    data.exerciseMinutes = source.exerciseMinutes;
    data.exerciseGoal = source.exerciseGoal;
    data.activeHours = source.activeHours;
    data.activeHourGoal = source.activeHourGoal;
    data.waterMl = source.waterMl;
    data.waterGoalMl = source.waterGoalMl;
    data.baseCalories = source.baseCalories;
    data.foodCalories = source.foodCalories;
    data.proteinG = source.proteinG;
    data.carbsG = source.carbsG;
    data.fatG = source.fatG;
    data.fiberG = source.fiberG;
    data.sodiumMg = source.sodiumMg;
    data.weightKg = source.weightKg;
    data.weightMinKg = source.weightMinKg;
    data.weightMaxKg = source.weightMaxKg;
    data.moodText = source.moodText;
    data.analysisText = source.analysisText;
    return data;
  }

  private formatDate(date: Date): string {
    let month = date.getMonth() + 1;
    let day = date.getDate();
    return `${date.getFullYear()}年${this.formatTwoDigits(month)}月${this.formatTwoDigits(day)}日`;
  }

  private calculateBaseCalories(weightKg: number): number {
    return Math.round(weightKg * BMR_WEIGHT_FACTOR + BMR_WEIGHT_OFFSET);
  }

  private formatUpdateTime(date: Date): string {
    let month = date.getMonth() + 1;
    let day = date.getDate();
    return `${this.formatTwoDigits(month)}-${this.formatTwoDigits(day)} ${this.formatTwoDigits(date.getHours())}:${this.formatTwoDigits(date.getMinutes())}`;
  }

  private formatOneDecimal(value: number): string {
    let value10 = Math.round(value * 10);
    let integerPart = Math.floor(value10 / 10);
    let decimalPart = value10 % 10;
    return `${integerPart}.${decimalPart}`;
  }

  private roundOneDecimal(value: number): number {
    return Math.round(value * 10) / 10;
  }

  private formatTwoDigits(value: number): string {
    if (value < 10) {
      return `0${value}`;
    }
    return value.toString();
  }
}

import http from '@ohos.net.http';
import { ChatMessage, MessageRole, ApiResponse, ApiRequestMessage, ApiRequestBody } from '../model/ChatMessage';
import Logger from '../../common/utils/Logger';

const TAG = 'AiService';

const DEFAULT_API_URL = 'https://api.deepseek.com/v1/chat/completions';
const DEFAULT_MODEL = 'deepseek-chat';

class HttpHeader {
  contentType: string = '';
  authorization: string = '';
}

class HttpRequestConfig {
  method: http.RequestMethod = http.RequestMethod.POST;
  header: HttpHeader = new HttpHeader();
  extraData: string = '';
  expectDataType: http.HttpDataType = http.HttpDataType.STRING;
  connectTimeout: number = 30000;
  readTimeout: number = 60000;
}

export class AiService {
  private apiUrl: string = DEFAULT_API_URL;
  private apiKey: string = 'sk-791c6c401d0f478c8647e23ccd0f2a40';
  private model: string = DEFAULT_MODEL;

  configure(apiUrl: string, apiKey: string, model?: string): void {
    Logger.info(TAG, 'configure: apiUrl=' + apiUrl + ', model=' + (model ? model : this.model));
    this.apiUrl = apiUrl;
    this.apiKey = apiKey;
    if (model) {
      this.model = model;
    }
  }

  buildSystemPrompt(healthContext: string): string {
    return '你是一个健康生活助手，帮助用户管理日常健康习惯。你可以根据用户的健康数据给出建议和鼓励。\n当前用户的健康数据摘要：\n' + healthContext + '\n\n请用简洁友好的中文回答用户问题，字数控制在200字以内。';
  }

  buildMessages(userMessage: string, history: ChatMessage[], healthContext: string): ApiRequestMessage[] {
    const messages: ApiRequestMessage[] = [];
    const sysMsg: ApiRequestMessage = { role: MessageRole.SYSTEM, content: this.buildSystemPrompt(healthContext) };
    messages.push(sysMsg);

    for (const msg of history) {
      const historyMsg: ApiRequestMessage = { role: msg.role, content: msg.content };
      messages.push(historyMsg);
    }

    const userMsg: ApiRequestMessage = { role: MessageRole.USER, content: userMessage };
    messages.push(userMsg);

    Logger.debug(TAG, 'buildMessages: total=' + messages.length + ', history=' + history.length);
    return messages;
  }

  async sendMessage(userMessage: string, history: ChatMessage[], healthContext: string): Promise<string> {
    Logger.info(TAG, 'sendMessage start: model=' + this.model + ', historyLen=' + history.length + ', msgLen=' + userMessage.length);

    const messages: ApiRequestMessage[] = this.buildMessages(userMessage, history, healthContext);

    const requestData: ApiRequestBody = {
      model: this.model,
      messages: messages,
      temperature: 0.7,
      max_tokens: 500
    };

    const requestBody: string = JSON.stringify(requestData);

    const httpRequest = http.createHttp();

    try {
      const startTime = Date.now();
      const config = new HttpRequestConfig();
      config.method = http.RequestMethod.POST;
      config.header = new HttpHeader();
      config.header.contentType = 'application/json';
      config.header.authorization = 'Bearer ' + this.apiKey;
      config.extraData = requestBody;
      config.connectTimeout = 30000;
      config.readTimeout = 60000;
      const response = await httpRequest.request(this.apiUrl, config);

      const elapsed = Date.now() - startTime;
      httpRequest.destroy();

      Logger.info(TAG, 'sendMessage response: code=' + response.responseCode + ', elapsed=' + elapsed + 'ms');

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ApiResponse;
        if (result.choices && result.choices.length > 0) {
          let replyContent = result.choices[0].message.content;
          replyContent = replyContent.replace(/\*\*(.+?)\*\*/g, '$1');
          replyContent = replyContent.replace(/\*(.+?)\*/g, '$1');
          Logger.info(TAG, 'sendMessage success: replyLen=' + replyContent.length);
          return replyContent;
        }
        Logger.warn(TAG, 'sendMessage: 200 but no choices in response');
      }

      Logger.error(TAG, 'sendMessage failed: responseCode=' + response.responseCode);
      return '[错误] API 返回状态码: ' + response.responseCode;
    } catch (err) {
      httpRequest.destroy();
      Logger.error(TAG, 'sendMessage exception: ' + JSON.stringify(err));
      return '[错误] 网络请求失败: ' + JSON.stringify(err);
    }
  }
}

export const aiService = new AiService();

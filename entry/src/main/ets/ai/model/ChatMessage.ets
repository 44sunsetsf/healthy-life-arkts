export enum MessageRole {
  USER = 'user',
  ASSISTANT = 'assistant',
  SYSTEM = 'system'
}

export class ChatMessage {
  role: MessageRole;
  content: string;
  timestamp: number;

  constructor(role: MessageRole, content: string) {
    this.role = role;
    this.content = content;
    this.timestamp = Date.now();
  }
}

export interface ApiMessage {
  role: string;
  content: string;
}

export interface ApiChoice {
  message: ApiMessage;
}

export interface ApiResponse {
  choices: ApiChoice[];
}

export interface ApiRequestMessage {
  role: string;
  content: string;
}

export interface ApiRequestBody {
  model: string;
  messages: ApiRequestMessage[];
  temperature: number;
  max_tokens: number;
}

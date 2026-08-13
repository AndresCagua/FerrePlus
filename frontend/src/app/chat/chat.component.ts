import { ChangeDetectionStrategy, Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { finalize } from 'rxjs/operators';
import { ChatService } from '../services/chat.service';
import { ChatSource } from '../core/models';

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  sources?: ChatSource[];
}

@Component({
  selector: 'app-chat',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './chat.component.html',
  styleUrls: ['./chat.component.scss']
})
export class ChatComponent {
  readonly messageForm = this.formBuilder.group({
    question: ['', [Validators.required, Validators.maxLength(1000)]]
  });

  messages: ChatMessage[] = [];
  loading = false;
  errorMessage = '';

  constructor(
    private formBuilder: FormBuilder,
    private chatService: ChatService
  ) {}

  sendMessage(): void {
    const questionControl = this.messageForm.controls.question;
    const question = questionControl.value?.trim() ?? '';

    if (!question || this.loading) {
      questionControl.markAsTouched();
      return;
    }

    this.messages.push({ role: 'user', content: question });
    this.messageForm.reset();
    this.errorMessage = '';
    this.loading = true;

    this.chatService.sendMessage(question)
      .pipe(finalize(() => this.loading = false))
      .subscribe({
        next: response => this.messages.push({
          role: 'assistant',
          content: response.answer,
          sources: response.sources
        }),
        error: error => this.errorMessage = this.getErrorMessage(error)
      });
  }

  getSourceTitle(source: ChatSource): string {
    const title = source.metadata?.['title'];
    return typeof title === 'string' && title.trim() ? title : `${source.entityType} #${source.entityId}`;
  }

  private getErrorMessage(error: HttpErrorResponse): string {
    if (error.status === 429) {
      return 'Se alcanzo el limite de consultas. Intenta nuevamente mas tarde.';
    }

    if (error.status === 503) {
      return 'El servicio de respuestas no esta disponible en este momento. Intenta nuevamente.';
    }

    return 'No fue posible obtener una respuesta. Verifica tu conexion e intenta nuevamente.';
  }
}

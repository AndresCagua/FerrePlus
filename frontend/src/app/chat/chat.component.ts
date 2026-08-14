import { AfterViewChecked, ChangeDetectionStrategy, Component, ElementRef, ViewChild, signal } from '@angular/core';
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
export class ChatComponent implements AfterViewChecked {
  readonly messageForm = this.formBuilder.group({
    question: ['', [Validators.required, Validators.maxLength(1000)]]
  });

  messages = signal<ChatMessage[]>([]);
  loading = signal(false);
  errorMessage = signal('');
  isOpen = signal(false);

  @ViewChild('messageList') private messageList?: ElementRef<HTMLDivElement>;
  private shouldScrollToBottom = false;

  constructor(
    private formBuilder: FormBuilder,
    private chatService: ChatService
  ) {}

  togglePanel(): void {
    this.isOpen.update(open => !open);
    if (this.isOpen()) {
      this.shouldScrollToBottom = true;
    }
  }

  closePanel(): void {
    this.isOpen.set(false);
  }

  ngAfterViewChecked(): void {
    if (!this.shouldScrollToBottom || !this.messageList) {
      return;
    }

    const element = this.messageList.nativeElement;
    element.scrollTop = element.scrollHeight;
    this.shouldScrollToBottom = false;
  }

  sendMessage(): void {
    const questionControl = this.messageForm.controls.question;
    const question = questionControl.value?.trim() ?? '';

    if (!question || this.loading()) {
      questionControl.markAsTouched();
      return;
    }

    this.messages.update(messages => [...messages, { role: 'user', content: question }]);
    this.shouldScrollToBottom = true;
    this.messageForm.reset();
    this.errorMessage.set('');
    this.loading.set(true);

    this.chatService.sendMessage(question)
      .pipe(finalize(() => {
        this.loading.set(false);
      }))
      .subscribe({
        next: response => {
          this.messages.update(messages => [
            ...messages,
            {
              role: 'assistant',
              content: response.answer,
              sources: response.sources
            }
          ]);
          this.shouldScrollToBottom = true;
        },
        error: error => {
          this.errorMessage.set(this.getErrorMessage(error));
        }
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

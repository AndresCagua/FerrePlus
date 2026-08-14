import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { ReactiveFormsModule } from '@angular/forms';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { of } from 'rxjs';
import { throwError } from 'rxjs';
import { ChatComponent } from './chat.component';
import { ChatModule } from './chat.module';
import { ChatService } from '../services/chat.service';

describe('ChatComponent', () => {
  let fixture: ComponentFixture<ChatComponent>;
  let component: ChatComponent;
  let sendMessageMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    sendMessageMock = vi.fn().mockReturnValue(of({
      answer: 'Puedes ir a /productos. [GUIA:7]',
      sources: [{ entityType: 'GUIA', entityId: 7, metadata: { title: 'Registrar producto' } }]
    }));

    TestBed.configureTestingModule({
      imports: [
        NoopAnimationsModule,
        ReactiveFormsModule,
        ChatModule
      ],
      providers: [{ provide: ChatService, useValue: { sendMessage: sendMessageMock } }]
    });
    fixture = TestBed.createComponent(ChatComponent);
    component = fixture.componentInstance;
  });

  it('envia la pregunta y renderiza respuesta y fuentes', () => {
    component.isOpen.set(true);
    component.messageForm.controls.question.setValue('¿Donde registro un producto?');
    component.sendMessage();
    fixture.detectChanges();

    expect(sendMessageMock).toHaveBeenCalledWith('¿Donde registro un producto?');
    expect(component.messages()).toHaveLength(2);
    expect(component.messages()[1].content).toContain('/productos');
    expect(component.messages()[1].sources).toHaveLength(1);
    expect(fixture.nativeElement.textContent).toContain('Registrar producto');
  });

  it('abre y cierra el panel desde el FAB', () => {
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('.chat-panel')).toBeNull();
    fixture.nativeElement.querySelector('.chat-fab').click();
    fixture.detectChanges();
    expect(component.isOpen()).toBe(true);
    expect(fixture.nativeElement.querySelector('.chat-panel')).not.toBeNull();

    fixture.nativeElement.querySelector('[aria-label="Cerrar asistente"]').click();
    fixture.detectChanges();
    expect(component.isOpen()).toBe(false);
  });

  it('muestra un error visible cuando el servicio falla', () => {
    sendMessageMock.mockReturnValueOnce(throwError(() => ({ status: 503 })));
    component.isOpen.set(true);
    component.messageForm.controls.question.setValue('¿Hay productos con stock bajo?');

    component.sendMessage();
    fixture.detectChanges();

    expect(component.errorMessage()).toContain('no esta disponible');
    expect(fixture.nativeElement.querySelector('[role="alert"]').textContent)
      .toContain('no esta disponible');
  });

  it('no envia una pregunta vacia', () => {
    component.messageForm.controls.question.setValue('   ');

    component.sendMessage();

    expect(sendMessageMock).not.toHaveBeenCalled();
    expect(component.messages()).toHaveLength(0);
  });

  it('renderiza listas y escapa contenido HTML no confiable', () => {
    const rendered = component.renderContent('- Producto <script>alert(1)</script>\n- Select');

    expect(rendered).toBe('<ul><li>Producto &lt;script&gt;alert(1)&lt;/script&gt;</li><li>Select</li></ul>');
  });
});

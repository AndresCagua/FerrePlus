import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { ChatService } from './chat.service';
import { ChatResponse } from '../core/models';
import { environment } from '../../environments/environment';

describe('ChatService', () => {
  let service: ChatService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [ChatService]
    });
    service = TestBed.inject(ChatService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('sendMessage envia POST /api/chat con la pregunta y devuelve la respuesta', () => {
    const response: ChatResponse = {
      answer: 'Hay stock disponible. [PRODUCTO:3]',
      sources: [{ entityType: 'PRODUCTO', entityId: 3, metadata: { title: 'Cable' } }]
    };
    let received: ChatResponse | undefined;

    service.sendMessage('¿Que productos hay?').subscribe(result => received = result);

    const request = httpMock.expectOne(`${environment.apiUrl}/chat`);
    expect(request.request.method).toBe('POST');
    expect(request.request.body).toEqual({ question: '¿Que productos hay?' });
    request.flush(response);

    expect(received).toEqual(response);
  });
});

package com.ferreplus.publico.service;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

import com.ferreplus.publico.dto.publico.ContactoRequestDTO;
import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.repository.ContactoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import java.util.Optional;

@ExtendWith(MockitoExtension.class)
class ContactoServiceTest {
    @Mock ContactoRepository repository;
    @Mock ApplicationEventPublisher events;
    @InjectMocks ContactoService service;

    @Test
    void honeypotDoesNotPersistContact() {
        var request = new ContactoRequestDTO("Bot", "bot@example.com", null, "Spam", "x", "filled");
        when(repository.findByIdempotencyKey("contact-key-1")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.create(request, "contact-key-1", "127.0.0.1", null))
                .isInstanceOf(PublicApiException.class);
        verify(repository, never()).save(any());
        verifyNoInteractions(events);
    }
}

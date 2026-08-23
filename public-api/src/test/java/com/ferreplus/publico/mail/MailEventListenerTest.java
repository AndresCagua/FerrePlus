package com.ferreplus.publico.mail;

import static org.mockito.Mockito.*;

import com.ferreplus.publico.event.PostulacionReceivedEvent;
import com.ferreplus.publico.model.Notificacion;
import com.ferreplus.publico.model.TipoDestinatario;
import com.ferreplus.publico.repository.ContactoRepository;
import com.ferreplus.publico.repository.PostulacionRepository;
import com.ferreplus.publico.service.NotificacionService;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import java.util.List;
import java.util.Optional;
import java.util.Properties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;
import org.thymeleaf.spring6.SpringTemplateEngine;

class MailEventListenerTest {
    private final NotificacionService notifications = mock(NotificacionService.class);
    private final JavaMailSender sender = mock(JavaMailSender.class);
    private final SpringTemplateEngine templateEngine = mock(SpringTemplateEngine.class);
    private final ContactoRepository contactos = mock(ContactoRepository.class);
    private final PostulacionRepository postulaciones = mock(PostulacionRepository.class);
    private MailEventListener listener;

    @BeforeEach
    void setUp() {
        listener = new MailEventListener(notifications, sender, templateEngine, contactos, postulaciones);
        ReflectionTestUtils.setField(listener, "from", "no-reply@test.invalid");
        when(templateEngine.process(anyString(), any())).thenReturn("<p>ok</p>");
        when(postulaciones.findById("post-1")).thenReturn(Optional.empty());
    }

    @Test
    void separaDestinatariosInternosYConfirmacionDelCandidato() {
        Notificacion internal = notification(TipoDestinatario.JOB_APPLICATION, List.of("talento@ferreplus.test"));
        Notificacion candidate = notification(TipoDestinatario.CANDIDATE_CONFIRMATION, List.of("candidate@test.invalid"));
        when(notifications.pending(TipoDestinatario.JOB_APPLICATION, "post-1", "corr-1")).thenReturn(internal);
        when(notifications.pendingToRecipient(TipoDestinatario.CANDIDATE_CONFIRMATION, "post-1", "candidate@test.invalid", "corr-1"))
                .thenReturn(candidate);
        when(sender.createMimeMessage()).thenAnswer(invocation -> new MimeMessage(Session.getInstance(new Properties())));

        listener.onPostulacion(new PostulacionReceivedEvent("post-1", "candidate@test.invalid", "corr-1"));

        verify(notifications).pendingToRecipient(TipoDestinatario.CANDIDATE_CONFIRMATION, "post-1", "candidate@test.invalid", "corr-1");
        verify(sender, times(2)).send(any(MimeMessage.class));
    }

    @Test
    void reintentaConfirmacionSinUsarDestinatariosAdministrativos() {
        Notificacion candidate = notification(TipoDestinatario.CANDIDATE_CONFIRMATION, List.of("candidate@test.invalid"));
        when(notifications.find("notification-1")).thenReturn(candidate);
        when(sender.createMimeMessage()).thenAnswer(invocation -> new MimeMessage(Session.getInstance(new Properties())));

        listener.retry("notification-1");

        verify(sender).send(any(MimeMessage.class));
        verify(postulaciones, never()).findById(anyString());
    }

    private Notificacion notification(TipoDestinatario type, List<String> recipients) {
        Notificacion notification = new Notificacion();
        notification.setId("notification-1");
        notification.setTipo(type);
        notification.setReferenciaId("post-1");
        notification.setDestinatarios(recipients);
        return notification;
    }
}

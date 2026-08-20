package com.ferreplus.publico.mail;

import com.ferreplus.publico.event.ContactoReceivedEvent;
import com.ferreplus.publico.event.PostulacionReceivedEvent;
import com.ferreplus.publico.model.EstadoNotificacion;
import com.ferreplus.publico.model.Notificacion;
import com.ferreplus.publico.model.TipoDestinatario;
import com.ferreplus.publico.repository.ContactoRepository;
import com.ferreplus.publico.repository.PostulacionRepository;
import com.ferreplus.publico.service.NotificacionService;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class MailEventListener {
    private final NotificacionService notifications;
    private final JavaMailSender sender;
    private final SpringTemplateEngine templateEngine;
    private final ContactoRepository contactos;
    private final PostulacionRepository postulaciones;
    @org.springframework.beans.factory.annotation.Value("${app.mail.from:${SMTP_FROM:no-reply@ferreplus.local}}") private String from;

    @EventListener
    @Async("mailTaskExecutor")
    public void onContacto(ContactoReceivedEvent event) {
        Notificacion notification = notifications.pending(TipoDestinatario.CONTACT_FORM, event.contactoId(), event.correlationId());
        var contact = contactos.findById(event.contactoId()).orElse(null);
        send(notification, "Nuevo contacto: " + (contact == null ? "FerrePlus" : contact.getAsunto()),
                "mail/contacto-recibido", contact == null ? java.util.Map.of() : java.util.Map.of(
                        "nombre", contact.getNombre(), "email", contact.getEmail(), "mensaje", contact.getMensaje()));
    }

    @EventListener
    @Async("mailTaskExecutor")
    public void onPostulacion(PostulacionReceivedEvent event) {
        Notificacion notification = notifications.pending(TipoDestinatario.JOB_APPLICATION, event.postulacionId(), event.correlationId());
        var application = postulaciones.findById(event.postulacionId()).orElse(null);
        send(notification, "Nueva postulacion", "mail/postulacion-recibida", application == null ? java.util.Map.of() : java.util.Map.of(
                "nombres", application.getNombres(), "apellidos", application.getApellidos(), "email", application.getEmail()));
    }

    public void retry(String id) {
        Notificacion notification = notifications.find(id); notification.setEstado(EstadoNotificacion.PENDING);
        notification.setNextAttemptAt(null); notifications.save(notification);
        send(notification, "Reenvio de notificacion", notification.getTipo() == TipoDestinatario.CONTACT_FORM
                ? "mail/contacto-recibido" : "mail/postulacion-recibida", java.util.Map.of());
    }

    private void send(Notificacion notification, String subject, String template, java.util.Map<String, Object> variables) {
        if (notification.getDestinatarios() == null || notification.getDestinatarios().isEmpty()) {
            notification.setEstado(EstadoNotificacion.SENT); notifications.save(notification); return;
        }
        try {
            Context context = new Context(); variables.forEach(context::setVariable);
            String html = templateEngine.process(template, context);
            var message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            helper.setFrom(from); helper.setTo(notification.getDestinatarios().toArray(String[]::new));
            helper.setSubject(subject); helper.setText(html, true);
            sender.send(message); notification.setEstado(EstadoNotificacion.SENT); notification.setUltimoError(null); notification.setNextAttemptAt(null);
        } catch (Exception exception) {
            int attempts = notification.getIntentos() + 1; notification.setIntentos(attempts);
            notification.setEstado(EstadoNotificacion.FAILED); notification.setUltimoError(sanitize(exception));
            long minutes = attempts <= 1 ? 1 : attempts == 2 ? 5 : 30;
            notification.setNextAttemptAt(Instant.now().plus(minutes, ChronoUnit.MINUTES));
        }
        notifications.save(notification);
    }
    private String sanitize(Exception exception) { return exception.getClass().getSimpleName() + ": " +
            String.valueOf(exception.getMessage()).replaceAll("[\\r\\n]", " ").substring(0, Math.min(500, String.valueOf(exception.getMessage()).length())); }
}

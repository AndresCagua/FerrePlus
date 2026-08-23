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
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import com.ferreplus.publico.config.SafeDiagnosticLog;

@Component
@RequiredArgsConstructor
public class MailEventListener {
    private static final Logger LOG = LoggerFactory.getLogger(MailEventListener.class);
    private final NotificacionService notifications;
    private final JavaMailSender sender;
    private final SpringTemplateEngine templateEngine;
    private final ContactoRepository contactos;
    private final PostulacionRepository postulaciones;
    @org.springframework.beans.factory.annotation.Value("${app.mail.from:${SMTP_FROM:no-reply@ferreplus.local}}") private String from;

    @EventListener
    @Async("mailTaskExecutor")
    public void onContacto(ContactoReceivedEvent event) {
        try (var ignored = MDC.putCloseable("correlationId", event.correlationId())) {
            LOG.info("mail.listener.pickup flow=contact type={} referenceId={} correlationId={}",
                    TipoDestinatario.CONTACT_FORM, event.contactoId(), event.correlationId());
            Notificacion notification = notifications.pending(TipoDestinatario.CONTACT_FORM, event.contactoId(), event.correlationId());
            var contact = contactos.findById(event.contactoId()).orElse(null);
            send(notification, "Nuevo contacto: " + (contact == null ? "FerrePlus" : contact.getAsunto()),
                    "mail/contacto-recibido", contact == null ? java.util.Map.of() : java.util.Map.of(
                            "nombre", contact.getNombre(), "email", contact.getEmail(), "mensaje", contact.getMensaje()));
        }
    }

    @EventListener
    @Async("mailTaskExecutor")
    public void onPostulacion(PostulacionReceivedEvent event) {
        try (var ignored = MDC.putCloseable("correlationId", event.correlationId())) {
            LOG.info("mail.listener.pickup flow=job_application type={} referenceId={} correlationId={}",
                    TipoDestinatario.JOB_APPLICATION, event.postulacionId(), event.correlationId());
            Notificacion notification = notifications.pending(TipoDestinatario.JOB_APPLICATION, event.postulacionId(), event.correlationId());
            Notificacion confirmation = notifications.pendingToRecipient(TipoDestinatario.CANDIDATE_CONFIRMATION,
                    event.postulacionId(), event.email(), event.correlationId());
            var application = postulaciones.findById(event.postulacionId()).orElse(null);
            send(notification, "Nueva postulacion", "mail/postulacion-recibida", application == null ? java.util.Map.of() : java.util.Map.of(
                    "nombres", application.getNombres(), "apellidos", application.getApellidos(), "email", application.getEmail()));
            send(confirmation, "Confirmacion de postulacion", "mail/confirmacion-postulacion", java.util.Map.of());
        }
    }

    public void retry(String id) {
        Notificacion notification = notifications.find(id);
        if (notification.getEstado() == EstadoNotificacion.SENT) {
            LOG.info("mail.retry.skipped notificationId={} type={} status=SENT correlationId={}",
                    notification.getId(), notification.getTipo(), notification.getCorrelationId());
            return;
        }
        LOG.info("mail.retry.scheduled notificationId={} type={} previousStatus={} attemptCount={} correlationId={}",
                notification.getId(), notification.getTipo(), notification.getEstado(), notification.getIntentos(), notification.getCorrelationId());
        notification.setEstado(EstadoNotificacion.PENDING);
        notification.setNextAttemptAt(null); notifications.save(notification);
        send(notification, "Reenvio de notificacion", templateFor(notification.getTipo()), java.util.Map.of());
    }

    @Scheduled(fixedDelayString = "${app.mail.retry-interval-ms:60000}")
    public void retryDueNotifications() {
        var due = notifications.dueForRetry(Instant.now());
        LOG.debug("mail.retry.scan dueCount={}", due.size());
        due.stream()
                .filter(notification -> notification.getIntentos() < 3)
                .forEach(this::retryExisting);
    }

    private void retryExisting(Notificacion notification) {
        LOG.info("mail.retry.scheduled notificationId={} type={} previousStatus={} attemptCount={} correlationId={}",
                notification.getId(), notification.getTipo(), notification.getEstado(), notification.getIntentos(), notification.getCorrelationId());
        notification.setEstado(EstadoNotificacion.PENDING);
        notifications.save(notification);
        if (notification.getTipo() == TipoDestinatario.CONTACT_FORM) {
            var contact = contactos.findById(notification.getReferenciaId()).orElse(null);
            send(notification, "Nuevo contacto", "mail/contacto-recibido", contact == null ? java.util.Map.of() : java.util.Map.of(
                    "nombre", contact.getNombre(), "email", contact.getEmail(), "mensaje", contact.getMensaje()));
            return;
        }
        if (notification.getTipo() == TipoDestinatario.CANDIDATE_CONFIRMATION) {
            send(notification, "Confirmacion de postulacion", "mail/confirmacion-postulacion", java.util.Map.of());
            return;
        }
        var application = postulaciones.findById(notification.getReferenciaId()).orElse(null);
        send(notification, "Nueva postulacion", "mail/postulacion-recibida", application == null ? java.util.Map.of() : java.util.Map.of(
                "nombres", application.getNombres(), "apellidos", application.getApellidos(), "email", application.getEmail()));
    }

    private String templateFor(TipoDestinatario type) {
        return type == TipoDestinatario.CONTACT_FORM ? "mail/contacto-recibido"
                : type == TipoDestinatario.CANDIDATE_CONFIRMATION ? "mail/confirmacion-postulacion"
                : "mail/postulacion-recibida";
    }

    private void send(Notificacion notification, String subject, String template, java.util.Map<String, Object> variables) {
        String correlationId = SafeDiagnosticLog.correlationId(notification.getCorrelationId());
        LOG.info("mail.send.start notificationId={} type={} status={} attemptCount={} recipientCount={} correlationId={}",
                notification.getId(), notification.getTipo(), notification.getEstado(), notification.getIntentos(),
                notification.getDestinatarios() == null ? 0 : notification.getDestinatarios().size(), correlationId);
        if (notification.getDestinatarios() == null || notification.getDestinatarios().isEmpty()) {
            notification.setEstado(EstadoNotificacion.SENT); notifications.save(notification);
            LOG.info("mail.send.end notificationId={} type={} status=SENT attemptCount={} recipientCount=0 correlationId={}",
                    notification.getId(), notification.getTipo(), notification.getIntentos(), correlationId);
            return;
        }
        try {
            Context context = new Context(); variables.forEach(context::setVariable);
            String html = templateEngine.process(template, context);
            var message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            helper.setFrom(from); helper.setTo(notification.getDestinatarios().toArray(String[]::new));
            helper.setSubject(subject); helper.setText(html, true);
            sender.send(message); notification.setEstado(EstadoNotificacion.SENT); notification.setUltimoError(null); notification.setNextAttemptAt(null);
            LOG.info("mail.send.end notificationId={} type={} status=SENT attemptCount={} recipientCount={} correlationId={}",
                    notification.getId(), notification.getTipo(), notification.getIntentos(), notification.getDestinatarios().size(), correlationId);
        } catch (Exception exception) {
            int attempts = notification.getIntentos() + 1; notification.setIntentos(attempts);
            notification.setEstado(EstadoNotificacion.FAILED); notification.setUltimoError(sanitize(exception));
            long minutes = attempts <= 1 ? 1 : attempts == 2 ? 5 : 30;
            notification.setNextAttemptAt(Instant.now().plus(minutes, ChronoUnit.MINUTES));
            LOG.warn("mail.send.failed notificationId={} type={} status=FAILED attemptCount={} recipientCount={} retryInMinutes={} failure={} correlationId={}",
                    notification.getId(), notification.getTipo(), attempts, notification.getDestinatarios().size(), minutes,
                    SafeDiagnosticLog.failure(exception), correlationId);
        }
        notifications.save(notification);
    }
    private String sanitize(Exception exception) { return SafeDiagnosticLog.failure(exception); }
}

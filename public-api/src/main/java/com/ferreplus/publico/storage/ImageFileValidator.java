package com.ferreplus.publico.storage;

import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

/** Validates the media formats consumed by the public portal before MinIO storage. */
@Component
public class ImageFileValidator {
    private static final long MAX_SIZE = 5L * 1024 * 1024;

    public ValidImage validate(MultipartFile file) {
        if (file == null || file.isEmpty()) throw new ImageValidationException("La imagen es obligatoria");
        if (file.getSize() > MAX_SIZE) throw new ImageValidationException("La imagen supera el limite de 5 MB");
        String extension = extension(file.getOriginalFilename());
        if (!extension.matches("jpg|jpeg|png|webp"))
            throw new ImageValidationException("Extension de imagen no permitida");
        String mime = file.getContentType() == null ? "" : file.getContentType().toLowerCase(Locale.ROOT);
        if (!matchesMagic(file, extension) || !allowedMime(mime, extension))
            throw new ImageValidationException("El MIME real de la imagen no coincide con su extension");
        return new ValidImage(extension.equals("jpeg") ? "jpg" : extension,
                mime, file.getSize(), file.getOriginalFilename());
    }

    private boolean allowedMime(String mime, String extension) {
        return (extension.equals("jpg") || extension.equals("jpeg")) && mime.equals("image/jpeg")
                || extension.equals("png") && mime.equals("image/png")
                || extension.equals("webp") && mime.equals("image/webp");
    }

    private boolean matchesMagic(MultipartFile file, String extension) {
        try (InputStream input = file.getInputStream()) {
            byte[] header = input.readNBytes(16);
            if (extension.equals("jpg") || extension.equals("jpeg"))
                return header.length >= 3 && (header[0] & 0xff) == 0xff && (header[1] & 0xff) == 0xd8 && (header[2] & 0xff) == 0xff;
            if (extension.equals("png"))
                return header.length >= 8 && header[0] == (byte) 0x89 && header[1] == 0x50 && header[2] == 0x4e && header[3] == 0x47;
            return header.length >= 12 && header[0] == 'R' && header[1] == 'I' && header[2] == 'F' && header[3] == 'F'
                    && header[8] == 'W' && header[9] == 'E' && header[10] == 'B' && header[11] == 'P';
        } catch (IOException exception) { throw new ImageValidationException("No fue posible leer la imagen"); }
    }
    private String extension(String name) {
        if (name == null || !name.contains(".")) return "";
        return name.substring(name.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
    }
    public record ValidImage(String extension, String mimeType, long size, String fileName) {}
}

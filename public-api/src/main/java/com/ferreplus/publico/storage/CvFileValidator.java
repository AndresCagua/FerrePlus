package com.ferreplus.publico.storage;

import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.util.Set;
import java.util.zip.ZipInputStream;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class CvFileValidator {
    public static final long MAX_SIZE = 5L * 1024 * 1024;
    private static final Set<String> EXTENSIONS = Set.of("pdf", "doc", "docx");

    public ValidatedCv validate(MultipartFile file) {
        if (file == null || file.isEmpty()) throw new CvValidationException(CvErrorCode.CV_SIZE_EXCEEDED,
                "El CV es obligatorio y no puede estar vacio");
        String name = file.getOriginalFilename() == null ? "" : file.getOriginalFilename();
        String extension = extension(name);
        if (!EXTENSIONS.contains(extension)) throw new CvValidationException(CvErrorCode.CV_EXTENSION_NOT_ALLOWED,
                "Extension de CV no permitida: ." + (extension.isBlank() ? "desconocida" : extension)
                        + ". Use .pdf, .doc o .docx");
        if (file.getSize() > MAX_SIZE) throw new CvValidationException(CvErrorCode.CV_SIZE_EXCEEDED,
                "El CV supera el limite permitido de 5 MB");
        try (InputStream input = file.getInputStream()) {
            byte[] header = input.readNBytes(8);
            boolean valid = switch (extension) {
                case "pdf" -> startsWith(header, new byte[] {'%', 'P', 'D', 'F', '-'});
                case "doc" -> startsWith(header, new byte[] {(byte) 0xD0, (byte) 0xCF, 0x11, (byte) 0xE0});
                case "docx" -> isDocx(file);
                default -> false;
            };
            if (!valid) throw new CvValidationException(CvErrorCode.CV_MIME_INVALID,
                    "El contenido real del CV no coincide con su extension");
        } catch (IOException exception) {
            throw new CvValidationException(CvErrorCode.CV_MIME_INVALID, "No se pudo inspeccionar el CV");
        }
        String mime = switch (extension) {
            case "pdf" -> "application/pdf";
            case "doc" -> "application/msword";
            default -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
        };
        String claimed = file.getContentType();
        if (claimed != null && !claimed.isBlank() && !claimed.equals("application/octet-stream") && !claimed.equals(mime))
            throw new CvValidationException(CvErrorCode.CV_MIME_INVALID,
                    "El MIME declarado no coincide con el tipo real del CV");
        return new ValidatedCv(extension, mime, file.getSize(), name);
    }

    private String extension(String name) {
        int dot = name.lastIndexOf('.');
        return dot < 0 ? "" : name.substring(dot + 1).toLowerCase(Locale.ROOT);
    }
    private boolean startsWith(byte[] actual, byte[] expected) {
        if (actual.length < expected.length) return false;
        for (int i = 0; i < expected.length; i++) if (actual[i] != expected[i]) return false;
        return true;
    }
    private boolean isDocx(MultipartFile file) {
        try (ZipInputStream zip = new ZipInputStream(file.getInputStream())) {
            boolean hasDocument = false;
            for (var entry = zip.getNextEntry(); entry != null; entry = zip.getNextEntry()) {
                if (entry.getName().equals("word/document.xml")) hasDocument = true;
            }
            return hasDocument;
        } catch (IOException exception) { return false; }
    }
    public record ValidatedCv(String extension, String mimeType, long size, String fileName) {}
}

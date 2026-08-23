package com.ferreplus.publico.storage;

import com.ferreplus.publico.exception.PublicApiException;
import org.springframework.http.HttpStatus;

public class ImageValidationException extends PublicApiException {
    public ImageValidationException(String message) { super(HttpStatus.BAD_REQUEST, message); }
}

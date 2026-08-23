package com.ferreplus.publico.storage;

import org.springframework.http.HttpStatus;
import com.ferreplus.publico.exception.PublicApiException;

public class CvValidationException extends PublicApiException {
    private final CvErrorCode code;
    public CvValidationException(CvErrorCode code, String message) {
        super(HttpStatus.BAD_REQUEST, message);
        this.code = code;
    }
    public CvErrorCode code() { return code; }
}

package com.ferreplus.service.chat;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class QueryParameterExtractor {
    private static final Pattern DATE = Pattern.compile("\\b\\d{4}-\\d{2}-\\d{2}\\b");
    private static final Pattern LIMIT = Pattern.compile("(?i)\\b(?:los|las|top)\\s+(\\d+)\\b");
    private static final int DEFAULT_LIMIT = 10;

    private QueryParameterExtractor() {
    }

    public static Optional<ValidatedChatParameters> extract(String question) {
        if (question == null || question.isBlank()) {
            return Optional.empty();
        }
        Optional<DateRange> range = extractDateRange(question);
        if (range.isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(new ValidatedChatParameters(range.get(), extractLimit(question)));
    }

    private static Optional<DateRange> extractDateRange(String question) {
        Matcher matcher = DATE.matcher(question);
        LocalDate from = null;
        LocalDate to = null;
        while (matcher.find()) {
            try {
                LocalDate value = LocalDate.parse(matcher.group());
                if (from == null) from = value;
                else if (to == null) to = value;
                else return Optional.empty();
            } catch (DateTimeParseException exception) {
                return Optional.empty();
            }
        }
        LocalDate today = LocalDate.now();
        if (from == null) from = today.withDayOfMonth(1);
        if (to == null) to = today;
        return from.isAfter(to) ? Optional.empty() : Optional.of(new DateRange(from, to));
    }

    private static int extractLimit(String question) {
        Matcher matcher = LIMIT.matcher(question);
        if (!matcher.find()) return DEFAULT_LIMIT;
        try {
            return Math.clamp(Integer.parseInt(matcher.group(1)), 1, 50);
        } catch (NumberFormatException exception) {
            return DEFAULT_LIMIT;
        }
    }
}

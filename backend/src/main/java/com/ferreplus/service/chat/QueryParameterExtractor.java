package com.ferreplus.service.chat;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class QueryParameterExtractor {
    private static final Pattern DATE = Pattern.compile("\\b\\d{4}-\\d{2}-\\d{2}\\b");
    private static final Pattern LIMIT = Pattern.compile("(?i)\\b(?:los|las|top)\\s+(\\d+)\\b");
    private static final Pattern PREVIOUS_MONTH = Pattern.compile(
            "(?i)\\b(?:(?:el|del)\\s+)?(?:ultimo|último)\\s+mes\\b"
                    + "|\\b(?:(?:el|del)\\s+)?mes\\s+pasado\\b");
    private static final Pattern THIS_MONTH = Pattern.compile("(?i)\\beste\\s+mes\\b");
    private static final int DEFAULT_LIMIT = 10;

    private QueryParameterExtractor() {
    }

    public static Optional<ValidatedChatParameters> extract(String question) {
        if (question == null || question.isBlank()) {
            return Optional.empty();
        }
        Optional<DateRange> range = extractDateRange(question);
        if (range.isEmpty() && (DATE.matcher(question).find() || containsUnsafeSyntax(question))) {
            return Optional.empty();
        }
        return Optional.of(new ValidatedChatParameters(range, extractLimit(question)));
    }

    private static Optional<DateRange> extractDateRange(String question) {
        if (containsUnsafeSyntax(question)) {
            return Optional.empty();
        }
        LocalDate today = LocalDate.now();
        if (PREVIOUS_MONTH.matcher(question).find()) {
            LocalDate previousMonth = today.minusMonths(1);
            return Optional.of(new DateRange(previousMonth.withDayOfMonth(1),
                    previousMonth.withDayOfMonth(previousMonth.lengthOfMonth())));
        }
        if (THIS_MONTH.matcher(question).find()) {
            return Optional.of(new DateRange(today.withDayOfMonth(1), today));
        }
        Matcher matcher = DATE.matcher(question);
        LocalDate from = null;
        LocalDate to = null;
        int dateCount = 0;
        while (matcher.find()) {
            try {
                LocalDate value = LocalDate.parse(matcher.group());
                if (from == null) from = value;
                else if (to == null) to = value;
                else return Optional.empty();
                dateCount++;
            } catch (DateTimeParseException exception) {
                return Optional.empty();
            }
        }
        if (dateCount == 0) {
            return Optional.empty();
        } else if (dateCount == 1) {
            to = from;
        }
        return from.isAfter(to) ? Optional.empty() : Optional.of(new DateRange(from, to));
    }

    private static boolean containsUnsafeSyntax(String question) {
        return question.contains(";") || question.contains("--")
                || question.contains("/*") || question.contains("*/");
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

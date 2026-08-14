package com.ferreplus.service.chat;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class QueryParameterExtractorTest {
    @Test
    void singleFutureDateIsUsedAsBothRangeBounds() {
        var result = QueryParameterExtractor.extract("ventas del 2027-01-01");

        assertThat(result).isPresent();
        assertThat(result.orElseThrow().dateRange())
                .isEqualTo(Optional.of(new DateRange(LocalDate.of(2027, 1, 1), LocalDate.of(2027, 1, 1))));
    }

    @Test
    void invertedExplicitDatesAreRejected() {
        assertThat(QueryParameterExtractor.extract("ventas del 2026-08-14 al 2026-08-01")).isEmpty();
    }

    @Test
    void absentDatesRepresentNoRange() {
        assertThat(QueryParameterExtractor.extract("compra mas cara")).get()
                .extracting(ValidatedChatParameters::dateRange)
                .isEqualTo(Optional.empty());
    }

    @Test
    void limitsAreClampedAndDefaulted() {
        assertThat(QueryParameterExtractor.extract("los 500 productos mas vendidos")).get()
                .extracting(ValidatedChatParameters::limit).isEqualTo(50);
        assertThat(QueryParameterExtractor.extract("productos mas vendidos")).get()
                .extracting(ValidatedChatParameters::limit).isEqualTo(10);
    }

    @Test
    void previousMonthIsCalendarMonth() {
        LocalDate today = LocalDate.now();
        LocalDate previousMonth = today.minusMonths(1);

        assertThat(QueryParameterExtractor.extract("mayor gasto del ultimo mes")).get()
                .extracting(ValidatedChatParameters::dateRange)
                .isEqualTo(Optional.of(new DateRange(previousMonth.withDayOfMonth(1),
                        previousMonth.withDayOfMonth(previousMonth.lengthOfMonth()))));
    }

    @Test
    void validDateWithSqlInjectionIsRejected() {
        assertThat(QueryParameterExtractor.extract("ventas del 2024-01-01'; DROP TABLE ventas;--")).isEmpty();
    }
}

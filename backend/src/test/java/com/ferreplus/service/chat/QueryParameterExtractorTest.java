package com.ferreplus.service.chat;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class QueryParameterExtractorTest {
    @Test
    void singleFutureDateIsUsedAsBothRangeBounds() {
        var result = QueryParameterExtractor.extract("ventas del 2027-01-01");

        assertThat(result).isPresent();
        assertThat(result.orElseThrow().dateRange())
                .isEqualTo(new DateRange(LocalDate.of(2027, 1, 1), LocalDate.of(2027, 1, 1)));
    }

    @Test
    void invertedExplicitDatesAreRejected() {
        assertThat(QueryParameterExtractor.extract("ventas del 2026-08-14 al 2026-08-01")).isEmpty();
    }
}

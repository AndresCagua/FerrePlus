package com.ferreplus.service.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ferreplus.entity.DocumentEmbedding;
import com.ferreplus.repository.DocumentEmbeddingRepository;
import com.ferreplus.service.EmbeddingService;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class RagServiceTest {

    @Test
    void search_returnsTopFiveDocumentsAndBuildsSources() {
        EmbeddingService embeddings = mock(EmbeddingService.class);
        DocumentEmbeddingRepository repository = mock(DocumentEmbeddingRepository.class);
        float[] vector = new float[768];
        when(embeddings.embed("productos" )).thenReturn(vector);
        when(embeddings.toPgVector(vector)).thenReturn("[0.0]");
        DocumentEmbedding document = DocumentEmbedding.builder().entityType("PRODUCTO").entityId(3L)
                .contentText("Cable electrico").metadata("{\"title\":\"Cable\"}").build();
        when(repository.findNearest(anyString(), eq(5))).thenReturn(List.of(document));

        RagService.RagResult result = new RagService(embeddings, repository, new ObjectMapper())
                .search("productos", 5);

        assertThat(result.documents()).containsExactly(document);
        assertThat(result.context()).contains("[PRODUCTO:3]", "Cable electrico");
        assertThat(result.sources().getFirst().title()).isEqualTo("Cable");
        verify(embeddings).embed("productos");
        verify(repository).findNearest(eq("[0.0]"), eq(5));
    }

    @Test
    void search_emptyCorpus_returnsEmptyContextAndSources() {
        EmbeddingService embeddings = mock(EmbeddingService.class);
        DocumentEmbeddingRepository repository = mock(DocumentEmbeddingRepository.class);
        when(embeddings.embed(anyString())).thenReturn(new float[768]);
        when(repository.findNearest(anyString(), eq(5))).thenReturn(List.of());

        RagService.RagResult result = new RagService(embeddings, repository, new ObjectMapper())
                .search("sin datos", 5);

        assertThat(result.documents()).isEmpty();
        assertThat(result.context()).isEmpty();
        assertThat(result.sources()).isEmpty();
    }
}

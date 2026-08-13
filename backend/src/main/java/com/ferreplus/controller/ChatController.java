package com.ferreplus.controller;

import com.ferreplus.dto.ChatRequest;
import com.ferreplus.dto.ChatResponse;
import com.ferreplus.dto.ChatSource;
import com.ferreplus.service.chat.ChatService;
import com.ferreplus.service.chat.IndexingService;
import com.ferreplus.service.chat.RagService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;
    private final IndexingService indexingService;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ChatResponse> chat(@Valid @RequestBody ChatRequest request) {
        ChatService.ChatResult result = chatService.answer(request.question());
        List<ChatSource> sources = result.sources().stream()
                .map(this::toChatSource)
                .toList();
        return ResponseEntity.ok(new ChatResponse(result.answer(), sources));
    }

    @PostMapping("/index/rebuild")
    @PreAuthorize("hasAuthority('CHAT_INDEX_REBUILD')")
    public ResponseEntity<IndexingService.RebuildResult> rebuildIndex() {
        return ResponseEntity.ok(indexingService.rebuildAll());
    }

    private ChatSource toChatSource(RagService.Source source) {
        Map<String, Object> metadata = Map.of("title", source.title());
        return new ChatSource(source.entityType(), source.entityId(), source.title(), metadata);
    }
}

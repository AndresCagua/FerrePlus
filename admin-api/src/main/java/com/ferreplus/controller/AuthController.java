package com.ferreplus.controller;

import com.ferreplus.dto.AuthLoginDTO;
import com.ferreplus.dto.AuthResponseDTO;
import com.ferreplus.dto.UsuarioRequestDTO;
import com.ferreplus.service.AuthService;
import com.ferreplus.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "http://localhost:4200")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final UsuarioService usuarioService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDTO> login(@Valid @RequestBody AuthLoginDTO dto) {
        AuthResponseDTO response = authService.login(dto);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody UsuarioRequestDTO dto) {
        if (usuarioService.list().isEmpty()) {
            return ResponseEntity.ok(usuarioService.create(dto));
        }
        return ResponseEntity.badRequest().body("Ya existe un usuario administrador en el sistema");
    }
}

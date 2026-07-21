package com.ferreplus.service;

import com.ferreplus.dto.CambioPasswordDTO;
import com.ferreplus.dto.UsuarioRequestDTO;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final RolService rolService;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<Usuario> list() {
        return usuarioRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Usuario getById(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado con id: " + id));
    }

    public Usuario create(UsuarioRequestDTO dto) {
        if (dto.getPassword() == null || dto.getPassword().isBlank()) {
            throw new BadRequestException("La contraseña es obligatoria");
        }

        if (usuarioRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new BadRequestException("El email ya está registrado");
        }

        Rol rol = rolService.getById(dto.getRolId());

        Usuario usuario = Usuario.builder()
                .nombre(dto.getNombre())
                .email(dto.getEmail())
                .password(passwordEncoder.encode(dto.getPassword()))
                .telefono(dto.getTelefono())
                .rol(rol)
                .activo(true)
                .build();

        return usuarioRepository.save(usuario);
    }

    public Usuario update(Long id, UsuarioRequestDTO dto) {
        Usuario usuario = getById(id);

        usuario.setNombre(dto.getNombre());
        usuario.setTelefono(dto.getTelefono());
        usuario.setActivo(true);

        if (dto.getEmail() != null && !dto.getEmail().equals(usuario.getEmail())) {
            if (usuarioRepository.findByEmail(dto.getEmail()).isPresent()) {
                throw new BadRequestException("El email ya está registrado");
            }
            usuario.setEmail(dto.getEmail());
        }

        if (dto.getRolId() != null) {
            Rol rol = rolService.getById(dto.getRolId());
            usuario.setRol(rol);
        }

        if (dto.getPassword() != null && !dto.getPassword().isBlank()) {
            usuario.setPassword(passwordEncoder.encode(dto.getPassword()));
        }

        return usuarioRepository.save(usuario);
    }

    public void delete(Long id) {
        Usuario usuario = getById(id);
        usuario.setActivo(false);
        usuarioRepository.save(usuario);
    }

    @Transactional(readOnly = true)
    public Usuario getByEmail(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado con email: " + email));
    }

    public void cambiarPassword(Long id, CambioPasswordDTO dto) {
        Usuario usuario = getById(id);

        if (!passwordEncoder.matches(dto.getPasswordActual(), usuario.getPassword())) {
            throw new BadRequestException("La contraseña actual no es correcta");
        }

        usuario.setPassword(passwordEncoder.encode(dto.getNuevoPassword()));
        usuarioRepository.save(usuario);
    }
}

package com.ferreplus.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductoRankingDTO {

    private Long productoId;
    private String nombre;
    private Long totalVendido;
}

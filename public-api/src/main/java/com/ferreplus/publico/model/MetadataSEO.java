package com.ferreplus.publico.model;

public record MetadataSEO(String title, String description, String canonical, OpenGraph openGraph) {
    public record OpenGraph(String title, String description, String imageObjectKey) {}
}

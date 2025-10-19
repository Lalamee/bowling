package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Table(name = "parts_catalog")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PartsCatalog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "catalog_id")
    private Long catalogId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manufacturer_id")
    private Manufacturer manufacturer;

    @Column(name = "catalog_number")
    private String catalogNumber;

    @Column(name = "official_name_en")
    private String officialNameEn;

    @Column(name = "official_name_ru")
    private String officialNameRu;

    @Column(name = "common_name")
    private String commonName;

    @Column(name = "description")
    private String description;

    @Column(name = "normal_service_life")
    private Integer normalServiceLife;

    @Column(name = "unit")
    private String unit;

    @Column(name = "is_unique")
    private Boolean isUnique;
}

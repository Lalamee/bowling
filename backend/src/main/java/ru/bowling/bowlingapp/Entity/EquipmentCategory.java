package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "equipment_category")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EquipmentCategory {

    @Id
    @Column(name = "id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private EquipmentCategory parent;

    @Column(name = "level", nullable = false)
    private Integer level;

    @Column(name = "brand")
    private String brand;

    @Column(name = "code")
    private String code;

    @Column(name = "name_ru", nullable = false)
    private String nameRu;

    @Column(name = "name_en")
    private String nameEn;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;
}

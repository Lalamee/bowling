package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Table(name = "club_equipment_types")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ClubEquipmentType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false)
    private BowlingClub club;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipment_type_id", nullable = false)
    private EquipmentType equipmentType;

    @Column(name = "lanes_count")
    private Integer lanesCount; // количество дорожек с данным типом оборудования

    @Column(name = "other_name")
    private String otherName; // если выбран "Other" - указать название
}

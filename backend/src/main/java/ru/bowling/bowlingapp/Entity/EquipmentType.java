package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Table(name = "equipment_type")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class EquipmentType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "equipment_type_id")
    private Integer equipmentTypeId;

    @Column(name = "name", nullable = false, unique = true)
    private String name; // AMF, Brunswick, VIA, XIMA, Other

    @Column(name = "description")
    private String description;
}

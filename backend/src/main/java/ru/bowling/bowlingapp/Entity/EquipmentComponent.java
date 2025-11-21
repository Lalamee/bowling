package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "equipment_components")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EquipmentComponent {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        @Column(name = "component_id")
        private Long componentId;

        @Column(name = "name", nullable = false)
        private String name;

        @Column(name = "manufacturer")
        private String manufacturer;

        @Column(name = "category")
        private String category;

        @Column(name = "code")
        private String code;

        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "parent_id")
        private EquipmentComponent parent;

        @Column(name = "notes", length = 2000)
        private String notes;
}

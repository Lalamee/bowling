package ru.bowling.bowlingapp.Entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "part_locations")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PartLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "location_id")
    private Integer locationId;

    @Column(name = "name", nullable = false, unique = true)
    private String name;

    @Column(name = "location_description")
    private String locationDescription;

    @Column(name = "is_central")
    private Boolean isCentral;

    @Column(name = "warehouse_id")
    private Integer warehouseId;
}


package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Table(name = "access_level")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AccessLevel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "access_level_id")
    private Integer accessLevelId;

    @Column(name = "name", nullable = false, unique = true)
    private String name;
}


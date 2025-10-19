package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Table(name = "education_level")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class EducationLevel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "education_level_id")
    private Integer educationLevelId;

    @Column(name = "name", nullable = false, unique = true)
    private String name;
}



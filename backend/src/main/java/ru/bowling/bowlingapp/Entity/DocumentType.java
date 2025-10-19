package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Table(name = "document_type")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class DocumentType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "document_type_id")
    private Integer documentTypeId;

    @Column(name = "name", nullable = false, unique = true)
    private String name;
}


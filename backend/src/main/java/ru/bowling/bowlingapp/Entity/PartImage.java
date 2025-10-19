package ru.bowling.bowlingapp.Entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Table(name = "part_images")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PartImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "image_id")
    private Long imageId;

    @Column(name = "catalog_id")
    private Long catalogId;

    @Column(name = "image_url")
    private String imageUrl;

}

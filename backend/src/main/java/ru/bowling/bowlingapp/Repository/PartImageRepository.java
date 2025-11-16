package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.PartImage;

import java.util.Optional;

@Repository
public interface PartImageRepository extends JpaRepository<PartImage, Long> {
    Optional<PartImage> findFirstByCatalogId(Long catalogId);
}

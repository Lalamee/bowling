package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.TechnicalDocument;

import java.util.Collection;
import java.util.List;

public interface TechnicalDocumentRepository extends JpaRepository<TechnicalDocument, Long> {

    List<TechnicalDocument> findByClubClubIdIn(Collection<Long> clubIds);
}

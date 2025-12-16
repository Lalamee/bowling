package ru.bowling.bowlingapp.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.bowling.bowlingapp.Entity.PartsCatalog;

import java.util.List;
import java.util.Optional;

@Repository
public interface PartsCatalogRepository extends JpaRepository<PartsCatalog, Long> {

	Optional<PartsCatalog> findByCatalogNumber(String catalogNumber);
	
	List<PartsCatalog> findByIsUniqueTrue();
	
	List<PartsCatalog> findByOfficialNameRuContainingIgnoreCase(String name);
	
	List<PartsCatalog> findByOfficialNameEnContainingIgnoreCase(String name);
	
	List<PartsCatalog> findByCommonNameContainingIgnoreCase(String name);
	
	List<PartsCatalog> findByCatalogNumberContainingIgnoreCase(String catalogNumber);

        @Query("select p from PartsCatalog p left join p.manufacturer m " +
                        "where (:q is null or CAST(p.officialNameRu AS text) ilike CAST(concat('%', CAST(:q AS text), '%') AS text) " +
                        "or CAST(p.officialNameEn AS text) ilike CAST(concat('%', CAST(:q AS text), '%') AS text) " +
                        "or CAST(p.commonName AS text) ilike CAST(concat('%', CAST(:q AS text), '%') AS text) " +
                        "or CAST(p.catalogNumber AS text) ilike CAST(concat('%', CAST(:q AS text), '%') AS text)) " +
                        "and (:manufacturerId is null or m.manufacturerId = :manufacturerId) " +
                        "and (:isUnique is null or p.isUnique = :isUnique) " +
                        "and (:categoryCodes is null or CAST(p.categoryCode AS text) in :categoryCodes)")
        Page<PartsCatalog> search(
                @Param("q") String q,
                @Param("manufacturerId") Integer manufacturerId,
                @Param("isUnique") Boolean isUnique,
                @Param("categoryCodes") List<String> categoryCodes,
                Pageable pageable
        );

        @Query("select p from PartsCatalog p left join p.manufacturer m " +
                        "where CAST(p.officialNameRu AS text) ilike CAST(concat('%', CAST(:query AS text), '%') AS text) " +
                        "or CAST(p.officialNameEn AS text) ilike CAST(concat('%', CAST(:query AS text), '%') AS text) " +
                        "or CAST(p.commonName AS text) ilike CAST(concat('%', CAST(:query AS text), '%') AS text) " +
                        "or CAST(p.catalogNumber AS text) ilike CAST(concat('%', CAST(:query AS text), '%') AS text) " +
                        "or CAST(p.description AS text) ilike CAST(concat('%', CAST(:query AS text), '%') AS text)")
        List<PartsCatalog> searchByNameOrNumberOrDescription(@Param("query") String query);

        @Query("select p from PartsCatalog p " +
                        "where CAST(p.commonName AS text) ilike CAST(:name AS text) " +
                        "or CAST(p.officialNameRu AS text) ilike CAST(:name AS text) " +
                        "or CAST(p.officialNameEn AS text) ilike CAST(:name AS text)")
        List<PartsCatalog> findByAnyNameIgnoreCase(@Param("name") String name);
}

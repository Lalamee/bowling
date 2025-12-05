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
                        "where (:q is null or lower(p.officialNameRu) like lower(concat('%', :q, '%')) " +
                        "or lower(p.officialNameEn) like lower(concat('%', :q, '%')) " +
                        "or lower(p.commonName) like lower(concat('%', :q, '%')) " +
                        "or lower(p.catalogNumber) like lower(concat('%', :q, '%'))) " +
                        "and (:manufacturerId is null or m.manufacturerId = :manufacturerId) " +
                        "and (:isUnique is null or p.isUnique = :isUnique) " +
                        "and (:categoryCodes is null or trim(p.categoryCode) in :categoryCodes)")
        Page<PartsCatalog> search(
                @Param("q") String q,
                @Param("manufacturerId") Integer manufacturerId,
                @Param("isUnique") Boolean isUnique,
                @Param("categoryCodes") List<String> categoryCodes,
                Pageable pageable
        );

        @Query("select p from PartsCatalog p left join p.manufacturer m " +
                        "where lower(p.officialNameRu) like lower(concat('%', :query, '%')) " +
                        "or lower(p.officialNameEn) like lower(concat('%', :query, '%')) " +
                        "or lower(p.commonName) like lower(concat('%', :query, '%')) " +
                        "or lower(p.catalogNumber) like lower(concat('%', :query, '%'))")
        List<PartsCatalog> searchByNameOrNumber(@Param("query") String query);

        @Query("select p from PartsCatalog p " +
                        "where lower(p.commonName) = lower(:name) " +
                        "or lower(p.officialNameRu) = lower(:name) " +
                        "or lower(p.officialNameEn) = lower(:name)")
        List<PartsCatalog> findByAnyNameIgnoreCase(@Param("name") String name);
}

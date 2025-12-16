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

        @Query(value = """
                        select p.* from parts_catalog p
                        left join manufacturer m on m.manufacturer_id = p.manufacturer_id
                        where (:q is null or
                                       p.official_name_ru::text ilike concat('%', cast(:q as text), '%') or
                                       p.official_name_en::text ilike concat('%', cast(:q as text), '%') or
                                       p.common_name::text ilike concat('%', cast(:q as text), '%') or
                                       p.catalog_number::text ilike concat('%', cast(:q as text), '%'))
                          and (:manufacturerId is null or m.manufacturer_id = :manufacturerId)
                          and (:isUnique is null or p.is_unique = :isUnique)
                          and (:categoryCodes is null or lower(trim(p.category_code)) = any(:categoryCodes))
                        """,
                        countQuery = """
                        select count(*) from parts_catalog p
                        left join manufacturer m on m.manufacturer_id = p.manufacturer_id
                        where (:q is null or
                                       p.official_name_ru::text ilike concat('%', cast(:q as text), '%') or
                                       p.official_name_en::text ilike concat('%', cast(:q as text), '%') or
                                       p.common_name::text ilike concat('%', cast(:q as text), '%') or
                                       p.catalog_number::text ilike concat('%', cast(:q as text), '%'))
                          and (:manufacturerId is null or m.manufacturer_id = :manufacturerId)
                          and (:isUnique is null or p.is_unique = :isUnique)
                          and (:categoryCodes is null or lower(trim(p.category_code)) = any(:categoryCodes))
                        """,
                        nativeQuery = true)
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
                        "or lower(p.catalogNumber) like lower(concat('%', :query, '%')) " +
                        "or lower(p.description) like lower(concat('%', :query, '%'))")
        List<PartsCatalog> searchByNameOrNumberOrDescription(@Param("query") String query);

        @Query("select p from PartsCatalog p " +
                        "where lower(p.commonName) like lower(:name) " +
                        "or lower(p.officialNameRu) like lower(:name) " +
                        "or lower(p.officialNameEn) like lower(:name)")
        List<PartsCatalog> findByAnyNameIgnoreCase(@Param("name") String name);
}

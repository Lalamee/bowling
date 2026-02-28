package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.AccountType;

import java.util.Optional;

public interface AccountTypeRepository extends JpaRepository<AccountType, Long> {
    Optional<AccountType> findByName(String name);
    Optional<AccountType> findFirstByNameIgnoreCaseOrderByAccountTypeIdAsc(String name);
    Optional<AccountType> findByNameIgnoreCase(String name);
}

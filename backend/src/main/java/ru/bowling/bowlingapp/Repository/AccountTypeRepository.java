package ru.bowling.bowlingapp.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import ru.bowling.bowlingapp.Entity.AccountType;

import java.util.Optional;

public interface AccountTypeRepository extends JpaRepository<AccountType, Integer> {
    Optional<AccountType> findByName(String name);
}


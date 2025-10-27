package ru.bowling.bowlingapp.integration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import ru.bowling.bowlingapp.Entity.AccountType;
import ru.bowling.bowlingapp.Entity.BowlingClub;
import ru.bowling.bowlingapp.Entity.Role;
import ru.bowling.bowlingapp.Repository.AccountTypeRepository;
import ru.bowling.bowlingapp.Repository.BowlingClubRepository;
import ru.bowling.bowlingapp.Repository.ClubStaffRepository;
import ru.bowling.bowlingapp.Repository.RefreshTokenRepository;
import ru.bowling.bowlingapp.Repository.RoleRepository;
import ru.bowling.bowlingapp.Repository.UserRepository;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthLoginIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AccountTypeRepository accountTypeRepository;

    @Autowired
    private BowlingClubRepository bowlingClubRepository;

    @Autowired
    private ClubStaffRepository clubStaffRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @BeforeEach
    void setUp() {
        refreshTokenRepository.deleteAll();
        clubStaffRepository.deleteAll();
        userRepository.deleteAll();
        roleRepository.deleteAll();
        accountTypeRepository.deleteAll();
        bowlingClubRepository.deleteAll();
    }

    @Test
    void registrationFollowedByLoginCompletesSuccessfully() throws Exception {
        Role role = roleRepository.save(Role.builder().name("CLUB_OWNER").build());
        AccountType accountType = accountTypeRepository.save(AccountType.builder().name("CLUB_OWNER").build());

        String registerPayload = String.format("{" +
                "\"user\": {" +
                "\"phone\": \"+7 (999) 000-11-22\"," +
                "\"password\": \"password123\"," +
                "\"roleId\": %d," +
                "\"accountTypeId\": %d" +
                "}," +
                "\"ownerProfile\": {" +
                "\"inn\": \"1234567890\"," +
                "\"legalName\": \"Test Club LLC\"," +
                "\"contactPerson\": \"Test Owner\"," +
                "\"contactPhone\": \"+7 (999) 000-11-22\"" +
                "}," +
                "\"club\": {" +
                "\"name\": \"Test Club\"," +
                "\"address\": \"Test Street 1\"," +
                "\"lanesCount\": 4," +
                "\"contactPhone\": \"+7 (999) 000-11-22\"" +
                "}" +
                "}",
                role.getRoleId(), accountType.getAccountTypeId());

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerPayload))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"phone\":\"+7 (999) 000-11-22\",\"password\":\"password123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"phone\":\"+7 (999) 000-11-22\",\"password\":\"password123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty());
    }

    @Test
    void mechanicRegistrationAlsoAllowsLogin() throws Exception {
        Role mechanicRole = roleRepository.save(Role.builder().name("MECHANIC").build());
        AccountType individual = accountTypeRepository.save(AccountType.builder().name("INDIVIDUAL").build());
        BowlingClub club = bowlingClubRepository.save(BowlingClub.builder()
                .name("Mechanic Test Club")
                .address("Mechanic Street 5")
                .lanesCount(6)
                .isActive(true)
                .isVerified(false)
                .build());

        String registerPayload = String.format("{" +
                "\"user\": {" +
                "\"phone\": \"+7 (999) 111-22-33\"," +
                "\"password\": \"password123\"," +
                "\"roleId\": %d," +
                "\"accountTypeId\": %d" +
                "}," +
                "\"mechanicProfile\": {" +
                "\"fullName\": \"Mechanic Tester\"," +
                "\"birthDate\": \"1990-01-01\"," +
                "\"educationLevelId\": 1," +
                "\"educationalInstitution\": \"Tech School\"," +
                "\"totalExperienceYears\": 5," +
                "\"bowlingExperienceYears\": 3," +
                "\"isEntrepreneur\": false," +
                "\"specializationId\": 1," +
                "\"skills\": \"Testing Machines\"," +
                "\"advantages\": \"Detail oriented\"," +
                "\"workPlaces\": \"Test Club\"," +
                "\"workPeriods\": \"2018-2024\"," +
                "\"clubId\": %d" +
                "}" +
                "}",
                mechanicRole.getRoleId(), individual.getAccountTypeId(), club.getClubId());

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerPayload))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"phone\":\"+7 (999) 111-22-33\",\"password\":\"password123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"phone\":\"+7 (999) 111-22-33\",\"password\":\"password123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty());
    }
}

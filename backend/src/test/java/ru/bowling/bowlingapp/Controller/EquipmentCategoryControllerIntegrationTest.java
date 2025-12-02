package ru.bowling.bowlingapp.Controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import ru.bowling.bowlingapp.Entity.EquipmentCategory;
import ru.bowling.bowlingapp.Repository.EquipmentCategoryRepository;

import org.junit.jupiter.api.BeforeEach;

import java.util.List;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EquipmentCategoryControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private EquipmentCategoryRepository equipmentCategoryRepository;

    @BeforeEach
    void setUpData() {
        equipmentCategoryRepository.deleteAll();

        EquipmentCategory brand = equipmentCategoryRepository.save(EquipmentCategory.builder()
                .id(1000L)
                .level(1)
                .brand("Brunswick")
                .nameRu("Brunswick")
                .nameEn("Brunswick")
                .sortOrder(1)
                .isActive(true)
                .build());

        EquipmentCategory pinsetters = saveChild(1100L, brand, 2, "Пинсеттеры", "Pinsetter parts", 1);
        EquipmentCategory scoring = saveChild(1110L, brand, 2, "Скоринг-системы", "Scoring & Management systems", 2);
        EquipmentCategory returns = saveChild(1120L, brand, 2, "Системы возврата шара", "Ball Returns parts", 3);
        EquipmentCategory laneParts = saveChild(1130L, brand, 2, "Комплектующие дорожек", "Lane parts", 4);
        EquipmentCategory laneMachines = saveChild(1140L, brand, 2, "Натричные машины", "Lane Machines", 5);
        saveChild(1150L, brand, 2, "Мебель, фурнитура", "Furniture & fixtures", 6);
        saveChild(1160L, brand, 2, "Расходники, про-шоп и уход за дорожками", "Consumables & pro shop", 7);
        saveChild(1170L, brand, 2, "Прочее", "Miscellaneous", 8);
        saveChild(1180L, brand, 2, "Шары", "Balls", 9);
        saveChild(1190L, brand, 2, "Кегли", "Pins", 10);
        saveChild(1200L, brand, 2, "Прокатная обувь", "Rental shoes", 11);
        saveChild(1210L, brand, 2, "Средства для ухода за дорожками", "Lane care products", 12);
        EquipmentCategory electronics = saveChild(1220L, brand, 2, "Электроника", "Electronics", 13);
        saveChild(1230L, brand, 2, "GS-модели", "GS models", 14);
        saveChild(1240L, brand, 2, "Механика/кинематика", "Mechanics & kinematics", 15);

        saveChildren(pinsetters, List.of(
                new ChildSpec(1101L, "Boost ST (стринг-кегли)", "Boost ST (string pins)", 1),
                new ChildSpec(1102L, "GS NXT", "GS NXT", 2),
                new ChildSpec(1103L, "GS-X", "GS-X", 3),
                new ChildSpec(1104L, "GS-98", "GS-98", 4),
                new ChildSpec(1105L, "GS-96", "GS-96", 5),
                new ChildSpec(1106L, "GS-92", "GS-92", 6)
        ));

        saveChildren(scoring, List.of(
                new ChildSpec(1111L, "Sync Invicta / Sync Spark", "Sync Invicta / Sync Spark", 1),
                new ChildSpec(1112L, "Sync", "Sync", 2),
                new ChildSpec(1113L, "Vector Plus", "Vector Plus", 3),
                new ChildSpec(1114L, "Vector", "Vector", 4),
                new ChildSpec(1115L, "Frameworx", "Frameworx", 5)
        ));

        saveChildren(returns, List.of(
                new ChildSpec(1121L, "Framework Ball Return", "Framework Ball Return", 1),
                new ChildSpec(1122L, "Center Stage Ball Return", "Center Stage Ball Return", 2)
        ));

        saveChildren(laneParts, List.of(
                new ChildSpec(1131L, "Синтетическое покрытие", "Synthetic lane surface", 1),
                new ChildSpec(1132L, "Бамперы", "Bumpers", 2),
                new ChildSpec(1133L, "Кеппинги, фолл-линии", "Capping, foul units", 3),
                new ChildSpec(1134L, "Kickbacks, пиндеки, гаттеры", "Kickbacks, pindecks, gutters", 4),
                new ChildSpec(1135L, "Деревянная подоснова и прочее", "Wood substructure & other", 5)
        ));

        saveChildren(laneMachines, List.of(
                new ChildSpec(1141L, "Phoenix Lite (LT4)", "Phoenix Lite (LT4)", 1),
                new ChildSpec(1142L, "NEXUS", "NEXUS", 2),
                new ChildSpec(1143L, "Envoy", "Envoy", 3),
                new ChildSpec(1144L, "Crossfire", "Crossfire", 4),
                new ChildSpec(1145L, "Другие (QubicaAMF, Kegel и др.)", "Other (including QubicaAMF, Kegel)", 5)
        ));

        saveChildren(electronics, List.of(
                new ChildSpec(1221L, "Silver Box", "Silver Box", 1),
                new ChildSpec(1222L, "Red Box", "Red Box", 2),
                new ChildSpec(1223L, "Консолидированная и Nexgen электроника", "Consolidated & Nexgen electronics", 3)
        ));
    }

    private EquipmentCategory saveChild(Long id, EquipmentCategory parent, int level, String nameRu, String nameEn, int sortOrder) {
        return equipmentCategoryRepository.save(EquipmentCategory.builder()
                .id(id)
                .parent(parent)
                .level(level)
                .brand("Brunswick")
                .nameRu(nameRu)
                .nameEn(nameEn)
                .sortOrder(sortOrder)
                .isActive(true)
                .build());
    }

    private void saveChildren(EquipmentCategory parent, List<ChildSpec> specs) {
        specs.forEach(spec -> saveChild(spec.id, parent, parent.getLevel() + 1, spec.nameRu, spec.nameEn, spec.sortOrder));
    }

    private record ChildSpec(Long id, String nameRu, String nameEn, int sortOrder) {}

    @Test
    @DisplayName("Корневой уровень возвращает только бренд Brunswick")
    @WithMockUser(roles = "MECHANIC")
    void rootLevelReturnsBrand() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "Brunswick")
                        .param("level", "1")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].nameRu").value("Brunswick"))
                .andExpect(jsonPath("$[0].parentId").doesNotExist());
    }

    @Test
    @DisplayName("Категории бренда отдаются только для выбранного parentId")
    @WithMockUser(roles = "MECHANIC")
    void secondLevelCategoriesAreScopedByParent() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "Brunswick")
                        .param("parentId", "1000")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(15)))
                .andExpect(jsonPath("$[*].nameRu", containsInAnyOrder(
                        "Пинсеттеры",
                        "Скоринг-системы",
                        "Системы возврата шара",
                        "Комплектующие дорожек",
                        "Натричные машины",
                        "Мебель, фурнитура",
                        "Расходники, про-шоп и уход за дорожками",
                        "Прочее",
                        "Шары",
                        "Кегли",
                        "Прокатная обувь",
                        "Средства для ухода за дорожками",
                        "Электроника",
                        "GS-модели",
                        "Механика/кинематика"
                )));
    }

    @Test
    @DisplayName("Дочерние элементы пинсеттеров ограничены своим parentId")
    @WithMockUser(roles = "MECHANIC")
    void pinsetterChildren() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "Brunswick")
                        .param("parentId", "1100")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(6)))
                .andExpect(jsonPath("$[*].nameRu", contains(
                        "Boost ST (стринг-кегли)",
                        "GS NXT",
                        "GS-X",
                        "GS-98",
                        "GS-96",
                        "GS-92"
                )));
    }

    @Test
    @DisplayName("Дочерние элементы натричных машин возвращаются корректно")
    @WithMockUser(roles = "MECHANIC")
    void laneMachineChildren() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "Brunswick")
                        .param("parentId", "1140")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(5)))
                .andExpect(jsonPath("$[*].nameRu", contains(
                        "Phoenix Lite (LT4)",
                        "NEXUS",
                        "Envoy",
                        "Crossfire",
                        "Другие (QubicaAMF, Kegel и др.)"
                )));
    }

    @Test
    @DisplayName("Запрос без parentId для глубокого уровня отклоняется")
    @WithMockUser(roles = "MECHANIC")
    void cannotSkipLevels() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "Brunswick")
                        .param("level", "3")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Некорректный parentId возвращает пустой список")
    @WithMockUser(roles = "MECHANIC")
    void invalidParentReturnsEmptyList() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "Brunswick")
                        .param("parentId", "999999")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }
}

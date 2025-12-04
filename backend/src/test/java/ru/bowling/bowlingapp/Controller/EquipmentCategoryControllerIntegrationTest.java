package ru.bowling.bowlingapp.Controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

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
@Sql(scripts = "/db/test_equipment_hierarchy.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD)
class EquipmentCategoryControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

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
    @DisplayName("Другие бренды без записей возвращают пустой список")
    @WithMockUser(roles = "MECHANIC")
    void unknownBrandReturnsEmpty() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "QubicaAMF")
                        .param("level", "1")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }

    @Test
    @DisplayName("Несовпадающий бренд не возвращает потомков")
    @WithMockUser(roles = "MECHANIC")
    void mismatchedBrandReturnsEmpty() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "QubicaAMF")
                        .param("parentId", "1000")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }

    @Test
    @DisplayName("Компоненты: корень возвращает только бренд Brunswick")
    @WithMockUser(roles = "MECHANIC")
    void componentRootLevelReturnsBrand() throws Exception {
        mockMvc.perform(get("/api/equipment/components")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name").value("Brunswick"))
                .andExpect(jsonPath("$[0].parentId").doesNotExist())
                .andExpect(jsonPath("$[0].code").value("BRUNSWICK"));
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
    @DisplayName("Категории сортируются по sort_order")
    @WithMockUser(roles = "MECHANIC")
    void categoriesAreSortedBySortOrder() throws Exception {
        mockMvc.perform(get("/api/equipment/categories")
                        .param("brand", "Brunswick")
                        .param("parentId", "1000")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nameRu").value("Пинсеттеры"))
                .andExpect(jsonPath("$[1].nameRu").value("Скоринг-системы"))
                .andExpect(jsonPath("$[2].nameRu").value("Системы возврата шара"));
    }

    @Test
    @DisplayName("Компоненты: категории бренда отдаются только для выбранного parentId")
    @WithMockUser(roles = "MECHANIC")
    void componentSecondLevelCategoriesAreScopedByParent() throws Exception {
        mockMvc.perform(get("/api/equipment/components")
                        .param("parentId", "1000")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(15)))
                .andExpect(jsonPath("$[*].name", containsInAnyOrder(
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
    @DisplayName("Компоненты: дочерние элементы пинсеттеров ограничены своим parentId")
    @WithMockUser(roles = "MECHANIC")
    void componentPinsetterChildren() throws Exception {
        mockMvc.perform(get("/api/equipment/components")
                        .param("parentId", "1100")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(6)))
                .andExpect(jsonPath("$[*].name", contains(
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
    @DisplayName("Компоненты: дочерние элементы натричных машин возвращаются корректно")
    @WithMockUser(roles = "MECHANIC")
    void componentLaneMachineChildren() throws Exception {
        mockMvc.perform(get("/api/equipment/components")
                        .param("parentId", "1140")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(5)))
                .andExpect(jsonPath("$[*].name", contains(
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

    @Test
    @DisplayName("Компоненты: некорректный parentId возвращает пустой список")
    @WithMockUser(roles = "MECHANIC")
    void componentInvalidParentReturnsEmptyList() throws Exception {
        mockMvc.perform(get("/api/equipment/components")
                        .param("parentId", "999999")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", empty()));
    }
}

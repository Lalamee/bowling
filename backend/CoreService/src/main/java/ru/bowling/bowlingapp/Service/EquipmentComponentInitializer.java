package ru.bowling.bowlingapp.Service;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import ru.bowling.bowlingapp.Entity.EquipmentComponent;
import ru.bowling.bowlingapp.Repository.EquipmentComponentRepository;

@Component
@RequiredArgsConstructor
public class EquipmentComponentInitializer implements ApplicationRunner {

        private final EquipmentComponentRepository repository;

        @Override
        @Transactional
        public void run(ApplicationArguments args) {
                seedBrunswickTree();
                seedSwitchTree();
        }

        private void seedBrunswickTree() {
                EquipmentComponent brunswick = ensure("Brunswick", "Brunswick", "BRAND", null, "BRUN", "Главный бренд из схемы");

                EquipmentComponent gsClassic = ensure("GS-96/97/98", "Brunswick", "LINE", brunswick, "GS-9X", "Классические GS линии");
                EquipmentComponent gsx = ensure("GS-X", "Brunswick", "LINE", brunswick, "GS-X", "Современная линейка GS-X");

                EquipmentComponent supplySystem = ensure("Система подачи шара (Front/Back-end)", "Brunswick", "MODULE", gsClassic,
                                "SUPPLY", "Узел подачи шара из схемы");
                ensure("Весовой стол (Scales)", "Brunswick", "NODE", supplySystem, "SCALES", "Весовой стол/датчики веса");
                ensure("Система возврата шара", "Brunswick", "MODULE", gsClassic, "RETURN", "Возврат и транспортировка шара");
                ensure("Пневматика/Компрессор", "Brunswick", "MODULE", gsClassic, "PNEUMATICS", "Пневматические элементы");
                ensure("Привод линии и фурнитура", "Brunswick", "MODULE", gsClassic, "DRIVE", "Привод, ремни, фурнитура");

                EquipmentComponent scoring = ensure("Система подсчета очков (Vector/Sync)", "Brunswick", "SYSTEM", brunswick,
                                "SCORING", "Системы учета очков и ПО");
                ensure("Front Desk (Vector Plus)", "Brunswick", "NODE", scoring, "FDESK", "Рабочее место оператора");
                ensure("Плееры/мониторы", "Brunswick", "NODE", scoring, "DISP", "Мониторы игроков и гостевая зона");

                EquipmentComponent gsxChassis = ensure("GS-X кузов и механика", "Brunswick", "MODULE", gsx, "GSX-MECH",
                                "Корпус и механические узлы GS-X");
                ensure("Электроника GS-X (Silver Box)", "Brunswick", "MODULE", gsx, "GSX-EL", "Блоки Silver Box");
                ensure("Контроллеры и датчики", "Brunswick", "NODE", gsxChassis, "GSX-SENS", "Датчики, кабели, контроллеры");
        }

        private void seedSwitchTree() {
                EquipmentComponent switchBrand = ensure("Switch Bowling", "Switch", "BRAND", null, "SWITCH", "Ветка Switch/Silver Box");

                EquipmentComponent silverBox = ensure("Silver Box", "Switch", "SYSTEM", switchBrand, "SILVER",
                                "Электроника Silver Box из схемы");
                ensure("Электроника/платы", "Switch", "NODE", silverBox, "SILVER-EL", "Платы, кабели, силовые блоки");
                ensure("GS-наворды", "Switch", "MODULE", silverBox, "GS-UPGRADE", "Комплект для модернизации GS под Silver Box");
        }

        private EquipmentComponent ensure(String name, String manufacturer, String category, EquipmentComponent parent, String code,
                        String notes) {
                return repository.findByNameAndManufacturerAndCategory(name, manufacturer, category)
                                .orElseGet(() -> repository.save(EquipmentComponent.builder()
                                                .name(name)
                                                .manufacturer(manufacturer)
                                                .category(category)
                                                .code(code)
                                                .notes(notes)
                                                .parent(parent)
                                                .build()));
        }
}

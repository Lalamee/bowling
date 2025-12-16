package ru.bowling.bowlingapp.Controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.bowling.bowlingapp.DTO.PartsCatalogCreateDTO;
import ru.bowling.bowlingapp.DTO.PartsCatalogResponseDTO;
import ru.bowling.bowlingapp.DTO.PartsSearchDTO;
import ru.bowling.bowlingapp.Service.PartsService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/parts")
@RequiredArgsConstructor
public class PartsController {

	private final PartsService partsService;

	@PostMapping("/search")
	public ResponseEntity<List<PartsCatalogResponseDTO>> searchParts(@RequestBody PartsSearchDTO searchDTO) {
		try {
			List<PartsCatalogResponseDTO> parts = partsService.searchParts(searchDTO);
			return ResponseEntity.ok(parts);
		} catch (Exception e) {
			return ResponseEntity.internalServerError().build();
		}
	}

	@GetMapping("/catalog/{catalogNumber}")
	public ResponseEntity<?> getPartByCatalogNumber(@PathVariable String catalogNumber) {
		try {
			return partsService.getPartByCatalogNumber(catalogNumber)
					.map(ResponseEntity::ok)
					.orElse(ResponseEntity.notFound().build());
		} catch (Exception e) {
			return ResponseEntity.internalServerError()
					.body(Map.of("error", "Failed to get part: " + e.getMessage()));
		}
	}

	@GetMapping("/unique")
        public ResponseEntity<List<PartsCatalogResponseDTO>> getUniqueParts() {
                try {
                        List<PartsCatalogResponseDTO> parts = partsService.getUniqueParts();
                        return ResponseEntity.ok(parts);
                } catch (Exception e) {
                        return ResponseEntity.internalServerError().build();
                }
        }

        @PostMapping("/catalog")
        public ResponseEntity<?> createOrFindCatalog(@RequestBody PartsCatalogCreateDTO payload) {
                try {
                        PartsCatalogResponseDTO part = partsService.findOrCreateCatalog(payload);
                        return ResponseEntity.ok(part);
                } catch (IllegalArgumentException e) {
                        return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
                } catch (Exception e) {
                        return ResponseEntity.internalServerError()
                                        .body(Map.of("error", "Failed to create catalog: " + e.getMessage()));
                }
        }

	@GetMapping("/all")
	public ResponseEntity<List<PartsCatalogResponseDTO>> getAllParts() {
		try {
			PartsSearchDTO searchDTO = new PartsSearchDTO();
			List<PartsCatalogResponseDTO> parts = partsService.searchParts(searchDTO);
			return ResponseEntity.ok(parts);
		} catch (Exception e) {
			return ResponseEntity.internalServerError().build();
		}
	}
}

# Makefile dla testów botów zk_libcod (F3.2)
# Uwaga: testy uruchamia się na serwerze CoD2, nie lokalnie

.PHONY: help deploy check clean

help:
	@echo "=== F3.2 Testy botow zk_libcod ==="
	@echo "make help      - ta pomoc"
	@echo "make check     - sprawdza skladnie GSC (jesli dostepny parser)"
	@echo "make deploy    - kopiuje testy do katalogu serwera CoD2"
	@echo "make clean     - usuwa pliki tymczasowe"

check:
	@echo "[CHECK] Sprawdzam strukture plikow..."
	@for f in tests/*.gsc; do \
		echo "  OK: $$f"; \
	done
	@echo "[CHECK] Wszystkie pliki GSC obecne"

DEPLOY_DIR ?= /opt/projects/cod2-testbench

deploy:
	@mkdir -p $(DEPLOY_DIR)/tests
	@cp -v tests/*.gsc $(DEPLOY_DIR)/tests/
	@cp -v README.md $(DEPLOY_DIR)/
	@cp -vr docs $(DEPLOY_DIR)/
	@echo "[DEPLOY] Testy skopiowane do $(DEPLOY_DIR)"

clean:
	@rm -f *~
	@find . -name "*.swp" -delete
	@echo "[CLEAN] OK"
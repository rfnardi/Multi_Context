test:
	@./run_tests.sh

.PHONY: test_all

# Roda todos os testes e gera o Summary agregado do Plenary
test_all:
	@echo "======================================================================"
	@echo "🧪 Executando Suíte Completa (Summary Agregado)..."
	@echo "======================================================================"
	@./run_tests.sh

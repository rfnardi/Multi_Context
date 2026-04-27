test:
	nvim --headless -c "PlenaryBustedDirectory lua/multi_context/tests/"

.PHONY: test_agregate_results

# Roda todos os testes e gera o Summary agregado do Plenary
test_agregate_results:
	@echo "======================================================================"
	@echo "🧪 Executando Suíte Completa (Summary Agregado)..."
	@echo "======================================================================"
	@./run_tests.sh

.PHONY: doc
doc:
	@echo "📚 Gerando as Help Tags nativas do Vimdoc..."
	nvim --headless -c "helptags doc/" -c "q"
	@echo "✅ Help Tags geradas!"

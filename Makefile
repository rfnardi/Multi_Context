.PHONY: test test_agregate_results doc

test:
	nvim --headless -i NONE -c "PlenaryBustedDirectory lua/multi_context/tests/"

test_agregate_results:
	@echo "======================================================================"
	@echo "🧪 Executando Suíte Completa e Coletando Falhas em Background..."
	@echo "======================================================================"
	@bash ./run_tests.sh 2>&1 | tee test_output.log || true
	@echo ""
	@echo "======================================================================"
	@echo "🔍 RELATÓRIO DE FALHAS (ISOLADO)"
	@echo "======================================================================"
	@# O .* ignora os códigos de cor ANSI em vermelho que o Plenary injeta
	@grep -A 12 "Fail.*||" test_output.log > failures.log || true
	@if [ -s failures.log ]; then \
		cat failures.log; \
		echo "======================================================================"; \
		echo "❌ ALERTA: Há testes falhando no sistema. Veja os detalhes acima."; \
		rm -f test_output.log failures.log; \
		exit 1; \
	else \
		echo "✅ SUCESSO ABSOLUTO! Não há falhas listadas."; \
		rm -f test_output.log failures.log; \
		exit 0; \
	fi

doc:
	@echo "📚 Gerando as Help Tags nativas do Vimdoc..."
	nvim --headless -i NONE -c "helptags doc/" -c "q"
	@echo "✅ Help Tags geradas!"

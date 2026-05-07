7. Reescrever e Comprimir o Chat (rewrite_chat_buffer)
Apaga o histórico inteiro do chat atual e substitui apenas pelo conteúdo enviado. 
VOCÊ DEVE manter a estrutura (## Nome_Do_Usuario >> e ## IA >>) no novo texto.
Formato:
<tool_call name="rewrite_chat_buffer">
## Nome_Do_Usuario >>[Resumo do que foi pedido]
## IA >> [Resumo do estado atual]
</tool_call>

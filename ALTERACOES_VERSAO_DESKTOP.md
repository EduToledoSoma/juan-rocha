# Alterações – Juan Rocha Boxe para Desktop

## Correções solicitadas

1. **Erro vermelho após salvar:** as 10 rotinas `reload()` de formulários e controles passaram a retornar `void`, eliminando a causa `setState() callback argument returned a Future`.
2. **Cartões cortados:** os cards usam altura fixa (169 px na grade) e texto redimensionável com espaço próprio, evitando `BOTTOM OVERFLOWED BY 8.6 PIXELS` no tamanho mostrado.
3. **Paleta:** valores dourados; nomes de cada indicador em etiqueta dourada com letras pretas; bordas douradas para mensalidades vencidas; sem alertas vermelhos de debug na interface corrigida.
4. **Nomes exatos:** alunos com matrícula ativa, mensalidades vencidas, receitas recebidas hoje/no mês, despesas lançadas no mês e presenças registradas hoje.
5. **Navegação:** toque/click em alunos -> Alunos; vencidas -> Mensalidades; receitas/despesas -> Financeiro; presenças -> Check-in.
6. **Layout desktop:** barra lateral em janelas largas; menu inferior mantido em janelas pequenas.
7. **Dados em Linux e Windows:** SQLite FFI em pasta de suporte do aplicativo, mantendo SQLite nativo no Android e iOS.
8. **Exportações:** PDF/CSV/JSON são gravados em uma pasta `JuanRochaBoxe/Exportacoes` dentro de Documentos no desktop. No celular permanece o compartilhamento nativo.
9. **Android XML:** consertado o fundo de inicialização antes fornecido no pacote Android.

## Verificações realizadas neste ambiente

- `python scripts/validar_schema.py` – passou (15 declarações e 5 restrições).
- Conferência estática de todas as rotinas `reload()` e referências de navegação – passou.
- YAML do GitHub Actions de Linux/Windows – analisado corretamente.
- Ícone original convertido para formato `.ico` de Windows.
- Integridade do pacote ZIP – testada.

## Limitações

- **Não foi possível executar Flutter** neste ambiente, portanto **não houve compilação nativa Linux/Windows nem testes de UI nos desktops**. Os workflows do GitHub Actions geram os binários quando rodados no repositório.
- Não há sincronização: cada instalação tem banco independente.
- Não existe ainda login multiusuário, criptografia de banco, sincronização, nem restauração automática de backups. Uso com dados reais exige mais trabalho de segurança.

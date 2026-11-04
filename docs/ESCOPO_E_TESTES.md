# Status técnico da primeira entrega — Juan Rocha Boxe

Data: 04/11/2026

## Implementado no código

| Área | Entrega | Observação |
| --- | --- | --- |
| Marca | Logo original preta e dourada, tema e app icon | Ícone gerado pelo comando do Flutter no Mac |
| Alunos | CRUD básico, cadastro detalhado, busca e filtros | Foto e validação de CPF ausentes |
| Planos | CRUD, valores em centavos, status | Ainda sem automação de reajustes |
| Agenda | Turmas, dias, professor, horário | Sem agenda recorrente individual e detecção de conflito |
| Frequência | Presença/falta/justificada por dia e aluno, histórico | Alerta depende de ausências registradas |
| Financeiro | Receitas, despesas, pagamentos parciais, caixa | Sem estornos/conciliador |
| Mensalidades | Competência única, cálculo de atraso, recibo PDF | Geração por comando manual |
| Produtos | Cadastro de estoque e venda atômica | Sem pedidos múltiplos por transação |
| CRM | Etapas e conversão para alunos | Não verifica automaticamente duplicatas |
| Dashboard | Indicadores reais SQLite e gráfico de frequência | Sem séries gráficas de receitas |
| Alertas | Vencidos, a vencer, aniversários, baixa frequência | Não há marcação lido/não lido |
| Exportação | CSV de alunos, PDF gerencial, JSON de dados | **Não** restaura JSON ainda; arquivo não criptografado |
| Auditoria | Log local de cadastros/pagamentos/alterações | Não há usuário associado ao evento |

## Não pronto para produção

- Login real, sessão, autorização por função, backend SQL/Postgres, sincronização e proteção dos dados em trânsito/repouso.
- Testes em dispositivo físico Apple, signing e TestFlight.
- Políticas completas de LGPD, consentimento, backup restaurável e recuperação de desastres.

## Verificações mínimas antes de qualquer piloto com dados reais

1. `bash scripts/preparar_ios_no_mac.sh` no macOS e resolver possíveis erros de análise, dependências ou projeto Xcode.
2. Criar três alunos fictícios, dois planos e duas turmas; editar status/plano e verificar persistência após fechar/reabrir app.
3. Criar mensalidade, tentar repetir competência, registrar pagamento parcial e pagar saldo, conferir caixa e recibo PDF.
4. Registrar faltas e presenças em dois dias e conferir o histórico por aluno e o gráfico.
5. Cadastrar luvas e uniformes, vender item, checar saldo financeiro e redução do estoque; testar quantidade maior que estoque.
6. Cadastrar interessado, converter uma vez e verificar o aluno gerado; revisar possíveis duplicidades.
7. Testar expiração, nascimento no mês, alerta de baixa frequência e backup exportado.
8. Validar proteção do dispositivo, proteção da base local, autenticação e restauração antes de registrar alunos reais.
9. Testar distribuição via TestFlight do proprietário.

O projeto foi escrito para iOS, mas **ainda não foi compilado ou testado num iPhone**. As verificações do banco via Python não validam a interface ou plugins Flutter.

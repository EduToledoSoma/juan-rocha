# Juan Rocha Boxe 1.1.0 — Recorrências e atualização segura

## Novidade
No módulo **Financeiro → Gerenciar recorrências mensais**, clique **Nova recorrência**.
Escolha **Mensalidade de aluno** ou **Despesa fixa**, informe descrição, valor, dia
(1 a 31), mês inicial e, opcionalmente, mês final. Para mensalidades, selecione
um aluno ativo. A recorrência pode ser pausada e reativada.

- Mensalidades são geradas como **pendentes**, sem simular pagamento.
- Despesas são lançadas no caixa **na data de vencimento**, nunca antes.
- Lançamentos anteriores não são apagados quando a regra é pausada.
- O processamento ocorre quando o app é iniciado e também ao salvar,
  reativar ou clicar em **Verificar e gerar pendências**. O aplicativo não
  executa tarefas em segundo plano quando está fechado.
- O dia 29/30/31 é ajustado para o último dia dos meses mais curtos.
- Uma mensalidade já existente daquele aluno/mês é preservada (não substituída).
- São processados no máximo 120 meses por regra para evitar varreduras infinitas.

## Compatibilidade e segurança do banco

**Muito importante:** Feche o aplicativo antes de atualizar. Faça um backup
independente da pasta de dados antes de distribuir para produção.

A versão anterior usa `juan_rocha_boxe.sqlite` e esquema SQLite versão 1.
A atualização usa versão 2 e cria apenas uma tabela nova `recurring_rules`.
Nenhuma tabela ou coluna existente é excluída; IDs, alunos, planos, pagamentos,
financeiro, presença, CRM e estoque permanecem inalterados.

O próprio aplicativo salva um snapshot do SQLite existente (incluindo -wal/-shm
caso existam) em `JuanRochaBoxe/databases/backups/antes_da_atualizacao_*`
antes de migrar. Se não conseguir fazer o backup, a migração é interrompida.
A cópia não substitui um backup externo testado. NÃO apague dados em AppData
ou na pasta de suporte do Linux ao atualizar.

A pasta Windows/Linux do banco continua sendo calculada por `path_provider`,
como na versão anterior. Não renomeie o identificador do aplicativo no Windows,
nem mude a pasta dos dados.

### Linux (computador que já tem o app)

1. Extraia este projeto em uma pasta separada; não apague a instalação atual.
2. Feche o aplicativo.
3. No terminal, dentro da pasta do projeto novo:

```bash
bash scripts/atualizar_linux.sh
```

O script gera o executável e atualiza o atalho existente com a mesma logo.
Seus dados ficam fora da pasta de instalação e não são apagados pelo script.

### Windows (para pessoa sem conhecimento técnico)

1. Você executa o workflow `Gerar instalador Windows - Juan Rocha Boxe` no GitHub Actions.
2. Baixe o artefato do GitHub; extraia `Juan_Rocha_Boxe_Setup.exe`.
3. Envie à pessoa um link de download (Google Drive ou outro meio confiável).
4. A pessoa **fecha o app**, baixa o Setup e executa. O instalador detecta a
   instalação anterior pelo `AppId` **inalterado** e atualiza na mesma pasta.
5. O instalador não exclui o banco em AppData, que é separado do programa.

**Alerta SmartScreen:** Não se pode garantir a ausência de avisos de segurança
em um `.exe` sem assinatura de código reconhecida. Para reduzir avisos e
estabelecer autenticidade, assine o instalador com certificado de assinatura
de código de uma autoridade confiável, proteja a chave e construa reputação.
Mesmo um executável assinado pode ser questionado pelo Windows.

### Nota sobre vários computadores

Banco local **não sincroniza** entre o Linux e o Windows. Atualizar um computador
não importa alunos do outro. Os dados já existentes em cada um permanecem.

### Condições de entrega

Este ZIP contém o código-fonte atualizado, **não executáveis já compilados**.
Os testes finais devem cobrir upgrade com uma cópia de dados reais anonimizada,
registro de pagamento, recorrência com 31 de fevereiro, duplicidade, pausa e
reabertura depois da instalação. Nunca experimente primeiro no único banco de
produção sem backup.

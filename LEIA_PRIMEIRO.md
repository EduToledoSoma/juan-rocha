# Juan Rocha Boxe — JR Boxe Gestão (iOS)

## O que este ZIP contém

Projeto **Flutter/Dart com destino iOS** (código-fonte, interface, banco local SQLite, testes, logo original do CT, gerador de ícone e roteiro de publicação). **Não contém APK, IPA assinado ou aplicativo instalado.**

A imagem original foi preservada em `assets/brand/logo_original.jpg` e utilizada na interface. Uma cópia convertida para PNG em 1024×1024 é usada apenas para gerar o ícone do iPhone.

## Funcionalidades implementadas no código

- **Alunos:** cadastro, edição, pesquisa, filtros, vínculo com plano/turma, data de nascimento, aniversário, telefone, emergência e observações.
- **Planos:** criar/editar, valor, modalidade, duração, aulas por semana e ativação.
- **Turmas/agenda:** turmas com professor, dias, horários, lotação declarada e situação.
- **Presenças:** check-in presente, falta e justificativa, por aluno e dia; histórico na ficha e indicadores por mês.
- **Mensalidades:** criação por competência, vencimento, desconto, garantia de unicidade aluno/mês, pagamento parcial ou total, status calculado, recibo PDF; valores recebidos alimentam o caixa.
- **Caixa:** receitas/despesas manuais e entradas automáticas vindas de pagamentos e vendas.
- **Produtos:** uniformes/luvas, estoque, venda com redução de quantidade e lançamento financeiro.
- **CRM:** contatos, funil de atendimento, acompanhamento e conversão de interessado em aluno.
- **Painel:** estudantes ativos, inadimplência, valores do dia/mês, despesas, presenças, aniversariantes e evolução da frequência.
- **Avisos internos:** aniversários, vencimentos e baixa frequência calculada a partir dos registros.
- **Relatórios:** resumo PDF, exportação CSV de alunos, exportação JSON dos dados; auditoria de operações.

**Atenção: todos os dados ficam apenas no dispositivo.** Esta primeira entrega é uma versão funcional de base local para testes, **não é uma aplicação de produção com múltiplos funcionários**.

## Funcionalidades do escopo original ainda NÃO implementadas

- Backend hospedado, sincronização em nuvem e autenticação de usuários por perfil (administrador/recepção/professor), com proteção por políticas servidoras.
- Criptografia do banco de dados no aparelho, política completa LGPD, exclusão/portabilidade automatizadas e recuperação/controle de sessões.
- Restauração de backup, conflitos e consistência de dados entre aparelhos.
- Geração recorrente automática de mensalidades, estornos, descontos com autorização e conciliação bancária.
- Controle estrito de capacidade da turma, prevenção de conflitos de horários e recorrência real de sessões.
- Check-in ligado a aulas agendadas individualmente, taxa de frequência prevista vs. realizada e notificações push.
- Foto do aluno, responsáveis e documentos com controles de permissão refinados.
- Status lido/não lido dos alertas, relatório avançado de inadimplência e gráficos de séries financeiras.
- Testes completos no Xcode e validação de App Store.

**Não use dados pessoais reais dos alunos nesta versão sem implementar controles de acesso, proteção de dados e recuperação de backup.** O backup JSON exportado não é criptografado e ainda não possui restauração automática no app.

## Como compilar exclusivamente para iOS (precisa de um Mac)

O usuário pode escrever Flutter em qualquer sistema operacional, mas a compilação de um app iOS exige **macOS + Xcode** ou serviço de compilação macOS. Android Studio em Linux não gera IPA; iPhones não instalam APK.

1. No **Mac**, instalar Flutter SDK (com `flutter` no PATH), Xcode e ferramentas de linha de comando. No terminal, executar `flutter doctor`.
2. Copiar/extrair este ZIP para uma pasta no Mac e abrir um Terminal nela.
3. Executar:

```bash
bash scripts/preparar_ios_no_mac.sh
```

Este script cria a pasta `ios/` pelo template oficial Flutter (somente iOS), resolve dependências, gera o ícone do app com sua logo, executa `flutter analyze` e os testes Dart.

4. Abrir `ios/Runner.xcworkspace` no Xcode, selecionar **Runner > Signing & Capabilities**, habilitar **Automatically manage signing**, escolher o **Team** da conta Apple Developer que fará a distribuição, e conferir o Bundle Identifier (`br.juanrochaboxe.juanRochaBoxe`, ou outro exclusivo aprovado).
5. Confirmar versão mínima do iOS, dispositivos de destino e testar em um iPhone real. Corrigir eventuais erros de build e comportamento antes da publicação.
6. No Terminal do Mac, dentro do projeto:

```bash
flutter pub get
flutter test
flutter analyze
flutter build ipa --release
```

7. O IPA assinado, quando a configuração de assinatura estiver correta, ficará em `build/ios/ipa/`.

## Como enviar ao dono do CT no iPhone

**Recomendação: TestFlight**, porque o proprietário instala pelo app TestFlight, com convite, sem precisar mexer em arquivos IPA.

1. Usar a conta Apple Developer pertencente ao titular do projeto/CT ou à organização responsável.
2. Criar identificador do aplicativo e registro no App Store Connect.
3. No Xcode Organizer, escolher `Distribute App > TestFlight & App Store` ou enviar via Transporter o IPA assinado.
4. Depois que o build for processado, abrir `App Store Connect > TestFlight`, adicionar o proprietário como testador (interno se for membro da equipe, externo se não for).
5. O proprietário instala o **TestFlight** da App Store, aceita o convite e instala o Juan Rocha Boxe.

Um IPA exportado **não** instala livremente por WhatsApp, Telegram ou AirDrop sem assinatura/distribuição válida pela Apple.

### Sem Mac próprio

Você pode usar um serviço de build de iOS que ofereça máquina macOS, assinatura com sua conta Apple e publicação no TestFlight. Não há comando no Linux/Android Studio que converta APK em IPA. Não compartilhe senhas ou certificados da conta Apple em mensagens.

## Arquivos importantes

- `lib/main.dart` — inicialização do Flutter, SQLite e tema.
- `lib/core/db.dart` — schema SQLite local e chaves estrangeiras.
- `lib/core/repository.dart` — regras transacionais de pagamentos, frequência e vendas.
- `lib/ui/` — as telas do aplicativo.
- `assets/brand/` — logo original e imagem do ícone.
- `test/utils_test.dart` — testes Flutter/Dart (para executar no Mac).
- `scripts/validar_schema.py` — valida as constraints SQL sem usar Flutter.
- `docs/ESCOPO_E_TESTES.md` — checklist detalhado e limitações.

## Validação realizada durante a geração

- O arquivo SQLite foi gerado em memória via Python executando as 15 declarações SQL do código Dart, testando restrições de duplicidade de competência, duplicidade de lançamento, duplicidade de frequência e estoque não negativo.
- **Não foi possível executar `flutter analyze`, `flutter test` ou `flutter build ipa` neste ambiente**: não há SDK Flutter nem macOS/Xcode. Por isso não há promessa de compilação aprovada ou de aplicativo pronto para produção.

## Opção para quem SÓ tem Linux: verificar compilação iOS no GitHub

O arquivo `.github/workflows/verificar-ios.yml` permite rodar **a análise, testes Dart e build iOS sem assinatura em uma máquina macOS do GitHub Actions**, mesmo que você use somente Linux.

1. Crie um repositório GitHub (prefira privado) e envie o conteúdo desta pasta para a raiz do repositório, inclusive a pasta `.github/`.
2. Abra **Actions > Verificar aplicativo iOS > Run workflow**.
3. Examine o resultado das etapas. Se falhar, envie os erros do log (remova qualquer informação privada).
4. **Esse teste não produz um IPA instalável**; o build assinado e a distribuição no TestFlight ainda precisam ser configurados em macOS (local ou nuvem) com a conta Apple Developer.

O GitHub pode cobrar uso de minutos de execução, principalmente para repositórios privados.

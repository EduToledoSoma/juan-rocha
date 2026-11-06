# JUAN ROCHA BOXE — Linux e Windows

Este projeto Flutter mantém a identidade preta e dourada e os recursos de cadastro, planos, turmas,
frequência, mensalidades, financeiro, produtos, CRM, alertas e relatórios da versão móvel.
É um **projeto-fonte pronto para gerar aplicativos desktop**, e não um executável compilado.

## Correções desta edição

- Eliminado o erro `setState() callback argument returned a Future` em todos os formulários.
- Cartões do dashboard com altura fixa, cores preto/dourado, títulos claros e tamanhos adaptáveis.
- Cada cartão é clicável e abre a área correspondente: alunos, mensalidades, financeiro ou check-in.
- Menu lateral nos desktops (>= 900 px) e navegação inferior em telas pequenas.
- Banco SQLite adaptado para Linux e Windows por `sqflite_common_ffi`.
- Exportação JSON/CSV/PDF salva em `Documentos/JuanRochaBoxe/Exportacoes` no desktop.
- O sistema não presume que um computador seja um iPhone.
- Fundo Android de inicialização com XML válido.

## Linux (Debian 13 / Ubuntu)

Você precisa do Flutter no PATH e dos pacotes do desktop Linux:

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsqlite3-0 libsqlite3-dev
flutter doctor -v
```

Dentro da pasta extraída, execute:

```bash
bash scripts/compilar_linux.sh
```

Para abrir depois do build:

```bash
./build/linux/x64/release/bundle/juan_rocha_boxe
```

**Distribuição:** compartilhe a pasta `build/linux/x64/release/bundle/` completa, com os arquivos `.so` e `data/`.
O computador de destino pode precisar das bibliotecas GTK e SQLite disponíveis.

## Windows 10/11

No **próprio Windows**, instale Flutter, Visual Studio 2022 com workload **Desktop development with C++**
e execute no PowerShell, na pasta extraída:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/compilar_windows.ps1
```

O executável e DLLs estarão em `build\windows\x64\runner\Release\`.
**Envie a pasta inteira**, não apenas o `.exe`.

## Gerar os dois automaticamente pelo GitHub

Envie o projeto ao seu repositório e abra `Actions → Gerar aplicativo desktop - Linux e Windows → Run workflow`.
Ao terminar, baixe os artefatos `JuanRochaBoxe-Linux` e `JuanRochaBoxe-Windows`.
Cada artefato contém a pasta da versão executável do respectivo sistema.

## Informações importantes

- O banco de cada instalação é **local** e independente. Dados do Poco não aparecem no desktop automaticamente.
- Nenhuma autenticação multiusuário ou sincronização remota foi incluída.
- O arquivo de backup JSON é exportável mas a função de restauração ainda não está implementada.
- Não use dados pessoais/financeiros reais de alunos para produção sem autenticação, proteção e backup/restore.
- A versão desktop precisa ser compilada e testada em Linux e Windows; não foi possível executar Flutter neste ambiente.

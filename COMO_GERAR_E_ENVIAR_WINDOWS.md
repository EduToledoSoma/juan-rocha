# Juan Rocha Boxe — instalador Windows com clique duplo

Esta pasta traz **somente os arquivos para gerar o instalador**. O `Setup.exe` sera gerado pelo GitHub Actions numa maquina Windows. O projeto Flutter final deve ser a **versao Desktop corrigida** (Linux/Windows), e nao o primeiro ZIP iOS.

## No Linux (desenvolvedor)

1. Tenha estas pastas:
   - `~/Projetos/Juan_Rocha_Boxe_Desktop/` (projeto desktop corrigido que ja funciona no Linux)
   - `~/Projetos/Juan_Rocha_Boxe_iOS_Flutter/` (checkout Git associado ao GitHub `EduToledoSoma/juan-rocha`)
2. Copie o codigo desktop corrigido ao checkout Git; **nao copie a pasta `.git`**, nem arquivos compilados/temporarios. Pode usar:

```bash
cd ~/Projetos/Juan_Rocha_Boxe_iOS_Flutter
rsync -a --exclude='.git/' --exclude='.dart_tool/' --exclude='build/' --exclude='.idea/'   ~/Projetos/Juan_Rocha_Boxe_Desktop/ ./
```

3. Extraia o arquivo `Juan_Rocha_Boxe_Instalador_Windows_Config.zip` na pasta do checkout Git:

```bash
unzip -o ~/Downloads/Juan_Rocha_Boxe_Instalador_Windows_Config.zip -d .
```

4. Envie as alteracoes:

```bash
git add -A
git commit -m "Prepare Windows installer for Juan Rocha Boxe"
GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_pessoal -o IdentitiesOnly=yes" git push origin main
```

5. Abra https://github.com/EduToledoSoma/juan-rocha/actions
   - Workflow: **Gerar instalador Windows - Juan Rocha Boxe**
   - Clique em `Run workflow` na branch `main`.
   - Quando ficar verde, abra a execucao e `Artifacts`.
   - Baixe **Juan-Rocha-Boxe-Instalador-Windows**; extrai o ZIP do GitHub; dentro esta `Juan_Rocha_Boxe_Setup.exe`.
   - Envie esse **EXE** como documento no WhatsApp ou via Google Drive/OneDrive.

## No Windows (destinatario)

- Baixe `Juan_Rocha_Boxe_Setup.exe`.
- Clique duas vezes e siga o assistente de instalacao.
- Um icone **Juan Rocha Boxe** sera criado no Menu Iniciar e na area de trabalho.
- Da proxima vez, abra com um clique. **Nao precisa Flutter, Android Studio, PowerShell ou Git.**

## Atenção

- Os dados do Windows sao locais e **nao sincronizam** com os dados do Linux/celular.
- Ainda nao ha autenticacao e restauracao de backup adequadas para operar com dados pessoais e financeiros reais do CT.
- Instalador nao assinado: Windows pode mostrar um aviso do SmartScreen; nao recomende ignorar avisos sem verificar procedencia. Para distribuir profissionalmente, assine digitalmente o EXE.
- Pode ser necessario Visual C++ Redistributable x64 caso o Windows nao tenha o runtime C++ necessario.
- Este pacote NAO inclui o executavel compilado: ate executar o workflow, nao existe um `Setup.exe` pronto.

# Juan Rocha Boxe — projeto para Android Studio (Flutter)

Este ZIP contém a **versão Android** do mesmo aplicativo Flutter usado no projeto iOS: mesmas telas, identidade preto/dourado, logo do CT, alunos, planos, agenda, frequência, financeiro, produtos, alertas e CRM.

**Abra a pasta principal `Juan_Rocha_Boxe_Android_Studio` no Android Studio.** Não abra apenas `android/` no primeiro uso: trata-se de um aplicativo **Flutter**, não de um projeto Kotlin puro.

## Requisitos uma única vez no Linux

- Android Studio com Android SDK e JDK 17 configurados.
- Plugins **Flutter** e **Dart** instalados em Settings > Plugins.
- **Flutter SDK instalado** e caminho configurado no Android Studio. Os plugins não instalam necessariamente o SDK. Guia: https://docs.flutter.dev/install e https://docs.flutter.dev/platform-integration/android/setup.

> Se o terminal mostrar `flutter: comando não encontrado`, ainda falta instalar/configurar o SDK. Não significa que o ZIP esteja com defeito.

## Abrir e gerar APK

1. Extraia o ZIP em `~/Projetos/`.
2. Android Studio > **Open** > selecione `~/Projetos/Juan_Rocha_Boxe_Android_Studio` (pasta que contém `pubspec.yaml`).
3. Informe o caminho do Flutter SDK se for solicitado e aguarde o `flutter pub get` / indexação.
4. Conecte o Poco X7 Pro com depuração USB ou use emulador e pressione **Run** para testar.
5. No menu **Build > Flutter > Build APK** (em algumas versões, `Build > Build Flutter APK`).
6. O arquivo deve surgir em `build/app/outputs/flutter-apk/app-release.apk` (ou `app-debug.apk` se gerar no modo de depuração).

### Alternativa no terminal do Android Studio

```bash
flutter doctor
flutter pub get
flutter build apk --debug
```

Resultado: `build/app/outputs/flutter-apk/app-debug.apk`.

## Identidade e dados

- Nome: **Juan Rocha Boxe**.
- Application ID Android: `br.juanrochaboxe.gestao`.
- Ícone e logo originais, sem redesenho.
- Banco local SQLite, no armazenamento privado do app.

## Limitações e cuidados

- A conversão de plataforma preserva o código Flutter, mas **não cria um app nativo Kotlin/Compose**.
- Não foi possível compilar/testar com Flutter/SDK Android neste ambiente; valide no seu Android Studio e no Poco.
- Projeto em **fase de testes**, sem contas multiusuário, autenticação ou sincronização segura; não use dados reais de alunos/finanças neste APK.
- A configuração `release` usa uma **chave de depuração só para instalação local**. Antes de distribuir/publicar, crie assinatura de produção e valide segurança e backups.
- Não desinstale o app com registros que deseja preservar; desinstalar normalmente elimina o SQLite local.
- Se houver falha no Gradle Wrapper, execute `flutter create --platforms=android --org br.juanrochaboxe .` na pasta do projeto para gerar os arquivos oficiais de suporte Gradle; isto mantém os arquivos em `lib/` e a identidade gráfica, mas pode regenerar os arquivos em `android/`, então revise o `applicationId` e o ícone antes de compilar.

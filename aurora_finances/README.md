# Aurora Finances

App Flutter para controle financeiro pessoal com autenticacao (Email/Senha, Google e Microsoft) e persistencia no Cloud Firestore por usuario.

## Objetivos do app
- Centralizar receitas, despesas e contas em um unico painel.
- Facilitar o controle mensal com categorias, subcategorias e lancamentos.
- Ajudar a visualizar saldo atual, saldo mensal e tendencia futura.
- Permitir importar faturas de cartao com OCR para agilizar o cadastro.

## Funcionalidades principais
- Login/registro por email e senha
- Login social com Google e Microsoft
- Dashboard com resumo de receitas, despesas, saldo e previsoes
- Cadastro de receitas e despesas
- Reordenacao de categorias e subcategorias por arraste
- Importacao de fatura (PDF) com OCR e sugestao de lancamentos
- Carteira/contas bancarias e categorias personalizadas
- Preferencias de tema, moeda e formato de data por usuario

## Resumo completo das funcionalidades
- Autenticacao: email/senha, Google e Microsoft.
- Dashboard: saldo atual, saldo mensal, variacao e previsao para meses futuros.
- Receitas: salario e extras com total por mes.
- Despesas: categorias e subcategorias com dois modos:
  - Subcategoria fixa: valor mensal direto.
  - Subcategoria detalhada: lista de lancamentos por data.
- Lancamentos detalhados: categoria, motivo, valor, data e parcelas.
- Parcelas: gera lancamentos futuros e mantem referencia da compra.
- Importacao de fatura: OCR local + parser, suporte a PDF com senha.
- Categorias globais: lista de categorias para lancamentos detalhados.
- Carteira: contas e saldo consolidado.
- Preferencias: tema, tipografia, moeda e formato de data.
- Configuracoes: reset de dados do usuario e exclusao de conta.

## Uso (fluxo sugerido)
1) Crie sua conta e entre no app.
2) Cadastre receitas e ajuste seu salario do mes.
3) Crie categorias e subcategorias de despesas:
   - Use subcategoria fixa para gastos recorrentes.
   - Use subcategoria detalhada para gastos variaveis.
4) Lance despesas do mes ou importe a fatura do cartao.
5) Acompanhe o resumo no dashboard e a previsao futura.
6) Ajuste categorias, cores e formatos nas configuracoes.

## Requisitos
- Flutter SDK instalado
- Android Studio ou JDK instalado (para build Android)
- Conta no Firebase
- (Opcional) Conta Microsoft Azure para login Microsoft
- Dispositivo/emulador Android com Google Play Services

## Configuracao do Flutter
1) Instale o Flutter: https://docs.flutter.dev/get-started/install
2) Verifique o ambiente:
```bash
flutter doctor
```

## Configuracao do Firebase (Android)
### 1) Criar projeto
- Firebase Console: https://console.firebase.google.com
- Crie um projeto (ex.: aurora-finances)

### 2) Registrar app Android
- Android package name: `com.auroratechadvisors.aurora_finances`
- Baixe o `google-services.json`
- Coloque em `android/app/google-services.json`

### 3) FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Isso gera `lib/firebase_options.dart` e `firebase.json`.

### 4) Plugins do Google Services (ja configurado)
- `android/build.gradle.kts` com:
```kotlin
plugins {
  id("com.google.gms.google-services") version "4.4.4" apply false
}
```
- `android/app/build.gradle.kts` com:
```kotlin
plugins {
  id("com.google.gms.google-services")
}
```

## Firebase Auth
No Firebase Console -> Authentication -> Sign-in method:
- Ative Email/Password
- Ative Google
- Ative Microsoft (precisa Azure)

## Microsoft (Azure) - resumo
1) Azure Portal -> App registrations -> New registration
2) Copie `Application (client) ID`
3) Crie `Client Secret` em Certificates & secrets
4) Cole Client ID e Secret no Firebase (Auth -> Microsoft)

## Google Sign-In (Android)
- Confirme o SHA-1 do debug e do release no Firebase.
- Baixe novamente o `google-services.json` apos adicionar o SHA-1.

## Firestore
1) Firebase Console -> Firestore Database -> Create database
2) Regras (production):
```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## SHA-1 (Google Sign-In / Microsoft)
Para APK debug, adicione o SHA-1 do debug keystore no Firebase:
```powershell
& "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin\keytool.exe" `
  -list -v -alias androiddebugkey `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android -keypass android
```
Depois baixe um novo `google-services.json`.

## Executar
```bash
flutter pub get
flutter run
```

## Gerar APK
```bash
flutter build apk
```

## Fluxo de dados
- Auth cria o usuario e o app grava dados em `users/{uid}/...`.
- Cada usuario acessa apenas seus documentos via Rules.
- Configuracoes de tema, moeda e rotulos ficam em `settings`.

## Estrutura dos dados (Firestore)
```
users/{uid}/settings/data
users/{uid}/receitas/data
users/{uid}/despesas/data
users/{uid}/carteira/data
users/{uid}/categories/data
```

## Importacao de fatura (PDF)
- A importacao usa OCR local (ML Kit) e parsing do texto.
- PDFs com senha sao suportados (sera solicitada na tela).
- Faturas variam muito: revise os lancamentos sugeridos antes de salvar.

## Organizacao de despesas
- As despesas sao organizadas em categorias e subcategorias.
- No layout de uma coluna (mobile), a ordem pode ser ajustada por arraste.

## Remocao de dados
- Em Configuracoes: apagar dados do usuario ou excluir a conta.
- Excluir conta remove os dados do Firestore vinculados ao UID.

## Plataformas
- Android: configurado.
- iOS/macOS/web/windows: registrados no Firebase, mas nao configurados no app.

## Observacoes
- O app so acessa dados do usuario logado.
- Se o Firestore retornar permission-denied, revise as Rules.

## Troubleshooting
- Login Google falha com `ApiException: 10`:
  - Verifique se o `applicationId` no Firebase e no app sao iguais.
  - Adicione o SHA-1 correto (debug ou release) no Firebase e baixe novo `google-services.json`.
- Firestore com `permission-denied`:
  - Regras nao aplicadas ou usuario nao autenticado.
  - Reaplique as Rules e confirme que o app esta logado.
- Firestore `unavailable`:
  - API do Firestore nao habilitada ou propagacao pendente.
  - Habilite a API no console e aguarde alguns minutos.

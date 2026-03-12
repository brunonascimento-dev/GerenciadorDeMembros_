# Gerenciador de Membros

Projeto Flutter para gestao de membros.

## Firebase API keys

As API keys de cliente Firebase nao ficam mais hardcoded no codigo versionado.
Use um arquivo local com `--dart-define-from-file`.

1. Crie `firebase_keys.json` a partir do template `firebase_keys.example.json`.
2. Preencha os valores reais de:
	- `FIREBASE_ANDROID_API_KEY`
	- `FIREBASE_IOS_API_KEY`
3. Execute o app com:

```bash
flutter run --dart-define-from-file=firebase_keys.json
```

4. Build de producao:

```bash
flutter build apk --dart-define-from-file=firebase_keys.json
flutter build ios --dart-define-from-file=firebase_keys.json
```

`firebase_keys.json` esta no `.gitignore` e nao deve ser commitado.

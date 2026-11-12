# Export Android (APK de debug) e Web — passo a passo

Preset `Android` já existe em `export_presets.cfg` (arm64-v8a, GL Compatibility, sem Gradle, `com.vksgames.thelastkeeper`). O que falta é só o ambiente. Estado desta máquina: Android SDK (`~/Android/Sdk`, com platform-tools, build-tools 35/36, NDK 28), JDK 17 e `debug.keystore` já existem.

## Por que o export falhou pelo snap

O `godot-4` do snap é a build **.NET (mono)** 4.7.2 e roda com a home do snap (`~/snap/godot-4/40`), que não vê `~/.config/godot`, `~/.local/share/godot` nem `/tmp`. Consequências: o Web é recusado (Godot não exporta Web com a build C#), e o Android não acha templates, JDK nem SDK.

## Passos

1. Use uma build **sem .NET** da mesma versão dos templates. Os templates instalados são `4.7.2.stable` (em `~/.local/share/godot/export_templates/`, já com `android_*.apk` e `web_*.zip`), mas o binário sem .NET disponível é o `~/Godot_v4.7.1-stable_linux.x86_64`. Baixe o Godot 4.7.2 padrão (não .NET) de godotengine.org, ou instale os templates 4.7.1 (Editor > Gerenciar Modelos de Exportação).
2. Em Editor > Configurações do Editor > Exportar > Android, confira (já constam em `~/.config/godot/editor_settings-4.7.tres`):
   - Java SDK Path: `/usr/lib/jvm/java-17-openjdk-amd64`
   - Android SDK Path: `/home/kauevictor30/Android/Sdk`
   - Debug Keystore: `~/.local/share/godot/keystores/debug.keystore`, usuário `androiddebugkey`, senha `android`
3. Exporte:
   ```bash
   mkdir -p ~/export_tmp/android ~/export_tmp/web
   godot --headless --path . --export-debug "Android" ~/export_tmp/android/tlk-debug.apk
   godot --headless --path . --export-release "Web" ~/export_tmp/web/index.html
   (cd ~/export_tmp/web && zip -r ../web.zip .)   # index.html na raiz do zip
   ```
4. Instale e meça: `adb install -r tlk-debug.apk` (depuração USB ligada); FPS na tela do jogo; anote o número como linha de base.

## Credenciais fora do git

A keystore de **debug** é a padrão do Godot (senha pública `android`), então não há segredo no repositório. Para uma keystore de **release** (5.7), não grave usuário/senha em `export_presets.cfg`: o editor guarda em `.godot/export_credentials.cfg`, que o `.gitignore` já ignora (`.godot/`). Faça backup da keystore de release fora do repo.

## Observações

- `build/` está no `.gitignore`; exporte para fora do repo.
- Web: single-thread (`thread_support=false`), então não exige cabeçalhos COOP/COEP.
- Windows exporta pelo snap sem problemas (ver que o destino precisa estar sob `~/snap/godot-4/common/` ou outra pasta visível ao snap).

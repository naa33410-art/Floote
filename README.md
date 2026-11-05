# Electro Scanner

Primeira versão Android em Flutter com três módulos experimentais:

- Detector acústico: captura o microfone e mede nível RMS do áudio.
- Detector magnético: exibe os eixos e a magnitude do magnetômetro.
- Radar Bluetooth BLE: lista anúncios BLE recebidos, nome/identificador disponível e RSSI.

## Limitações importantes

Este app é uma ferramenta auxiliar de inspeção. Encontrar Bluetooth, som ou alteração magnética não confirma a presença de um rastreador. O RSSI não fornece distância precisa. O telefone não detecta diretamente sinais GPS, celulares ou toda a radiofrequência. Alguns rastreadores não anunciam BLE continuamente ou usam identificadores rotativos.

## Gerar APK pelo GitHub

1. Crie um repositório chamado `electro-scanner` no GitHub.
2. Envie todos os arquivos e pastas deste projeto para a raiz do repositório.
3. Abra a aba **Actions**.
4. Se necessário, habilite GitHub Actions.
5. Execute **Build Android APK** com **Run workflow** ou aguarde o build automático após o push.
6. Abra a execução concluída e baixe o artefato `electro-scanner-apk`.

O APK não está incluído neste pacote; ele será produzido pelo workflow.

## Próximas melhorias

- FFT e espectrograma para análise de frequências acústicas.
- Histórico e comparação de leituras BLE por sessão.
- Interface de inspeção guiada por áreas do veículo.
- Revisão das permissões BLE conforme a versão Android e política de distribuição.

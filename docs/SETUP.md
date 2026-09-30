# Configuração do Cormex Work

Este repositório contém apenas o frontend Flutter Web/PWA. O Cloud Code oficial está em [BancoWorckk](https://github.com/Tdk17/BancoWorckk), no diretório `cloud/feature/`. Siga o `docs/SETUP.md` daquele repositório para compilar `cloud/main.js`, publicar no Back4App, configurar Redis, CLP, índices, segmentos e planos. Não publique o antigo `cloud/src` do frontend.

Em **Settings → Secrets and variables → Actions → Variables** deste repositório, defina `PARSE_SERVER_URL`, `PARSE_APPLICATION_ID`, `PARSE_CLIENT_KEY` se utilizada, `TERMS_VERSION`, `PRIVACY_VERSION`, `TERMS_URL` e `PRIVACY_URL`. Os documentos precisam estar publicados; as versões no Back4App devem coincidir. Estas variáveis entram no JavaScript público: nunca use Master Key ou credenciais Redis. Execute o workflow **Publicar GitHub Pages** novamente após alterá-las.

A API do IBGE é consumida pelo navegador para selecionar UF e cidade. As listas não são persistidas no Parse; somente a cidade, UF e código do município escolhidos pelo cliente são salvos em sua conta. A localização automática pelo dispositivo ainda não está ativada.

Valide primeiro em QA: cadastro e login, cidade, reserva com recurso, ordem de serviço/decisão do cliente, notificações e financeiro. O CI do frontend compila o Flutter e prepara o PWA; o CI e os testes da API ficam no BancoWorckk. O Pages sozinho não instala o Cloud Code no Back4App.

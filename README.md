# Cormex Work

Plataforma SaaS multiempresa para agendamento e operação de serviços. Código independente de Malta Wash/AutoHost. Frontend Flutter Web e API Parse Cloud Code para Back4App.

## Estado desta entrega

O fluxo do cliente começa em conta autenticada: `/client` reúne categorias e reservas; busca, perfil do profissional e agendamento exigem login. A área da empresa mantém serviços, horários, reservas e painel. O aplicativo não apresenta registros fictícios. Falhas de API aparecem como erro.

O frontend pode ser publicado no GitHub Pages. A existência das chaves do Parse no build não confirma que as funções Cloud Code estão ativas nem que cadastro e reservas passam de ponta a ponta. A branch de desenvolvimento integra a seleção de cidade por UF no IBGE, ordens de serviço e lançamentos financeiros. O backend correspondente fica em [BancoWorckk](https://github.com/Tdk17/BancoWorckk). Veja a [arquitetura do produto](docs/PRODUCT_ARCHITECTURE.md).

## Estrutura

- lib/: Flutter Web responsivo, get_it, go_router e signals.
- BancoWorckk/cloud/feature/: fonte única das funções Parse; BancoWorckk/cloud/main.js é o arquivo gerado para o Back4App.
- docs/SETUP.md: configuração separada de Back4App, Redis, planos, CLPs e build.
- docs/API.md: funções implementadas e contratos.
- .github/workflows/ci.yml: análise e build Flutter. A validação da API ocorre no BancoWorckk.
- .github/workflows/pages.yml: build Flutter e publicação no GitHub Pages após push em main.

## GitHub Pages

Em **Settings → Pages → Build and deployment → Source**, selecione **GitHub Actions**. O fluxo `Publicar GitHub Pages` compila com base `/Cormex_Work/` e publica em https://tdk17.github.io/Cormex_Work/. Também pode ser iniciado manualmente em Actions.

Quando o novo backend estiver pronto, configure no repositório em **Settings → Secrets and variables → Actions → Variables**: `PARSE_SERVER_URL`, `PARSE_APPLICATION_ID`, `TERMS_VERSION`, `PRIVACY_VERSION`, `TERMS_URL` e `PRIVACY_URL`; `PARSE_CLIENT_KEY` é opcional. Rode o fluxo novamente. Essas variáveis entram no JavaScript público: nunca use Master Key, credenciais Redis ou chaves privadas. A hospedagem de Pages cobre apenas o frontend; a API Parse precisa operar separadamente.

## Desenvolvimento

Flutter SDK estável:

    flutter pub get && flutter analyze && flutter build web --release

O build exige dados **públicos** do novo app Parse, versões e URLs dos documentos jurídicos:

    flutter build web --release \
      --dart-define=PARSE_SERVER_URL=https://SEU-PARSE-SERVER/parse \
      --dart-define=PARSE_APPLICATION_ID=SEU_APP_ID \
      --dart-define=TERMS_VERSION=VERSAO_PUBLICADA \
      --dart-define=PRIVACY_VERSION=VERSAO_PUBLICADA \
      --dart-define=TERMS_URL=https://SEU-DOMINIO/termos \
      --dart-define=PRIVACY_URL=https://SEU-DOMINIO/privacidade

Nunca passar Master Key ou credenciais Redis ao Flutter. A sessão web fica somente na memória; recarregar a página pede novo login.

## Licença

Licenciamento a definir pelo proprietário do projeto.

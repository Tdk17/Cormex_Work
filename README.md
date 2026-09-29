# Cormex Work

Plataforma SaaS multiempresa para agendamento e operação de serviços. Código independente de Malta Wash/AutoHost. Frontend Flutter Web e API Parse Cloud Code para Back4App.

## Estado desta entrega

Primeira fatia funcional: área pública, cadastro e login, criação de empresa, seleção de plano com avaliação configurada no servidor, perfil público, serviços, horários, recursos no backend, disponibilidade, reserva idempotente, transições e painel. O aplicativo não apresenta registros fictícios. Falhas de API aparecem como erro.

O frontend pode ser publicado no GitHub Pages. Sem o novo Back4App configurado, a página inicial abre, mas cadastro, busca e agendamentos aguardam ativação. Equipe e convites, remarcação, relatórios completos, notificações, console da plataforma, exportação LGPD e cobrança com provedor ainda não estão implementados. Veja [escopo e próximos passos](docs/STATUS.md).

## Estrutura

- lib/: Flutter Web responsivo, get_it, go_router e signals.
- cloud/: Cloud Functions Parse, validação, papéis, isolamento, rate limit e lock distribuído Redis.
- cloud/config/segments.json: definições iniciais reais de lavação, oficina e beleza.
- docs/SETUP.md: configuração separada de Back4App, Redis, planos, CLPs e build.
- docs/API.md: funções implementadas e contratos.
- .github/workflows/ci.yml: análise Flutter e testes do Cloud Code.
- .github/workflows/pages.yml: build Flutter e publicação no GitHub Pages após push em main.

## GitHub Pages

Em **Settings → Pages → Build and deployment → Source**, selecione **GitHub Actions**. O fluxo `Publicar GitHub Pages` compila com base `/Cormex_Work/` e publica em https://tdk17.github.io/Cormex_Work/. Também pode ser iniciado manualmente em Actions.

Quando o novo backend estiver pronto, configure no repositório em **Settings → Secrets and variables → Actions → Variables**: `PARSE_SERVER_URL`, `PARSE_APPLICATION_ID`, `TERMS_VERSION`, `PRIVACY_VERSION`, `TERMS_URL` e `PRIVACY_URL`; `PARSE_CLIENT_KEY` é opcional. Rode o fluxo novamente. Essas variáveis entram no JavaScript público: nunca use Master Key, credenciais Redis ou chaves privadas. A hospedagem de Pages cobre apenas o frontend; a API Parse precisa operar separadamente.

## Desenvolvimento

Flutter SDK estável e Node 18+:

    cd cloud && npm ci && npm test && npm run check
    cd .. && flutter pub get && flutter analyze

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

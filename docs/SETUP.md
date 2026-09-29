# Configuração do novo ambiente Cormex Work

## 1. Separação

Crie aplicativos Parse separados para desenvolvimento, QA e produção. Não use o app ou banco do Malta Wash, CRM ou Easy. O repositório público não deve conter chaves privilegiadas.

## 2. Cloud Code

Use Node 18+ e envie o conteúdo da pasta cloud/ ao ambiente Cloud Code do aplicativo, mantendo main.js, src/ e package.json juntos. Configure o ponto de entrada como main.js. As dependências ioredis e luxon devem estar instaladas pelo ambiente. Valide que v1-segments-list responde no console antes de abrir a aplicação web.

Variáveis **somente no servidor**:

| Variável | Finalidade |
| --- | --- |
| REDIS_URL | Redis com TLS e persistência operacional; locks e rate limit. Sem conexão, gravações protegidas falham |
| TERMS_VERSION / PRIVACY_VERSION | Versões publicadas dos documentos |
| REQUIRE_EMAIL_VERIFICATION | true após configurar o provedor de e-mail do Parse |

Back4App permite dependências pelo package.json na pasta Cloud Code; confirme suporte do plano/ambiente a conexão externa Redis antes do deploy. Guia oficial: https://help.back4app.com/hc/en-us/articles/360002038772-How-to-install-an-NPM-module-at-Back4App

## 3. Classes, CLPs e índices

Configure CLP para Workspace, Membership, SegmentDefinition, Plan, Subscription, Service, BusinessHours, Resource, CustomerProfile, Booking, ConsentRecord e AuditEvent: negar find, get, create, update e delete a público e usuário comum; somente Master Key/Cloud Code. _User mantém autenticação Parse, mas desabilite listagem pública e revisão de campos. Não confie apenas na ACL dos objetos.

Índices obrigatórios no banco Parse/Mongo, criados pelo administrador do ambiente antes de tráfego real:

- Workspace.slug: único;
- Workspace.onboardingKey: único;
- Membership._p_workspace + _p_user: único;
- Subscription._p_workspace para busca;
- Service._p_workspace + active;
- Booking.idempotencyScope: único;
- Booking._p_workspace + status + startAtUTC;
- Booking._p_workspace + blockedUntilUTC;
- BusinessHours._p_workspace + weekday: único;
- SegmentDefinition.code + version e Plan.code + version: únicos.

Teste os nomes concretos dos campos pointer (_p_workspace, _p_user) no seu Parse. Se o painel Back4App não permitir criar índices únicos, faça a criação pela administração autorizada do Mongo ou não libere reservas ao público. Um lock Redis sem validação de corrida em QA não é evidência suficiente para produção.

## 4. Segmentos e planos

Os três segmentos iniciais constam em cloud/config/segments.json. O script de bootstrap é executado por operador com Master Key **somente na máquina segura/CI protegido**:

    PARSE_SERVER_URL=https://NOVO_APP/parse \
    PARSE_APPLICATION_ID=APP_ID \
    PARSE_MASTER_KEY=MASTER_KEY \
    node cloud/scripts/bootstrap.js

Planos não têm preço fictício. Depois de definir preços e limites reais, escreva um JSON privado com array de planos contendo code, name, version, amount em centavos, currency: "BRL", billingInterval: "monthly" ou "yearly", trialDays, segmentCodes, limits: {"services": N, "resources": N} e capabilities. Execute o mesmo comando com PLANS_CONFIG_PATH=/caminho/privado/planos.json. Não comite preços provisórios. Alteração de preço exige nova versão e análise do impacto em assinantes.

## 5. Frontend

Passe ao build somente URL HTTPS e identificadores públicos. Busca e login requerem PARSE_SERVER_URL e PARSE_APPLICATION_ID. Defina também TERMS_VERSION, PRIVACY_VERSION, TERMS_URL e PRIVACY_URL com documentos publicados; o cadastro fica desabilitado sem eles. A Client Key, se usada, não é segredo privilegiado. Nunca inclua Master Key, REST API Key privilegiada ou REDIS_URL no bundle.

O ambiente Flutter não tenta acessar um backend genérico por fallback. Sem configuração válida, só a página inicial informativa fica acessível; funções que usam API mostram um aviso de indisponibilidade. Para Pages, selecione GitHub Actions em Settings → Pages, cadastre as variáveis públicas descritas no README e execute `Publicar GitHub Pages`. Mantenha domínios/CORS restritos ao host escolhido. Verifique cada deep link no host.

O frontend usa somente cabeçalhos Parse autorizados pelo preflight do Back4App. Depois de publicar, abra a busca no GitHub Pages e confirme que `v1-segments-list` e `v1-discovery-search` respondem; variáveis no build não instalam o Cloud Code no Back4App.

O PWA usa manifesto, ícones e um service worker com versão gerada após o build por `python3 scripts/prepare_pwa.py build/web` (a workflow de Pages já executa isso). Ele armazena apenas arquivos estáticos do próprio site para abertura offline. Reservas, login e resultados da API exigem rede e nunca são armazenados pelo service worker.

## 6. Validação e rollback

Em QA, rode o fluxo completo: conta → workspace → plano real com trial → horário → serviço → reserva → cancelamento. Faça tentativas simultâneas para o mesmo horário com usuários diferentes, repetição da idempotency key, acesso cruzado a workspaces, sessão revogada, limite de plano e expiração do trial. Teste backup e restauração da base.

Rollback do Flutter: publicar o build anterior. Rollback do Cloud Code: restaurar a versão anterior do diretório Cloud. Não apague dados em rollback; mudanças de schema e índices precisam de migração compatível e plano próprio. Faça snapshot antes da primeira publicação.

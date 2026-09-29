# API Parse Cloud Code v1

Base: POST na rota /functions/v1-{nome} do PARSE_SERVER_URL com X-Parse-Application-Id, Content-Type: application/json e, quando autenticado, X-Parse-Session-Token. O corpo JSON contém parâmetros diretamente. O transporte Parse envolve a resposta em result.

Sucesso: {"result":{"ok":true,"data":{},"meta":{"requestId":"..."}}}.
Erro: {"result":{"ok":false,"error":{"code":"...","message":"...","fieldErrors":{},"requestId":"..."}}}.
O frontend trata ambos e não confirma gravação antes de ok: true.

| Função | Autorização | Entrada principal |
| --- | --- | --- |
| auth-register | Pública, rate limit | name, email, password, acceptTerms, termsVersion, privacyVersion |
| auth-login | Pública, rate limit | email, password |
| auth-password-reset-request | Pública, rate limit | email |
| auth-me / auth-logout | Sessão | sem parâmetros |
| segments-list / plans-list | Pública | segmentCode opcional em plans-list |
| workspaces-create | Sessão, lock | name, slug, segmentCode, timezone, city, state, idempotencyKey |
| workspaces-get / workspaces-update | Membership; update owner/admin | workspaceId e campos editáveis |
| subscription-select-trial / subscription-status | Owner / membership | workspaceId, planCode, acceptedVersion |
| services-list / create / update / archive | Membership; escrita permitida e plano ativo | workspaceId, serviceId e campos do serviço |
| business-hours-get / update | Membership; escrita permitida e plano ativo | workspaceId, days[1..7] |
| resources-list / create | Membership; escrita permitida e plano ativo | workspaceId, name, type |
| customers-list / create | Papel com clientes:write | workspaceId, name, email/phone |
| discovery-search | Pública, rate limit | segmentCode/city/limit/cursor |
| workspaces-public-profile | Pública | slug |
| availability-search | Pública, perfil ativo | workspaceId, serviceId, resourceId opcional, day YYYY-MM-DD |
| bookings-create | Sessão, plano ativo, lock | workspaceId, serviceId, startAt ISO com fuso, idempotencyKey; customerId opcional para equipe |
| bookings-list | Membership ou cliente titular | workspaceId, limit/cursor |
| bookings-mine | Sessão do cliente | sem parâmetros |
| bookings-transition | Equipe autorizada ou cliente cancelando a própria | workspaceId, bookingId, status |
| dashboard-summary | Membership | workspaceId, day opcional |

## Exemplos de fluxo

1. segments-list → auth-register → auth-login → workspaces-create → plans-list → subscription-select-trial.
2. business-hours-update → services-create → workspaces-update com publicProfileEnabled: true.
3. discovery-search → workspaces-public-profile → availability-search → login cliente → bookings-create → bookings-list.

O backend ignora preço/duração enviados na reserva e registra snapshots do serviço. Todas as consultas operacionais fixam o workspace no servidor. idempotencyKey é reutilizada apenas para repetir a mesma solicitação.

## Classes criadas pela execução

_User, ConsentRecord, Workspace, Membership, SegmentDefinition, Plan, Subscription, Service, BusinessHours, Resource, CustomerProfile, Booking, AuditEvent. A criação de schema/índices e CLPs é etapa administrativa, descrita em SETUP.

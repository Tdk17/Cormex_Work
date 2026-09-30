# API do Cormex Work

O contrato completo e as instruções de implantação estão em [BancoWorckk/docs/API.md](https://github.com/Tdk17/BancoWorckk/blob/main/docs/API.md). A evolução dos endpoints de cliente, agenda, oficina e financeiro está no PR correspondente do BancoWorckk até o merge.

O frontend chama `POST {PARSE_SERVER_URL}/functions/v1-{nome}` com App ID público e sessão quando necessário. Verifica `result.ok` antes de considerar uma ação concluída. Não acessa classes Parse diretamente e não guarda uma cópia do Cloud Code neste repositório.

Fluxo do cliente: `auth-register/login` → `auth-me` → `customer-profile-update` → `segments-list` → `discovery-search` → `workspaces-public-profile` → `availability-options/search` → `bookings-create/mine` → `service-orders-list/get/estimate-decision` → `notifications-list/mark-read`.

Fluxo da empresa: `workspaces-create/get/update` → `business-hours-get/update` → `services-*` → `resources-*` → `bookings-list/transition` → `service-orders-create/inspection-upsert/estimate-submit/status-update` → `finance-entries-create/list/settle` → `finance-summary`.

# Cormex Work — fluxo e arquitetura acordados

Este documento define o fluxo do produto. O Work é a plataforma de agendamento e gestão de atendimentos por segmento; o CormeX Easy continua sendo o catálogo aberto e amplo de serviços. O Work usa Flutter Web/PWA com get_it, go_router e signals; Parse Cloud Code no Back4App com funções v1-*, validação e autorização no servidor. O código fonte do backend implantável fica em `BancoWorckk/cloud/feature/`, com `cloud/main.js` autossuficiente gerado a partir dessas features para o editor Back4App.

## Fluxo do cliente

1. A página institucional oferece entrada/cadastro. Busca, perfil do profissional, horários e agendamento exigem conta autenticada.
2. O primeiro destino após login é `/client`, com cidade, categorias retornadas por `v1-segments-list` e próximos atendimentos de `v1-bookings-mine`. A cidade é dado de perfil e pode ser corrigida. Localização automática deve pedir permissão explícita, converter coordenadas em cidade por serviço definido e permitir edição; não se deve inferir cidade a partir de IP nem mostrar cidade inventada.
3. A categoria abre `/find?segment=...&city=...`; `v1-discovery-search` devolve somente empresas ativas naquela categoria/cidade. O cliente abre `/business/:slug`, escolhe serviço e disponibilidade em `/book/...`, confirma a reserva pela API e acompanha em `/my-bookings`.
4. Cada agendamento deve mostrar empresa, endereço/local, serviço, horário com fuso, situação e histórico. A data deve ser formatada no fuso do atendimento. Avisos de pronto, alterações ou cancelamento geram evento e notificação persistida.
5. Um cliente não precisa criar empresa. Uma mesma conta pode ser cliente e membro de empresa; a troca de área não modifica a identidade.

## Fluxo da empresa

1. Após login, o responsável cria sua empresa uma única vez em `/onboarding`; `v1-workspaces-create` é idempotente e cria a associação owner. Os membros gerenciam a empresa em `/app/...` conforme papel.
2. A empresa configura segmento, endereço, equipe/recursos, calendário, pausas, feriados, serviços, duração, preço e planos/pacotes que realmente vende. O servidor calcula disponibilidade e bloqueia dupla reserva. Lavação e salão configuram horários próprios, com capacidade por recurso/profissional.
3. A agenda gera atendimento. A empresa confirma, inicia, conclui ou cancela com transições autorizadas. Um serviço de oficina pode abrir ordem de serviço ligada a cliente, veículo e agendamento.
4. Painel financeiro usa lançamentos reais vinculados a ordem, serviço e recebimento; separa previsto de recebido e dá visão por período. Pagamento presencial não é prova automática de recebimento. Cobrança da assinatura do SaaS é domínio separado.

## Especialização por segmento

| Segmento | Dados e operação específicos | Visível ao cliente |
| --- | --- | --- |
| Oficina mecânica | Veículo, vistoria, itens verificados, defeitos, serviços, peças, orçamento, aprovação e evolução da ordem de serviço | Diagnóstico, orçamento, aprovação, peças pendentes, progresso e liberação para retirada |
| Lavação | Serviços, pacotes, duração, boxes, expediente e exceções | Serviços disponíveis, horários, estado do atendimento e veículo pronto |
| Salão | Procedimentos, profissionais, duração, pacotes e expediente individual | Profissional, horário, procedimento e conclusão |

O núcleo de autenticação, empresa, agenda, clientes, notificações, permissões e financeiro é comum. Cada segmento acrescenta recursos e campos próprios por versão de configuração; não se espalham condicionais por todas as telas.

## Contratos que ainda precisam ser implementados

- `v1-customer-profile-get/update`: sessão do titular; cidade/UF e preferências, com validação e consentimento para localização. A resposta de `v1-auth-me` pode incluir somente o resumo necessário.
- `v1-bookings-mine` e `v1-bookings-list`: incluir nome e endereço da empresa, fuso, situação e eventos relevantes sem permitir ler reservas alheias.
- `v1-service-orders-create/get/list/update`: membro autorizado cria OS para booking/veículo do mesmo workspace; cliente titular vê a projeção pública da própria OS. IDs de workspace, booking e cliente são conferidos no servidor.
- `v1-service-orders-inspection-upsert`: itens verificados e achados; manter autor, horário e trilha imutável de alterações relevantes.
- `v1-service-orders-estimate-submit/decision`: itens, valores e validade; cliente titular aprova/rejeita versão específica, sem confundir agendamento com autorização de reparo. Mudanças de valor exigem nova versão e aprovação.
- `v1-service-orders-status-update`: estados `opened`, `inspection`, `awaiting_approval`, `awaiting_parts`, `in_service`, `ready_for_pickup`, `delivered`, `canceled`; transições limitadas por papel, evento e notificação ao cliente.
- `v1-business-services-*`, `v1-business-hours-*`, `v1-resources-*`, `v1-packages-*`: configuração pela empresa, isolamento por workspace e disponibilidade recalculada. Não expor pacotes antes do contrato existir.
- `v1-finance-entries-*`, `v1-finance-summary`: valores em centavos, moeda, origem, competência, vencimento, pagamento confirmado e estornos; acesso somente de owner/admin/financeiro; relatórios do cliente não expõem dados da empresa.
- `v1-notifications-list/read`: eventos persistentes de reserva, OS e conclusão; push é canal adicional, nunca a única fonte de verdade.

## Portões de aceitação

- Uma pessoa sem sessão não consulta `/find`, `/business/...` ou `/book/...`; após login retorna ao destino solicitado. Um novo cliente acessa `/client` sem ser forçado a criar empresa.
- Cadastro cria conta real e sessão. Não publicar um botão desabilitado por variáveis legais vazias sem informar precisamente a configuração faltante. Back4App deve carregar as funções e responder com os contratos reais.
- Uma empresa de cada segmento configura o próprio horário; outro workspace não lê nem altera seus dados. Reservas concorrentes disputando o mesmo horário geram somente uma confirmação.
- Cliente vê local e horário corretos, OS e notificações apenas dos próprios atendimentos; aprovar orçamento é uma operação autenticada e auditada.
- Flutter analyze/build web, testes do Cloud Code, verificação visual mobile/desktop e fluxo de ponta a ponta em app Parse de teste precisam passar antes de levar a main e publicar.

## Situação da implementação

A branch de realinhamento leva a busca e o agendamento para dentro da sessão e introduz `/client` com categorias e reservas usando as funções atuais. Cidade ainda é filtro manual; a API não fornece perfil de cidade nem geocodificação. A resposta atual de `bookings-mine` não traz nome/endereço da empresa. Ordem de serviço, pacotes comerciais, eventos/notificações e controle financeiro ainda não existem. Não declarar esses fluxos funcionais até o Cloud Code e a interface serem implementados e testados juntos.

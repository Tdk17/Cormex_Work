# Cormex Work — fluxo e arquitetura acordados

Este documento define o fluxo do produto. O Work é a plataforma de agendamento e gestão de atendimentos por segmento; o CormeX Easy continua sendo o catálogo aberto e amplo de serviços. O Work usa Flutter Web/PWA com get_it, go_router e signals; Parse Cloud Code no Back4App com funções v1-*, validação e autorização no servidor. O código fonte do backend implantável fica em `BancoWorckk/cloud/feature/`, com `cloud/main.js` autossuficiente gerado a partir dessas features para o editor Back4App.

## Fluxo do cliente

1. A página institucional oferece entrada/cadastro. Busca, perfil do profissional, horários e agendamento exigem conta autenticada.
2. O primeiro destino após login é `/client`, com cidade, categorias retornadas por `v1-segments-list` e próximos atendimentos de `v1-bookings-mine`. Estados e municípios vêm da API oficial de localidades do IBGE, carregados por UF e mantidos apenas em cache da sessão; a escolha do cliente é persistida em `v1-customer-profile-update`. Localização automática por coordenadas ainda depende de permissão explícita e serviço de geocodificação; não se deve inferir cidade do IP nem inventá-la.
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

## Contratos implementados na branch

- `v1-customer-profile-update` e `v1-auth-me` transportam cidade, UF e código de município. `v1-discovery-search` filtra por cidade e UF.
- `v1-bookings-mine/list` traz nome e endereço da empresa, cidade, UF e horário local. Empresas novas informam endereço ao cadastrar; existentes precisam preenchê-lo antes de ativar o perfil público.
- `v1-availability-options` lista recursos ativos para serviços que exigem box, cadeira ou baía; a reserva envia o recurso escolhido.
- `v1-service-orders-*` abre OS vinculada ao agendamento de oficina, registra vistoria, envia orçamento em centavos, recebe aprovação do cliente da versão exata e atualiza o status. Eventos de alteração geram notificação persistente.
- `v1-finance-entries-create/list/settle` e `v1-finance-summary` registram lançamentos manuais com acesso do proprietário. Receita prevista e recebida ficam separadas.

## Contratos e decisões ainda pendentes

- Geolocalização automática, endereço validado/CEP, histórico detalhado e imutável por item de vistoria, fotos, aprovação com validade, estornos e relatórios financeiros por competência.
- Pacotes/planos comerciais da empresa e configuração completa de equipe/recursos na interface; o backend já possui serviços, horário e recursos.
- Push e e-mail transacionais; a implementação presente garante apenas notificações dentro do app.
- Confirmar publicação do `cloud/main.js` no Back4App, versões e URLs jurídicas no Pages e no backend, Redis e dados iniciais de segmentos/planos antes do teste real de cadastro.

## Portões de aceitação

- Uma pessoa sem sessão não consulta `/find`, `/business/...` ou `/book/...`; após login retorna ao destino solicitado. Um novo cliente acessa `/client` sem ser forçado a criar empresa.
- Cadastro cria conta real e sessão. Não publicar um botão desabilitado por variáveis legais vazias sem informar precisamente a configuração faltante. Back4App deve carregar as funções e responder com os contratos reais.
- Uma empresa de cada segmento configura o próprio horário; outro workspace não lê nem altera seus dados. Reservas concorrentes disputando o mesmo horário geram somente uma confirmação.
- Cliente vê local e horário corretos, OS e notificações apenas dos próprios atendimentos; aprovar orçamento é uma operação autenticada e auditada.
- Flutter analyze/build web, testes do Cloud Code, verificação visual mobile/desktop e fluxo de ponta a ponta em app Parse de teste precisam passar antes de levar a main e publicar.

## Situação da implementação

A branch contém o código de localização, agendamentos, OS e financeiro. O teste real de ponta a ponta aguarda Cloud Code atualizado e cadastro funcional no app Back4App. O build isolado não comprova deploy nem operação em produção.

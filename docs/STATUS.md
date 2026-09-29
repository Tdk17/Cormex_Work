# Status técnico e limites

## Implementado

| Área | Entrega |
| --- | --- |
| Conta | Cadastro com aceite versionado, login, logout, recuperação neutra e consulta da sessão |
| Empresa | Onboarding idempotente, perfil privado/público, segmento definido no servidor |
| Assinatura | Catálogo de planos pela API e avaliação somente quando o plano publicado prevê dias de trial |
| Catálogo | Serviços persistidos, edição/arquivamento via API, recursos básicos e horários semanais |
| Agenda | Slots no fuso da empresa, conflito por recurso, reserva com lock e chave de idempotência, cancelamento/transição |
| Cliente | Perfil criado ao reservar, listagem de reservas próprias por API |
| Gestão | Dashboard diário, listagem de serviços e reservas, configuração do perfil e horários |
| Segurança | ACL vazia em registros operacionais, CLP externa obrigatória, validação estrita, rate limit Redis e RBAC no servidor |

## A construir antes da produção

1. Vincular e configurar um novo aplicativo Back4App e Redis; aplicar CLPs e índices. Sem isso, mutações com lock/rate limit falham de forma segura.
2. Definir planos reais, valores, limites, trial e regras de inadimplência. Integração de cobrança, webhooks assinados e portal exigem escolha de provedor.
3. Criar páginas e contratos jurídicos reais de Termos/Privacidade, política de retenção e canal LGPD. O cadastro web permanece desabilitado sem URLs.
4. Implementar convite de equipe, revogação de sessões, recursos na interface, cliente manual, remarcação, exceções/feriados, notificações/outbox, relatórios completos, console interno e exportação.
5. Criar testes de integração contra Parse/Redis em QA, inclusive corridas concorrentes de reservas e idempotência. Os testes atuais são unitários de regras.
6. Revisar acessibilidade, paginação de todas as listas, fusos e horário de verão, backups/restore, observabilidade e teste responsivo real.
7. Integrar GitHub Pages ou domínio dedicado apenas após ambiente QA funcional e configuração de produção.

## Política de produto desta versão

- Um workspace usa um segmento principal.
- Apenas planos com avaliação positiva podem iniciar acesso; não existe confirmação de pagamento sem provedor.
- Reservas confirmam automaticamente. A política de aprovação, cancelamento e no-show requer decisão comercial.
- Recursos têm capacidade 1; sem recurso definido, a agenda conservadoramente aceita uma reserva por vez.
- Backend usa lock distribuído por empresa e dia. Antes da produção é obrigatório validar conectividade Redis e índice único de idempotência em QA.
- Tela web mantém token de sessão em memória; o recarregamento solicita novo login.

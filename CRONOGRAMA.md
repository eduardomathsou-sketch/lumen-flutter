# Cronograma do projeto Lumen Store

Acompanhamento das 22 tarefas do cronograma oficial da disciplina, conferidas contra o código
dos dois repositórios:

- **App (Flutter):** este repositório, `lumen-flutter`.
- **API (FastAPI + PostgreSQL):** [Lumen-backend](https://github.com/eduardomathsou-sketch/Lumen-backend),
  branch [`evolucao-semestre`](https://github.com/eduardomathsou-sketch/Lumen-backend/tree/evolucao-semestre)
  ([Pull Request #1](https://github.com/eduardomathsou-sketch/Lumen-backend/pull/1)).

Atualizado em 10/11/2026.

**Legenda:** ✅ pronto no app e na API · 🟡 parcial (a coluna "Situação" diz o que falta) · ⏳ a fazer

## Resumo

| | Tarefas |
| --- | --- |
| ✅ Prontas | 12 de 22 |
| 🟡 Parciais | 9 de 22 |
| ⏳ A fazer | 1 de 22 |

Nas parciais, a regra de negócio já está pronta e testada na API; o que falta é a tela no app
ou uma conta externa (Mercado Pago, Melhor Envio).

## As 22 tarefas

| # | Tarefa | Est. | Situação | Onde está no código |
| --- | --- | --- | --- | --- |
| 1 | Criar estrutura inicial do projeto | P | ✅ App em pastas por assunto e API em camadas (rotas → services → repositories → models) | App: `lib/store`, `lib/account`, `lib/checkout`, `lib/admin` · API: `app/api`, `app/services`, `app/repositories`, `app/models` |
| 2 | Criar tela de Login | P | ✅ Login com erro claro, limite de tentativas e "Esqueci minha senha" | App: `lib/account/account_pages.dart` (`AuthPage`), `lib/account/password_pages.dart` · API: `POST /auth/login` |
| 3 | Configurar autenticação de usuário | M | ✅ Código de acesso (sessão) aleatório e revogável; o banco guarda só o hash. Senha com scrypt. Aparelhos conectados, sessão curta para a administração | App: `lib/account/account_controller.dart`, `lib/account/security_pages.dart` · API: `app/services/auth_service.py`, `app/core/security.py`, [ACCOUNTS.md](https://github.com/eduardomathsou-sketch/Lumen-backend/blob/evolucao-semestre/ACCOUNTS.md) |
| 4 | Criar tela de Cadastro | P | ✅ Cadastro com aceite dos Termos (obrigatório) e de novidades (opcional), como pede a LGPD | App: `AuthPage` em `lib/account/account_pages.dart`, `lib/account/legal_pages.dart` · API: `POST /auth/register`, `GET /legal` |
| 5 | Criar tela Home | M | ✅ Vitrine com banner da coleção, categorias e produtos vindos da API | App: `lib/main.dart`, `lib/store/collection_banner.dart` |
| 6 | Criar listagem de Produtos | M | ✅ Lista paginada por categoria, com carregamento, erro e nova tentativa | App: `CatalogPage` em `lib/store/store_pages.dart`, `lib/store/catalog_api.dart` · API: `GET /products`, `GET /categories` |
| 7 | Criar tela de Detalhes do Produto | P | 🟡 Detalhe com foto, preço, quantidade e favorito. **Falta no app:** escolher tamanho/cor e mostrar composição e cuidados (a API já entrega) | App: `ProductDetailPage` em `lib/store/store_pages.dart` · API: `GET /products/{id}`, `app/models/product_variant.py` |
| 8 | Criar busca de produtos | P | ✅ Busca por nome, protegida contra caracteres especiais | App: `CatalogPage` · API: `GET /products?search=` (`app/repositories/product_repository.py`) |
| 9 | Criar Carrinho de Compras | M | ✅ Sacola com quantidades, remoção e preço sempre calculado pelo servidor; a sacola de visitante passa para a conta no login | App: `BagPage` em `lib/checkout/checkout_pages.dart` · API: `app/services/cart_service.py` |
| 10 | Criar tela Minha Conta | P | 🟡 Perfil, favoritos, segurança (trocar senha, aparelhos) e sair. **Falta no app:** editar nome/telefone e a área de privacidade (baixar dados, excluir conta), que a API já tem | App: `ProfilePage` em `lib/account/account_pages.dart` · API: `app/api/v1/endpoints/users.py` |
| 11 | Criar cadastro/edição de endereço | P | 🟡 O endereço é preenchido e validado no checkout. **Falta no app:** a tela de endereços salvos (a API guarda até 10 por conta) | App: `CheckoutPage` · API: `/users/me/addresses`, `app/services/user_service.py` |
| 12 | Criar tela de Checkout | M | ✅ Endereço, CPF/CNPJ validado, frete, resumo e proteção contra pedido duplicado (`Idempotency-Key`) | App: `CheckoutPage` em `lib/checkout/checkout_pages.dart` · API: `app/services/order_service.py` |
| 13 | Integrar API de Pagamento | G | 🟡 PIX completo em modo de teste e integração com o Mercado Pago pronta (assinatura do aviso + reconsulta + conferência de valor). **Falta:** a conta de produção do Mercado Pago | API: `app/services/payment_service.py`, `app/services/mercado_pago_orders.py` · App: `OrderPage` |
| 14 | Integrar API de Frete/Envio | M | 🟡 Frete fixo funcionando e integração com o Melhor Envio pronta (PAC/SEDEX). **Falta:** o token do Melhor Envio | API: `app/services/shipping_service.py`, [SHIPPING.md](https://github.com/eduardomathsou-sketch/Lumen-backend/blob/evolucao-semestre/SHIPPING.md) · App: escolha de frete no `CheckoutPage` |
| 15 | Criar sistema de Cupons | M | 🟡 Pronto na API (percentual ou valor fixo, validade, limite de usos, proteção contra chute de código). **Falta no app:** o campo de cupom e a gestão no painel | API: `app/services/coupon_service.py`, `/admin/coupons` |
| 16 | Criar sistema de Avaliações | M | 🟡 Pronto na API (1 a 5 estrelas, só de quem recebeu o produto). **Falta no app:** mostrar e enviar avaliações | API: `app/services/review_service.py`, `/products/{id}/reviews` |
| 17 | Criar tela Meus Pedidos | M | 🟡 Lista e detalhe do pedido com retomada do PIX. **Falta no app:** status de entrega, rastreio e pedido de devolução (a API já tem) | App: `OrdersPage` e `OrderPage` em `lib/checkout/checkout_pages.dart` · API: `app/api/v1/endpoints/orders.py`, `app/services/return_service.py` |
| 18 | Criar confirmação de pedido | P | ✅ Tela do pedido com PIX copia-e-cola, atualização automática e e-mail de confirmação | App: `OrderPage` · API: `app/services/notification_service.py`, `app/services/email_templates.py` |
| 19 | Conectar aplicativo ao banco/API | G | 🟡 App ligado à API (teste de contrato roda a cada push) e banco PostgreSQL criado na Neon. **Falta:** concluir a publicação própria na Vercel | App: `lib/api_config.dart`, `test/backend_contract_test.dart` · API: `migrations/` (0001 a 0010) |
| 20 | Realizar testes básicos do aplicativo | M | ✅ 122 testes automáticos na API (SQLite e PostgreSQL) e 28 no app, executados pelo GitHub Actions a cada push | App: `test/`, `.github/workflows/app.yml` · API: `tests/`, `.github/workflows/` |
| 21 | Corrigir erros encontrados | M | ✅ Revisão de segurança feita e corrigida (lista abaixo); continua a cada entrega | Histórico de commits dos dois repositórios |
| 22 | Gerar versão Android para testes | P | ⏳ A pasta `android/` existe; falta gerar o APK de teste | `android/` |

## Plano por aula

A aula de 10/11 foi adiada; as entregas de 10/11 e 17/11 serão mostradas juntas.

| Aula | O que mostrar (tarefas do cronograma) |
| --- | --- |
| 17/11 | 1 a 8: estrutura, login, autenticação, cadastro, home, listagem, detalhes e busca |
| 24/11 | 9 a 11: carrinho, minha conta e endereços |
| 01/12 | 12, 13 e 18: checkout, pagamento e confirmação de pedido |
| 08/12 | 14 a 17: frete, cupons, avaliações e meus pedidos |
| 15/12 | 19 a 22: app ligado à API publicada, testes, correções e versão Android |

## Erros encontrados e corrigidos (tarefa 21)

| Problema | Correção |
| --- | --- |
| O aviso de pagamento do modo de teste aceitava um segredo padrão conhecido | Sem segredo configurado o aviso fica desligado; em produção o segredo precisa ter 32+ caracteres |
| O limite de tentativas por IP usava o IP do servidor intermediário | A API lê o IP real da cliente (`x-real-ip`) |
| Preço guardado como número com vírgula flutuante | Preço em centavos inteiros (migration 0006) |
| Bibliotecas com alertas de segurança | Atualizadas; `pip-audit` sem alertas |
| Era possível testar códigos de cupom sem limite | Códigos inexistentes são contados por IP e bloqueados |
| Um robô podia reservar o estoque criando pedidos sem pagar | Limite de pedidos por IP e de unidades de cada produto por pedido |
| O site podia ser embutido em outra página (clickjacking) | Cabeçalhos `X-Frame-Options` e `frame-ancestors` no site e na API |
| Um código de acesso roubado valia até vencer | Aparelhos conectados (ver e desconectar), sessão da administração de 12 horas e teto de sessões por conta |

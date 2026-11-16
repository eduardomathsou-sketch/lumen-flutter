# Cronograma do projeto Lumen Store

Acompanhamento das 22 tarefas do cronograma oficial da disciplina, conferidas contra o código
dos dois repositórios:

- **App (Flutter):** este repositório, `lumen-flutter`.
- **API (FastAPI + PostgreSQL):** [Lumen-backend](https://github.com/eduardomathsou-sketch/Lumen-backend),
  branch [`evolucao-semestre`](https://github.com/eduardomathsou-sketch/Lumen-backend/tree/evolucao-semestre)
  ([Pull Request #1](https://github.com/eduardomathsou-sketch/Lumen-backend/pull/1)).

Atualizado em 16/11/2026.

**Publicada:** loja em <https://lumen-store-omega.vercel.app> e API em
<https://lumen-api-wine.vercel.app>, com banco PostgreSQL na Neon (São Paulo), ligados pela
integração oficial Neon × Vercel.

**Legenda:** ✅ pronto no app e na API · 🟡 parcial (a coluna "Situação" diz o que falta) · ⏳ a fazer

## Resumo

| | Tarefas |
| --- | --- |
| ✅ Prontas | 20 de 22 |
| 🟡 Parciais | 2 de 22 |
| ⏳ A fazer | 0 de 22 |

As duas parciais já funcionam de ponta a ponta em modo de teste; o que falta é a conta
externa (Mercado Pago para o PIX de verdade e Melhor Envio para o frete calculado).

## As 22 tarefas

| # | Tarefa | Est. | Situação | Onde está no código |
| --- | --- | --- | --- | --- |
| 1 | Criar estrutura inicial do projeto | P | ✅ App em pastas por assunto e API em camadas (rotas → services → repositories → models) | App: `lib/store`, `lib/account`, `lib/checkout`, `lib/admin` · API: `app/api`, `app/services`, `app/repositories`, `app/models` |
| 2 | Criar tela de Login | P | ✅ Login com erro claro, limite de tentativas e "Esqueci minha senha" | App: `lib/account/account_pages.dart` (`AuthPage`), `lib/account/password_pages.dart` · API: `POST /auth/login` |
| 3 | Configurar autenticação de usuário | M | ✅ Código de acesso (sessão) aleatório e revogável; o banco guarda só o hash. Senha com scrypt. Aparelhos conectados, sessão curta para a administração | App: `lib/account/account_controller.dart`, `lib/account/security_pages.dart` · API: `app/services/auth_service.py`, `app/core/security.py`, [ACCOUNTS.md](https://github.com/eduardomathsou-sketch/Lumen-backend/blob/evolucao-semestre/ACCOUNTS.md) |
| 4 | Criar tela de Cadastro | P | ✅ Cadastro com aceite dos Termos (obrigatório) e de novidades (opcional), como pede a LGPD | App: `AuthPage` em `lib/account/account_pages.dart`, `lib/account/legal_pages.dart` · API: `POST /auth/register`, `GET /legal` |
| 5 | Criar tela Home | M | ✅ Visual claro (Montserrat + Bodoni, preto e dourado): banner em carrossel, faixa de confiança, vitrine "Escolhidos da semana" com selos e preço "de/por", menu lateral, barra inferior e rodapé. Funciona com letra grande no celular | App: `lib/main.dart`, `lib/lumen_theme.dart`, `lib/store/collection_banner.dart`, `lib/store/store_chrome.dart`, `lib/store/product_card.dart` |
| 6 | Criar listagem de Produtos | M | ✅ Lista paginada por categoria e ordenação (relevância, menor e maior preço, nome), com carregamento, erro e nova tentativa | App: `CatalogPage` em `lib/store/store_pages.dart`, `lib/store/catalog_api.dart` · API: `GET /products`, `GET /categories` |
| 7 | Criar tela de Detalhes do Produto | P | ✅ Foto, preço, escolha de tamanho e cor (esgotados bloqueados), estoque da variação, nota média, composição, cuidados e avaliações. No painel: cadastro de tamanhos, cores, composição, cuidados e envio da foto do computador (a API regrava sem a localização gravada pela câmera) | App: `ProductDetailPage` em `lib/store/store_pages.dart` · API: `GET /products/{id}`, `app/models/product_variant.py` |
| 8 | Criar busca de produtos | P | ✅ Busca por nome, protegida contra caracteres especiais | App: `CatalogPage` · API: `GET /products?search=` (`app/repositories/product_repository.py`) |
| 9 | Criar Carrinho de Compras | M | ✅ Sacola com quantidades, remoção e preço sempre calculado pelo servidor; a sacola de visitante passa para a conta no login | App: `BagPage` em `lib/checkout/checkout_pages.dart` · API: `app/services/cart_service.py` |
| 10 | Criar tela Minha Conta | P | ✅ Perfil, favoritos, Meus dados (nome e celular), segurança (trocar senha, aparelhos), Privacidade (novidades, baixar dados e excluir conta, com senha) e sair | App: `ProfilePage` em `lib/account/account_pages.dart`, `lib/account/privacy_pages.dart` · API: `app/api/v1/endpoints/users.py` |
| 11 | Criar cadastro/edição de endereço | P | ✅ Meus endereços (criar, editar, excluir, padrão; até 10) e escolha rápida no checkout, com o endereço padrão já preenchido | App: `lib/account/address_pages.dart`, `CheckoutPage` · API: `/users/me/addresses`, `app/services/user_service.py` |
| 12 | Criar tela de Checkout | M | ✅ Endereço, CPF/CNPJ validado, frete, resumo e proteção contra pedido duplicado (`Idempotency-Key`) | App: `CheckoutPage` em `lib/checkout/checkout_pages.dart` · API: `app/services/order_service.py` |
| 13 | Integrar API de Pagamento | G | 🟡 PIX completo em modo de teste (a administração confirma o PIX de teste pelo painel) e integração com o Mercado Pago pronta (assinatura do aviso + reconsulta + conferência de valor). Página guiada para ligar o PIX real pronta. **Falta:** colar a chave de produção do Mercado Pago na Vercel | API: `app/services/payment_service.py`, `app/services/mercado_pago_orders.py` · App: `OrderPage` |
| 14 | Integrar API de Frete/Envio | M | 🟡 Frete fixo funcionando e integração com o Melhor Envio pronta (PAC/SEDEX). **Falta:** o token do Melhor Envio | API: `app/services/shipping_service.py`, [SHIPPING.md](https://github.com/eduardomathsou-sketch/Lumen-backend/blob/evolucao-semestre/SHIPPING.md) · App: escolha de frete no `CheckoutPage` |
| 15 | Criar sistema de Cupons | M | ✅ Campo de cupom no checkout (validado pela API, desconto no total) e gestão no painel (percentual ou valor fixo, compra mínima, validade, limite de usos, pausa). Proteção contra chute de código | App: `CheckoutPage`, `lib/admin/admin_coupons.dart` · API: `app/services/coupon_service.py`, `/admin/coupons` |
| 16 | Criar sistema de Avaliações | M | ✅ Avaliações na página da peça e botão "Avaliar" no pedido entregue (1 a 5 estrelas e comentário). Só quem recebeu avalia; aparece só o primeiro nome | App: `lib/store/reviews.dart` · API: `app/services/review_service.py`, `/products/{id}/reviews` |
| 17 | Criar tela Meus Pedidos | M | ✅ Lista com etapa e data; detalhe com retomada do PIX, linha do tempo da entrega, rastreio e pedido de devolução (7 dias arrependimento, 90 defeito). No painel: pedidos da loja, envio e entrega | App: `OrdersPage`/`OrderPage`, `lib/checkout/order_delivery.dart`, `lib/admin/admin_orders.dart` · API: `app/api/v1/endpoints/orders.py`, `app/services/return_service.py` |
| 18 | Criar confirmação de pedido | P | ✅ Tela do pedido com PIX copia-e-cola, atualização automática e e-mail de confirmação | App: `OrderPage` · API: `app/services/notification_service.py`, `app/services/email_templates.py` |
| 19 | Conectar aplicativo ao banco/API | G | ✅ Loja e API publicadas na Vercel (região São Paulo), banco PostgreSQL na Neon ligado pela integração oficial (nenhuma senha digitada à mão) e catálogo carregado. O teste de contrato liga o app à API a cada push | App: `lib/api_config.dart`, `test/backend_contract_test.dart` · API: `migrations/` (0001 a 0012) |
| 20 | Realizar testes básicos do aplicativo | M | ✅ 136 testes automáticos na API (SQLite e PostgreSQL) e 66 no app, executados pelo GitHub Actions a cada push | App: `test/`, `.github/workflows/app.yml` · API: `tests/`, `.github/workflows/` |
| 21 | Corrigir erros encontrados | M | ✅ Revisão de segurança feita e corrigida (lista abaixo); continua a cada entrega | Histórico de commits dos dois repositórios |
| 22 | Gerar versão Android para testes | P | ✅ O GitHub Actions gera o APK de teste a cada push, já apontando para a API publicada, com o ícone da Lumen (baixar em Actions → run → Artifacts) | `android/`, job `android` em `.github/workflows/app.yml` |

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
| A cópia dos dados pessoais ia direto para a área de transferência (outros apps podem ler) | A cópia aparece na tela e copiar vira uma escolha, com aviso para limpar depois |
| Salvar um produto pelo painel apagava a composição e os cuidados (o painel não mandava esses campos) | Na edição, a API mantém os campos que não vieram; o painel agora edita composição, cuidados, tamanhos e cores |
| A vitrine anunciava frete grátis com 2 peças, mas o frete fixo cobrava mesmo assim | Cotação e pedido zeram o frete a partir de 2 peças também no frete fixo |
| No checkout, um CPF inválido fora da tela passava sem aviso do app (o formulário só conferia os campos visíveis) | Formulários longos mantêm todos os campos montados e validam tudo antes de enviar |
| A foto do banner tinha 1,9 MB e deixava a loja lenta no celular | Banner em JPEG otimizado (125 KB), mesma qualidade visível |
| Com a letra do celular aumentada, o topo e a barra inferior estouravam a tela | A marca não cresce com a letra (como um logotipo) e a barra limita o crescimento do texto |
| O painel só aceitava link de foto, e fotos de celular carregam a localização GPS | Envio direto do computador: a foto é reduzida no navegador e a API regrava em JPEG sem metadados, com limite de tamanho e de pixels |

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumen_store/account/account_controller.dart';
import 'package:lumen_store/account/account_pages.dart';
import 'package:lumen_store/account/address_pages.dart';
import 'package:lumen_store/account/legal_pages.dart';
import 'package:lumen_store/account/privacy_pages.dart';
import 'package:lumen_store/account/security_pages.dart';
import 'package:lumen_store/checkout/commerce_api.dart';

import 'checkout_test.dart' show MemoryStorage, cartJson;

const password = 'Minha frase segura 123!';
const validCode = 'codigo-valido-com-mais-de-20';

http.Response reply(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// API de mentira com as rotas de conta usadas pelas telas.
class FakeAccountApi {
  Json? registered;
  String? resetEmail;
  bool passwordChanged = false;
  bool deleted = false;
  final List<Json> addresses = [];
  Json? profile;
  List<Json> devices = [
    {
      'id': 'atual-0001',
      'device': 'Chrome · Windows',
      'current': true,
      'last_used_at': '2026-11-09T20:00:00Z',
    },
    {
      'id': 'outro-0002',
      'device': 'Safari · iPhone',
      'current': false,
      'last_used_at': '2026-11-08T12:30:00',
    },
  ];

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    final body = request.body.isEmpty ? <String, dynamic>{} : jsonDecode(request.body) as Json;
    if (path.endsWith('/cart')) {
      return reply({'token': 'guest-token', 'cart': cartJson()}, 201);
    }
    if (path.endsWith('/auth/register')) {
      registered = body;
      return reply({
        'access_token': 'account-token',
        'user': {'id': 1, 'email': body['email'], 'terms_current': true},
      }, 201);
    }
    if (path.endsWith('/auth/me')) {
      return reply({'id': 1, 'email': 'cliente@example.com'});
    }
    if (path.endsWith('/favorites')) return reply([]);
    if (path.endsWith('/legal/terms')) {
      return reply({
        'slug': 'terms',
        'title': 'Termos de Uso',
        'version': '2026-11',
        'content':
            '# Termos de Uso da Lumen\n\n## 1. Quem somos\n\nTexto do parágrafo.\n\n'
            '- Item de lista\n\n| Dado | Para quê |\n|---|---|\n| E-mail | Criar a conta |\n',
      });
    }
    if (path.endsWith('/auth/password-reset')) {
      resetEmail = body['email'] as String;
      return reply({'detail': 'Se houver uma conta com este e-mail, enviamos as instruções.'}, 202);
    }
    if (path.endsWith('/auth/password-reset/confirm')) {
      return body['token'] == validCode && body['new_password'] == 'Outra frase segura 456!'
          ? http.Response('', 204)
          : reply({'detail': 'Este link de nova senha é inválido ou expirou. Peça um novo.'}, 422);
    }
    if (path.endsWith('/auth/sessions')) return reply(devices);
    if (path.contains('/auth/sessions/') && request.method == 'DELETE') {
      devices = devices.where((d) => d['id'] != path.split('/').last).toList();
      return http.Response('', 204);
    }
    if (path.endsWith('/auth/logout-others')) {
      devices = devices.where((d) => d['current'] == true).toList();
      return http.Response('', 204);
    }
    if (path.endsWith('/users/me/password')) {
      if (body['current_password'] != password) {
        return reply({'detail': 'Senha atual incorreta.'}, 401);
      }
      passwordChanged = true;
      return http.Response('', 204);
    }
    if (path.endsWith('/users/me') && request.method == 'PUT') {
      profile = body;
      return reply({'id': 1, 'email': 'cliente@example.com', ...body});
    }
    if (path.endsWith('/users/me/consents')) {
      return reply({'id': 1, 'email': 'cliente@example.com', 'marketing_opt_in': body['marketing_opt_in']});
    }
    if (path.endsWith('/users/me/data-export')) {
      return body['password'] == password
          ? reply({'account': {'email': 'cliente@example.com'}, 'orders': []})
          : reply({'detail': 'Senha incorreta.'}, 401);
    }
    if (path.endsWith('/users/me/delete')) {
      if (body['password'] != password) return reply({'detail': 'Senha incorreta.'}, 401);
      deleted = true;
      return http.Response('', 204);
    }
    if (path.endsWith('/users/me/addresses') && request.method == 'GET') {
      return reply(addresses);
    }
    if (path.endsWith('/users/me/addresses') && request.method == 'POST') {
      final saved = {'id': addresses.length + 1, ...body};
      addresses.add(saved);
      return reply(saved, 201);
    }
    final addressMatch = RegExp(r'/users/me/addresses/(\d+)$').firstMatch(path);
    if (addressMatch != null && request.method == 'DELETE') {
      addresses.removeWhere((a) => '${a['id']}' == addressMatch.group(1));
      return http.Response('', 204);
    }
    return reply({'detail': 'Rota inesperada: $path'}, 404);
  }

  AccountController controller({bool signedIn = false}) => AccountController(
    CommerceApi(
      client: MockClient(handle),
      baseUrl: 'https://api.example.com/api/v1',
      storage: MemoryStorage(),
      accountStorage: MemoryStorage()..value = signedIn ? 'account-token' : null,
    ),
    favoritesStorage: MemoryStorage(),
  );
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('register is only sent after the terms are accepted', (
    tester,
  ) async {
    phone(tester);
    final api = FakeAccountApi();
    final account = api.controller();
    addTearDown(account.dispose);
    await tester.pumpWidget(
      MaterialApp(home: AuthPage(account: account, register: true)),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'cliente@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('auth-password')), password);
    await tester.enterText(find.byKey(const ValueKey('auth-confirm')), password);
    tester.testTextInput.hide();
    await reveal(tester, find.text('CADASTRAR'));
    await tester.tap(find.text('CADASTRAR'));
    await tester.pumpAndSettle();
    expect(api.registered, isNull);
    expect(find.byKey(const ValueKey('auth-terms-error')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('auth-terms')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-terms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-terms-error')), findsNothing);
    await reveal(tester, find.text('CADASTRAR'));
    await tester.tap(find.text('CADASTRAR'));
    await tester.pumpAndSettle();
    expect(api.registered, {
      'email': 'cliente@example.com',
      'password': password,
      'accept_terms': true,
      'marketing_opt_in': false,
    });
    expect(account.user!['email'], 'cliente@example.com');
  });

  testWidgets('forgot password asks for a code and saves the new password', (
    tester,
  ) async {
    phone(tester);
    final api = FakeAccountApi();
    final account = api.controller();
    addTearDown(account.dispose);
    await tester.pumpWidget(MaterialApp(home: AuthPage(account: account)));
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'cliente@example.com',
    );
    tester.testTextInput.hide();
    await tester.tap(find.byKey(const ValueKey('auth-forgot')));
    await tester.pumpAndSettle();
    expect(find.text('cliente@example.com'), findsOneWidget);
    await tester.tap(find.text('ENVIAR CÓDIGO'));
    await tester.pumpAndSettle();
    expect(api.resetEmail, 'cliente@example.com');
    expect(find.byKey(const ValueKey('reset-notice')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('reset-code')),
      'codigo-errado-com-mais-de-20',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-password')),
      'Outra frase segura 456!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-confirm')),
      'Outra frase segura 456!',
    );
    tester.testTextInput.hide();
    await reveal(tester, find.text('SALVAR NOVA SENHA'));
    await tester.tap(find.text('SALVAR NOVA SENHA'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reset-error')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('reset-code')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('reset-code')), validCode);
    tester.testTextInput.hide();
    await reveal(tester, find.text('SALVAR NOVA SENHA'));
    await tester.tap(find.text('SALVAR NOVA SENHA'));
    await tester.pumpAndSettle();
    expect(find.text('Senha alterada. Entre com a nova senha.'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
  });

  testWidgets('legal page shows headings, lists and table rows', (tester) async {
    phone(tester);
    final account = FakeAccountApi().controller();
    addTearDown(account.dispose);
    await tester.pumpWidget(
      MaterialApp(home: LegalPage(account: account, slug: 'terms')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.text('Termos de Uso da Lumen'), findsOneWidget);
    expect(find.text('1. Quem somos'), findsOneWidget);
    expect(find.text('Item de lista'), findsOneWidget);
    expect(find.text('DADO'), findsOneWidget);
    expect(find.text('Criar a conta'), findsOneWidget);
    expect(find.text('Versão 2026-11'), findsOneWidget);
  });

  testWidgets('security page disconnects another device', (tester) async {
    phone(tester);
    final api = FakeAccountApi();
    final account = api.controller(signedIn: true);
    addTearDown(account.dispose);
    await account.initialize();
    await tester.pumpWidget(MaterialApp(home: SecurityPage(account: account)));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Safari · iPhone'));
    expect(find.text('Chrome · Windows'), findsOneWidget);
    expect(find.text('Este aparelho'), findsOneWidget);
    await tester.tap(find.text('DESCONECTAR'));
    await tester.pumpAndSettle();
    expect(find.text('Safari · iPhone'), findsNothing);
    expect(find.text('DESCONECTAR OS OUTROS APARELHOS'), findsNothing);
    expect(api.devices.length, 1);
  });

  testWidgets('security page changes the password after checking the current one', (
    tester,
  ) async {
    phone(tester);
    final api = FakeAccountApi();
    final account = api.controller(signedIn: true);
    addTearDown(account.dispose);
    await account.initialize();
    await tester.pumpWidget(MaterialApp(home: SecurityPage(account: account)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('security-current')), 'senha errada');
    await tester.enterText(
      find.byKey(const ValueKey('security-new')),
      'Outra frase segura 456!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('security-confirm')),
      'Outra frase segura 456!',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('ALTERAR SENHA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ALTERAR SENHA'));
    await tester.pumpAndSettle();
    expect(find.text('Senha atual incorreta.'), findsOneWidget);
    expect(api.passwordChanged, isFalse);

    await tester.enterText(find.byKey(const ValueKey('security-current')), password);
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('ALTERAR SENHA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ALTERAR SENHA'));
    await tester.pumpAndSettle();
    expect(api.passwordChanged, isTrue);
    expect(
      find.text('Senha alterada. Os outros aparelhos foram desconectados.'),
      findsOneWidget,
    );
  });

  testWidgets('profile saves name and only a valid phone', (tester) async {
    phone(tester);
    final api = FakeAccountApi();
    final account = api.controller(signedIn: true);
    addTearDown(account.dispose);
    await account.initialize();
    await tester.pumpWidget(MaterialApp(home: ProfileEditPage(account: account)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('profile-name')), ' Ana Lima ');
    await tester.enterText(find.byKey(const ValueKey('profile-phone')), '1234');
    tester.testTextInput.hide();
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();
    expect(find.text('Informe DDD e número (10 ou 11 dígitos).'), findsOneWidget);
    expect(api.profile, isNull);

    await tester.enterText(find.byKey(const ValueKey('profile-phone')), '(84) 99999-1234');
    tester.testTextInput.hide();
    await tester.tap(find.text('SALVAR'));
    await tester.pumpAndSettle();
    expect(api.profile, {'full_name': 'Ana Lima', 'phone': '84999991234'});
    expect(account.user?['full_name'], 'Ana Lima');
  });

  testWidgets('privacy toggles marketing and deletes the account with the password', (
    tester,
  ) async {
    phone(tester);
    final api = FakeAccountApi();
    final account = api.controller(signedIn: true);
    addTearDown(account.dispose);
    await account.initialize();
    await tester.pumpWidget(MaterialApp(home: PrivacyPage(account: account)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('marketing-switch')));
    await tester.pumpAndSettle();
    expect(account.user?['marketing_opt_in'], isTrue);

    await tester.tap(find.text('Baixar meus dados'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('confirm-password')), 'senha errada');
    await tester.tap(find.text('COPIAR MEUS DADOS'));
    await tester.pumpAndSettle();
    expect(find.text('Senha incorreta.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(const ValueKey('delete-account')));
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('confirm-password')), password);
    await tester.tap(find.text('EXCLUIR DEFINITIVAMENTE'));
    await tester.pumpAndSettle();
    expect(api.deleted, isTrue);
    expect(account.user, isNull);
  });

  testWidgets('addresses are validated, saved and listed', (tester) async {
    phone(tester);
    final api = FakeAccountApi();
    final account = api.controller(signedIn: true);
    addTearDown(account.dispose);
    await account.initialize();
    await tester.pumpWidget(MaterialApp(home: AddressesPage(account: account)));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum endereço salvo ainda.'), findsOneWidget);

    await tester.tap(find.text('NOVO ENDEREÇO'));
    await tester.pumpAndSettle();
    for (final entry in {
      'recipient': 'Ana Lima',
      'postal_code': '590',
      'street': 'Rua das Flores',
      'number': '10',
      'district': 'Tirol',
      'city': 'Natal',
      'state': 'rn',
    }.entries) {
      final field = find.byKey(ValueKey('address-${entry.key}'));
      await reveal(tester, field);
      await tester.enterText(field, entry.value);
    }
    tester.testTextInput.hide();
    await reveal(tester, find.text('SALVAR ENDEREÇO'));
    await tester.tap(find.text('SALVAR ENDEREÇO'));
    await tester.pumpAndSettle();
    expect(find.text('CEP com 8 números.'), findsOneWidget);
    expect(api.addresses, isEmpty);

    final cep = find.byKey(const ValueKey('address-postal_code'));
    await reveal(tester, cep);
    await tester.enterText(cep, '59015-000');
    tester.testTextInput.hide();
    await reveal(tester, find.text('SALVAR ENDEREÇO'));
    await tester.tap(find.text('SALVAR ENDEREÇO'));
    await tester.pumpAndSettle();
    expect(api.addresses.single['postal_code'], '59015000');
    expect(api.addresses.single['state'], 'RN');
    expect(find.text('Casa'), findsOneWidget);
    expect(find.textContaining('Rua das Flores, 10'), findsOneWidget);
  });
}

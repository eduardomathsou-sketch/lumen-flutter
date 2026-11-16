import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumen_store/admin/admin_api.dart';
import 'package:lumen_store/admin/admin_pages.dart';
import 'package:lumen_store/admin/photo_picker.dart';
import 'package:lumen_store/checkout/commerce_api.dart';

import 'admin_test.dart' show FakeAdmin, tapVisible;
import 'checkout_test.dart' show MemoryStorage;

final photoUrl = 'https://api.example.com/api/v1/media/${'a' * 64}.jpg';

class FakeAdminWithPhotos extends FakeAdmin implements AdminMediaRepository {
  List<int>? uploaded;
  String? contentType;
  bool fail = false;
  @override
  Future<String> uploadPhoto(List<int> bytes, String contentType) async {
    if (fail) {
      throw const CommerceException('Foto grande demais: envie até 4 MB.', 413);
    }
    uploaded = bytes;
    this.contentType = contentType;
    return photoUrl;
  }
}

final jpeg = PickedPhoto(Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3]), 'image/jpeg');

Future<void> openForm(
  WidgetTester tester,
  FakeAdmin repo, {
  PhotoPicker? picker,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AdminProductPage(repository: repo, productId: 1, photoPicker: picker),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('AdminApi sends the photo bytes with the admin session', () async {
    final token = MemoryStorage();
    await token.write('admin-session');
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/admin/media');
      expect(request.headers['Authorization'], 'Bearer admin-session');
      expect(request.headers['Content-Type'], startsWith('image/jpeg'));
      expect(request.bodyBytes, jpeg.bytes);
      return http.Response(jsonEncode({'url': photoUrl}), 201);
    });
    addTearDown(client.close);
    final api = AdminApi(
      CommerceApi(
        client: client,
        accountStorage: token,
        storage: MemoryStorage(),
        baseUrl: 'http://localhost/api/v1',
      ),
    );
    expect(await api.uploadPhoto(jpeg.bytes, jpeg.contentType), photoUrl);
  });

  testWidgets('upload button only appears where photos can be chosen and sent', (
    tester,
  ) async {
    // Sem repositório de fotos, ou sem seletor (testes rodam fora do navegador): sem botão.
    await openForm(tester, FakeAdmin(), picker: () async => jpeg);
    expect(find.byKey(const ValueKey('admin-photo-upload')), findsNothing);
    await openForm(tester, FakeAdminWithPhotos());
    expect(find.byKey(const ValueKey('admin-photo-upload')), findsNothing);
    await openForm(tester, FakeAdminWithPhotos(), picker: () async => jpeg);
    expect(find.byKey(const ValueKey('admin-photo-upload')), findsOneWidget);
  });

  testWidgets('sent photo fills the product photo and is saved with it', (
    tester,
  ) async {
    final repo = FakeAdminWithPhotos();
    await openForm(tester, repo, picker: () async => jpeg);
    await tapVisible(tester, find.text('ENVIAR FOTO DO COMPUTADOR'));
    expect(repo.uploaded, jpeg.bytes);
    expect(repo.contentType, 'image/jpeg');
    expect(find.text(photoUrl), findsOneWidget);
    expect(find.textContaining('Foto enviada'), findsOneWidget);
    await tapVisible(tester, find.text('SALVAR PRODUTO'));
    expect(repo.saved!['image_url'], photoUrl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled choice changes nothing; errors are explained', (
    tester,
  ) async {
    final repo = FakeAdminWithPhotos();
    PickedPhoto? next;
    Object? failure;
    await openForm(tester, repo, picker: () async {
      final error = failure;
      if (error != null) throw error;
      return next;
    });
    await tapVisible(tester, find.text('ENVIAR FOTO DO COMPUTADOR'));
    expect(repo.uploaded, isNull);
    expect(find.text(photoUrl), findsNothing);

    failure = const PhotoPickException('Não consegui abrir essa foto.');
    await tapVisible(tester, find.text('ENVIAR FOTO DO COMPUTADOR'));
    expect(find.text('Não consegui abrir essa foto.'), findsOneWidget);

    failure = null;
    next = jpeg;
    repo.fail = true;
    await tapVisible(tester, find.text('ENVIAR FOTO DO COMPUTADOR'));
    expect(find.text('Foto grande demais: envie até 4 MB.'), findsOneWidget);
    expect(find.text(photoUrl), findsNothing);
    expect(repo.saves, 0);
  });
}

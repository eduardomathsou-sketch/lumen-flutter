import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../checkout/commerce_api.dart';
import '../store/catalog_api.dart';

class AccountController extends ChangeNotifier {
  AccountController(this.api, {SessionStorage? favoritesStorage})
    : storage =
          favoritesStorage ??
          SecureSessionStorage(CommerceApi.defaultBaseUrl, scope: 'favorites');
  final CommerceApi api;
  final SessionStorage storage;
  Json? user;
  List<StoreProduct> favorites = [];
  bool loading = true;
  String? error;
  final Set<int> updating = {};
  bool _disposed = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  bool isFavorite(int id) => favorites.any((x) => x.id == id);
  bool get isAdmin => user?['is_admin'] == true;

  Future<void> initialize() async {
    loading = true;
    error = null;
    _changed();
    try {
      if (await api.hasAccount()) {
        try {
          user = await api.accountRequest('GET', '/auth/me') as Json;
        } on CommerceException catch (e) {
          if (e.status != 401) rethrow;
          await api.clearAccount();
          user = null;
        }
      }
      await _loadFavorites();
    } catch (_) {
      error = 'Não foi possível carregar sua conta. Tente novamente.';
    } finally {
      loading = false;
      _changed();
    }
  }

  Future<void> _loadFavorites() async {
    final dynamic data = user != null
        ? await api.accountRequest('GET', '/favorites')
        : jsonDecode((await storage.read()) ?? '[]');
    favorites = (data as List)
        .map((x) => StoreProduct.fromJson(x as Json))
        .toList();
  }

  /// Falso quando os Termos mudaram depois do aceite: o app pede o aceite de novo.
  bool get termsCurrent => user == null || user!['terms_current'] != false;

  Future<void> signIn(
    String email,
    String password,
    bool register, {
    bool acceptTerms = false,
    bool marketing = false,
  }) async {
    user = await api.signIn(
      email.trim(),
      password,
      register,
      acceptTerms: acceptTerms,
      marketing: marketing,
    );
    error = null;
    favorites = [];
    try {
      await _loadFavorites();
    } catch (_) {
      error = 'Conta conectada. Atualize para carregar seus favoritos.';
    }
    _changed();
  }

  // --- Documentos legais e nova senha (não precisam de conta) ---
  Future<Json> legalDocument(String slug) async =>
      await api.publicRequest('GET', '/legal/${Uri.encodeComponent(slug)}')
          as Json;

  Future<String> requestPasswordReset(String email) async {
    final data =
        await api.publicRequest(
              'POST',
              '/auth/password-reset',
              body: {'email': email.trim()},
            )
            as Json;
    return data['detail'] as String;
  }

  Future<void> confirmPasswordReset(String code, String newPassword) async {
    await api.publicRequest(
      'POST',
      '/auth/password-reset/confirm',
      body: {'token': code.trim(), 'new_password': newPassword},
    );
  }

  // --- Segurança da conta ---
  Future<void> changePassword(String current, String next) async {
    await api.accountRequest(
      'POST',
      '/users/me/password',
      body: {'current_password': current, 'new_password': next},
    );
  }

  Future<List<Json>> sessions() async =>
      (await api.accountRequest('GET', '/auth/sessions') as List).cast<Json>();

  Future<void> revokeSession(String id) async {
    await api.accountRequest(
      'DELETE',
      '/auth/sessions/${Uri.encodeComponent(id)}',
    );
  }

  Future<void> logoutOthers() async {
    await api.accountRequest('POST', '/auth/logout-others');
  }

  Future<void> acceptTerms() async {
    user =
        await api.accountRequest(
              'PUT',
              '/users/me/consents',
              body: {
                'marketing_opt_in': user?['marketing_opt_in'] == true,
                'accept_terms': true,
              },
            )
            as Json;
    _changed();
  }

  // --- Endereços salvos (até 10 por conta) ---
  Future<List<Json>> addresses() async =>
      (await api.accountRequest('GET', '/users/me/addresses') as List).cast<Json>();

  Future<Json> saveAddress(Json data, {int? id}) async =>
      await api.accountRequest(
            id == null ? 'POST' : 'PUT',
            id == null ? '/users/me/addresses' : '/users/me/addresses/$id',
            body: data,
          )
          as Json;

  Future<void> deleteAddress(int id) async {
    await api.accountRequest('DELETE', '/users/me/addresses/$id');
  }

  // --- Meus dados e privacidade (LGPD) ---
  Future<void> updateProfile({String? fullName, String? phone}) async {
    user =
        await api.accountRequest(
              'PUT',
              '/users/me',
              body: {'full_name': fullName, 'phone': phone},
            )
            as Json;
    _changed();
  }

  Future<void> setMarketing(bool enabled) async {
    user =
        await api.accountRequest(
              'PUT',
              '/users/me/consents',
              body: {'marketing_opt_in': enabled},
            )
            as Json;
    _changed();
  }

  /// Cópia completa dos dados da conta (pede a senha de novo).
  Future<Json> exportData(String password) async =>
      await api.accountRequest(
            'POST',
            '/users/me/data-export',
            body: {'password': password},
          )
          as Json;

  /// Exclui a conta na API e limpa este aparelho.
  Future<void> deleteAccount(String password) async {
    await api.accountRequest(
      'POST',
      '/users/me/delete',
      body: {'password': password},
    );
    await sessionEnded();
  }

  /// Sessão vencida ou encerrada em outro aparelho: limpa a conta deste aparelho.
  Future<void> sessionEnded() async {
    await api.clearAccount();
    user = null;
    favorites = [];
    try {
      await _loadFavorites();
    } catch (_) {
      // Sem favoritos locais não há o que mostrar; a conta já saiu.
    }
    _changed();
  }

  Future<void> logout() async {
    try {
      await api.accountRequest('POST', '/auth/logout');
    } on CommerceException catch (e) {
      if (e.status != 401) rethrow;
    }
    await api.clearAccount();
    user = null;
    favorites = [];
    error = null;
    try {
      await _loadFavorites();
    } catch (_) {
      error = 'Não foi possível carregar os favoritos deste aparelho.';
    }
    _changed();
  }

  Future<void> toggle(StoreProduct product) async {
    if (loading || updating.isNotEmpty) return;
    updating.add(product.id);
    _changed();
    try {
      final selected = isFavorite(product.id);
      final next = favorites.where((x) => x.id != product.id).toList();
      if (!selected) next.add(product);
      if (user != null) {
        await api.accountRequest(
          selected ? 'DELETE' : 'PUT',
          '/favorites/${product.id}',
        );
      } else {
        await storage.write(
          jsonEncode(
            next
                .map(
                  (p) => {
                    'id': p.id,
                    'name': p.name,
                    'description': p.description,
                    'price': p.price,
                    'stock': p.stock,
                    'category_name': p.categoryName,
                    'image_url': p.imageUrl,
                  },
                )
                .toList(),
          ),
        );
      }
      favorites = next;
    } finally {
      updating.remove(product.id);
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import '../../features/profile/domain/entities/address_entity.dart';
import '../../features/profile/domain/entities/user_entity.dart';

/// Credencial de teste (usada apenas em demonstração).
class MockCredential {
  final UserEntity user;
  final String password;
  final List<AddressEntity> addresses;
  final Set<String> favoriteProductIds;

  const MockCredential({
    required this.user,
    required this.password,
    required this.addresses,
    required this.favoriteProductIds,
  });
}

/// Usuários de teste do app.
///
/// Regras:
/// - `camila@email.com` → usuária completa com pedidos (ativo + entregue), endereços,
///   favoritos e pontos de fidelidade.
/// - `maria@email.com` → usuária com apenas pedido entregue (sem pedido ativo).
/// - `joao@email.com` → novo usuário, sem pedidos, sem favoritos.
/// - `admin@raito.com` → admin para testes internos.
final List<MockCredential> mockCredentials = [
  MockCredential(
    user: UserEntity(
      email: 'camila@email.com',
      name: 'Camila Rocha',
      initials: 'CR',
      isAdmin: false,
      memberSince: DateTime(2025, 3, 12),
      phone: '(62) 99999-1234',
      birthDate: DateTime(1994, 3, 15),
      loyaltyPoints: 890,
    ),
    password: '123456',
    addresses: [
      AddressEntity(
        id: 'a1',
        label: 'Casa',
        street: 'Rua das Flores',
        number: '123',
        complement: 'Apto 302',
        neighborhood: 'Setor Bueno',
        city: 'Goiânia',
        state: 'GO',
        zipCode: '74230-010',
        isDefault: true,
      ),
      AddressEntity(
        id: 'a2',
        label: 'Trabalho',
        street: 'Av. T-63',
        number: '1500',
        complement: 'Sala 405',
        neighborhood: 'Setor Bueno',
        city: 'Goiânia',
        state: 'GO',
        zipCode: '74223-050',
      ),
    ],
    favoriteProductIds: {'1', '5', '7'},
  ),
  MockCredential(
    user: UserEntity(
      email: 'maria@email.com',
      name: 'Maria Silva',
      initials: 'MS',
      isAdmin: false,
      memberSince: DateTime(2024, 11, 20),
      phone: '(11) 98888-5555',
      birthDate: DateTime(1990, 7, 8),
      loyaltyPoints: 320,
    ),
    password: '123456',
    addresses: [
      AddressEntity(
        id: 'a3',
        label: 'Casa',
        street: 'Rua Augusta',
        number: '2400',
        complement: 'Bloco B, Apto 45',
        neighborhood: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01412-100',
        isDefault: true,
      ),
    ],
    favoriteProductIds: {'3'},
  ),
  MockCredential(
    user: UserEntity(
      email: 'joao@email.com',
      name: 'João Pereira',
      initials: 'JP',
      isAdmin: false,
      memberSince: DateTime(2026, 4, 1),
      phone: '(21) 97777-2222',
      loyaltyPoints: 0,
    ),
    password: '123456',
    addresses: const [],
    favoriteProductIds: const {},
  ),
  MockCredential(
    user: UserEntity(
      email: 'admin@raito.com',
      name: 'Admin Raitõ',
      initials: 'AR',
      isAdmin: true,
      memberSince: DateTime(2024, 1, 1),
      phone: '(62) 3000-0000',
      loyaltyPoints: 9999,
    ),
    password: 'admin',
    addresses: [
      AddressEntity(
        id: 'a4',
        label: 'Matriz',
        street: 'Av. Raitõ',
        number: '1',
        neighborhood: 'Centro',
        city: 'Goiânia',
        state: 'GO',
        zipCode: '74000-000',
        isDefault: true,
      ),
    ],
    favoriteProductIds: const {},
  ),
];

MockCredential? findCredential(String email, String password) {
  for (final c in mockCredentials) {
    if (c.user.email.toLowerCase() == email.toLowerCase() &&
        c.password == password) {
      return c;
    }
  }
  return null;
}

MockCredential? findCredentialByEmail(String email) {
  for (final c in mockCredentials) {
    if (c.user.email.toLowerCase() == email.toLowerCase()) return c;
  }
  return null;
}

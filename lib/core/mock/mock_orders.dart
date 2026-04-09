import '../../features/profile/domain/entities/address_entity.dart';
import '../../features/profile/domain/entities/order_entity.dart';
import 'mock_users.dart';

/// Pedidos mock indexados por e-mail do usuário.
///
/// Regras:
/// - Camila tem 1 pedido em andamento (status `shipped`) + 1 entregue.
/// - Maria tem 1 pedido entregue (para permitir avaliação).
/// - João não tem pedidos ainda.
/// - Admin tem 1 pedido cancelado como exemplo.
final List<OrderEntity> mockOrders = [
  // Camila — pedido em andamento
  OrderEntity(
    id: '12847',
    userEmail: 'camila@email.com',
    createdAt: DateTime(2026, 4, 6, 9, 15),
    status: OrderStatus.shipped,
    items: const [
      OrderItem(
        productId: '1',
        productName: 'Pendente Moderno',
        imageUrl:
            'https://images.unsplash.com/photo-1565814636199-ae8133055c1c?w=400',
        subtitle: 'Luz quente · E27',
        price: 890,
        quantity: 1,
      ),
    ],
    address: _camilaAddress(),
    subtotal: 890,
    shipping: 0,
    discount: 89,
    paymentMethod: 'Pix',
    estimatedDelivery: DateTime(2026, 4, 8),
    timeline: [
      OrderTimelineEvent(
        title: 'Pedido confirmado',
        timestamp: DateTime(2026, 4, 6, 9, 15),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Pagamento aprovado',
        timestamp: DateTime(2026, 4, 6, 9, 18),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Em preparo',
        timestamp: DateTime(2026, 4, 6, 13, 0),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Saiu para entrega',
        timestamp: DateTime(2026, 4, 8, 8, 45),
        active: true,
        description:
            'Seu pedido está com o entregador e chega hoje até 18h.',
      ),
      const OrderTimelineEvent(
        title: 'Entregue',
      ),
    ],
  ),

  // Camila — pedido entregue (pendente de avaliação)
  OrderEntity(
    id: '12711',
    userEmail: 'camila@email.com',
    createdAt: DateTime(2026, 3, 18, 14, 30),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productId: '5',
        productName: 'Abajur de Cabeceira',
        imageUrl:
            'https://images.unsplash.com/photo-1540932239986-30128078f3c5?w=400',
        subtitle: 'Luz quente · E27',
        price: 349,
        quantity: 2,
      ),
    ],
    address: _camilaAddress(),
    subtotal: 698,
    shipping: 0,
    discount: 0,
    paymentMethod: 'Cartão de crédito',
    timeline: [
      OrderTimelineEvent(
        title: 'Pedido confirmado',
        timestamp: DateTime(2026, 3, 18, 14, 30),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Pagamento aprovado',
        timestamp: DateTime(2026, 3, 18, 14, 32),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Em preparo',
        timestamp: DateTime(2026, 3, 18, 18, 0),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Saiu para entrega',
        timestamp: DateTime(2026, 3, 20, 9, 0),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Entregue',
        timestamp: DateTime(2026, 3, 20, 16, 22),
        completed: true,
      ),
    ],
    reviewed: false,
  ),

  // Maria — entregue
  OrderEntity(
    id: '12440',
    userEmail: 'maria@email.com',
    createdAt: DateTime(2026, 2, 10, 11, 0),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productId: '3',
        productName: 'Luminária de Mesa',
        imageUrl:
            'https://images.unsplash.com/photo-1524484485831-a92ffc0de03f?w=400',
        subtitle: 'Luz neutra · LED integrado',
        price: 289,
        quantity: 1,
      ),
    ],
    address: _mariaAddress(),
    subtotal: 289,
    shipping: 0,
    discount: 0,
    paymentMethod: 'Pix',
    timeline: [
      OrderTimelineEvent(
        title: 'Pedido confirmado',
        timestamp: DateTime(2026, 2, 10, 11, 0),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Entregue',
        timestamp: DateTime(2026, 2, 13, 15, 0),
        completed: true,
      ),
    ],
    reviewed: true,
  ),

  // Admin — cancelado
  OrderEntity(
    id: '12001',
    userEmail: 'admin@raito.com',
    createdAt: DateTime(2026, 1, 5, 10, 0),
    status: OrderStatus.cancelled,
    items: const [
      OrderItem(
        productId: '8',
        productName: 'Iluminação de Palco',
        imageUrl:
            'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400',
        subtitle: 'Kit profissional',
        price: 2890,
        quantity: 1,
      ),
    ],
    address: _adminAddress(),
    subtotal: 2890,
    shipping: 0,
    discount: 0,
    paymentMethod: 'Boleto',
    timeline: [
      OrderTimelineEvent(
        title: 'Pedido confirmado',
        timestamp: DateTime(2026, 1, 5, 10, 0),
        completed: true,
      ),
      OrderTimelineEvent(
        title: 'Cancelado',
        timestamp: DateTime(2026, 1, 5, 14, 0),
        completed: true,
        description: 'Cancelado por solicitação do cliente.',
      ),
    ],
  ),
];

AddressEntity _camilaAddress() =>
    findCredentialByEmail('camila@email.com')!.addresses.first;

AddressEntity _mariaAddress() =>
    findCredentialByEmail('maria@email.com')!.addresses.first;

AddressEntity _adminAddress() =>
    findCredentialByEmail('admin@raito.com')!.addresses.first;

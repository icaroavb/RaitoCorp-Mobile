import 'package:equatable/equatable.dart';

import 'address_entity.dart';

enum OrderStatus { confirmed, preparing, shipped, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.confirmed => 'Confirmado',
        OrderStatus.preparing => 'Em preparo',
        OrderStatus.shipped => 'Saiu para entrega',
        OrderStatus.delivered => 'Entregue',
        OrderStatus.cancelled => 'Cancelado',
      };

  bool get isInProgress =>
      this == OrderStatus.confirmed ||
      this == OrderStatus.preparing ||
      this == OrderStatus.shipped;

  bool get isDelivered => this == OrderStatus.delivered;
  bool get isCancelled => this == OrderStatus.cancelled;
}

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String imageUrl;
  final String subtitle;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.subtitle,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

class OrderTimelineEvent extends Equatable {
  final String title;
  final DateTime? timestamp;
  final bool completed;
  final bool active;
  final String? description;

  const OrderTimelineEvent({
    required this.title,
    this.timestamp,
    this.completed = false,
    this.active = false,
    this.description,
  });

  @override
  List<Object?> get props => [title, timestamp, completed, active];
}

class OrderEntity extends Equatable {
  final String id;
  final String userEmail;
  final DateTime createdAt;
  final OrderStatus status;
  final List<OrderItem> items;
  final AddressEntity address;
  final double subtotal;
  final double shipping;
  final double discount;
  final String paymentMethod;
  final DateTime? estimatedDelivery;
  final List<OrderTimelineEvent> timeline;
  final bool reviewed;

  const OrderEntity({
    required this.id,
    required this.userEmail,
    required this.createdAt,
    required this.status,
    required this.items,
    required this.address,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.paymentMethod,
    this.estimatedDelivery,
    this.timeline = const [],
    this.reviewed = false,
  });

  double get total => subtotal + shipping - discount;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [id];
}

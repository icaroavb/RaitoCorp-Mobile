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

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['product_id'].toString(),
        productName: json['product_name'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'image_url': imageUrl,
        'subtitle': subtitle,
        'price': price,
        'quantity': quantity,
      };

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

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) =>
      OrderTimelineEvent(
        title: json['title'] as String,
        timestamp: json['timestamp'] == null
            ? null
            : DateTime.parse(json['timestamp'] as String).toLocal(),
        completed: json['completed'] as bool? ?? false,
        active: json['active'] as bool? ?? false,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        if (timestamp != null) 'timestamp': timestamp!.toUtc().toIso8601String(),
        'completed': completed,
        'active': active,
        if (description != null) 'description': description,
      };

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

  factory OrderEntity.fromJson(Map<String, dynamic> json) => OrderEntity(
        id: json['id'].toString(),
        userEmail: json['user_email'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        status: _enumFromString(
          OrderStatus.values,
          json['status'] as String?,
          OrderStatus.confirmed,
        ),
        items: (json['items'] as List? ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        address: AddressEntity.fromJson(
            json['address'] as Map<String, dynamic>),
        subtotal: (json['subtotal'] as num).toDouble(),
        shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['payment_method'] as String? ?? '',
        estimatedDelivery: json['estimated_delivery'] == null
            ? null
            : DateTime.parse(json['estimated_delivery'] as String).toLocal(),
        timeline: (json['timeline'] as List? ?? const [])
            .map((e) => OrderTimelineEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        reviewed: json['reviewed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_email': userEmail,
        'created_at': createdAt.toUtc().toIso8601String(),
        'status': status.name,
        'items': items.map((i) => i.toJson()).toList(),
        'address': address.toJson(),
        'subtotal': subtotal,
        'shipping': shipping,
        'discount': discount,
        'payment_method': paymentMethod,
        if (estimatedDelivery != null)
          'estimated_delivery': estimatedDelivery!.toUtc().toIso8601String(),
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'reviewed': reviewed,
      };

  double get total => subtotal + shipping - discount;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [id];
}

T _enumFromString<T extends Enum>(List<T> values, String? raw, T fallback) {
  if (raw == null) return fallback;
  for (final v in values) {
    if (v.name.toLowerCase() == raw.toLowerCase()) return v;
  }
  return fallback;
}

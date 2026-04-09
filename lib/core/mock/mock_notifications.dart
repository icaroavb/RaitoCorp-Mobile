import '../../features/profile/domain/entities/notification_entity.dart';

final List<AppNotification> mockNotifications = [
  AppNotification(
    id: 'n1',
    userEmail: 'camila@email.com',
    type: AppNotificationType.order,
    title: 'Seu pedido saiu para entrega',
    body: 'Pendente Moderno chega hoje até 18h.',
    createdAt: DateTime(2026, 4, 8, 8, 45),
  ),
  AppNotification(
    id: 'n2',
    userEmail: 'camila@email.com',
    type: AppNotificationType.review,
    title: 'Avalie seu produto',
    body: 'Como foi o Abajur de Cabeceira? Sua opinião ajuda muito.',
    createdAt: DateTime(2026, 4, 7, 10, 0),
  ),
  AppNotification(
    id: 'n3',
    userEmail: 'camila@email.com',
    type: AppNotificationType.promotion,
    title: 'Luz quente com 20% off',
    body: 'Os produtos mais buscados do quarto estão em promoção.',
    createdAt: DateTime(2026, 4, 5, 9, 0),
    read: true,
  ),
  AppNotification(
    id: 'n4',
    userEmail: 'maria@email.com',
    type: AppNotificationType.review,
    title: 'Obrigado pela avaliação!',
    body: 'Sua opinião sobre a Luminária de Mesa foi publicada.',
    createdAt: DateTime(2026, 2, 14, 10, 0),
    read: true,
  ),
];

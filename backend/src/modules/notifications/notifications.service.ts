import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { DeliveryStatus } from '../../common/enums/delivery-status.enum';
import { NotificationType } from '../../common/enums/notification-type.enum';
import { NotificationResponseDto } from './dto/notification-response.dto';
import { PushTokenResponseDto } from './dto/push-token-response.dto';
import { RegisterPushTokenDto } from './dto/register-push-token.dto';
import { NotificationDeliveryLogEntity } from './entities/notification-delivery-log.entity';
import { NotificationEntity } from './entities/notification.entity';
import { PushTokenEntity } from './entities/push-token.entity';

interface CreateNotificationInput {
  recipientId: string;
  type: NotificationType;
  title: string;
  body: string;
  entityType?: string | null;
  entityId?: string | null;
  data?: Record<string, unknown> | null;
}

/**
 * Сервіс повідомлень.
 * На цьому етапі створює внутрішні повідомлення та зберігає push-токени.
 */
@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(NotificationEntity)
    private readonly notificationsRepository: Repository<NotificationEntity>,

    @InjectRepository(PushTokenEntity)
    private readonly pushTokensRepository: Repository<PushTokenEntity>,

    @InjectRepository(NotificationDeliveryLogEntity)
    private readonly deliveryLogsRepository: Repository<NotificationDeliveryLogEntity>,
  ) {}

  /**
   * Створює внутрішнє повідомлення.
   * Push-доставку підключимо окремо після Firebase.
   */
  async createNotification(
    input: CreateNotificationInput,
  ): Promise<NotificationResponseDto> {
    const notification = this.notificationsRepository.create({
      recipientId: input.recipientId,
      type: input.type,
      title: input.title,
      body: input.body,
      entityType: input.entityType ?? null,
      entityId: input.entityId ?? null,
      data: input.data ?? null,
      readAt: null,
    });

    const savedNotification =
      await this.notificationsRepository.save(notification);

    /**
     * Фіксуємо, що in-app notification створено.
     */
    const deliveryLog = this.deliveryLogsRepository.create({
      notificationId: savedNotification.id,
      pushTokenId: null,
      channel: 'in_app',
      status: DeliveryStatus.SENT,
      errorMessage: null,
    });

    await this.deliveryLogsRepository.save(deliveryLog);

    return this.toNotificationResponseDto(savedNotification);
  }

  /**
   * Повертає повідомлення поточного користувача.
   */
  async getMyNotifications(
    userId: string,
  ): Promise<NotificationResponseDto[]> {
    const notifications = await this.notificationsRepository.find({
      where: {
        recipientId: userId,
      },
      order: {
        createdAt: 'DESC',
      },
      take: 100,
    });

    return notifications.map((notification) =>
      this.toNotificationResponseDto(notification),
    );
  }

  /**
   * Позначає повідомлення як прочитане.
   */
  async markAsRead(
    notificationId: string,
    userId: string,
  ): Promise<NotificationResponseDto> {
    const notification = await this.notificationsRepository.findOne({
      where: {
        id: notificationId,
      },
    });

    if (!notification) {
      throw new NotFoundException({
        errorCode: 'NOTIFICATION_NOT_FOUND',
        message: 'Повідомлення не знайдено',
      });
    }

    if (notification.recipientId !== userId) {
      throw new ForbiddenException({
        errorCode: 'NOTIFICATION_ACCESS_DENIED',
        message: 'Ви не маєте доступу до цього повідомлення',
      });
    }

    if (!notification.readAt) {
      notification.readAt = new Date();
      await this.notificationsRepository.save(notification);
    }

    return this.toNotificationResponseDto(notification);
  }

  /**
   * Реєструє або оновлює push-токен пристрою.
   */
  async registerPushToken(
    userId: string,
    dto: RegisterPushTokenDto,
  ): Promise<PushTokenResponseDto> {
    const normalizedToken = dto.token.trim();

    let pushToken = await this.pushTokensRepository.findOne({
      where: {
        token: normalizedToken,
      },
    });

    if (!pushToken) {
      pushToken = this.pushTokensRepository.create({
        userId,
        token: normalizedToken,
        platform: dto.platform,
        deviceName: dto.deviceName?.trim() || null,
        isActive: true,
        lastUsedAt: new Date(),
      });
    } else {
      /**
       * Якщо токен уже є, оновлюємо його власника та стан.
       * Це корисно, якщо користувач перевстановив застосунок або перелогінився.
       */
      pushToken.userId = userId;
      pushToken.platform = dto.platform;
      pushToken.deviceName = dto.deviceName?.trim() || null;
      pushToken.isActive = true;
      pushToken.lastUsedAt = new Date();
    }

    const savedToken = await this.pushTokensRepository.save(pushToken);

    return this.toPushTokenResponseDto(savedToken);
  }

  /**
   * Перетворює NotificationEntity у DTO.
   */
  private toNotificationResponseDto(
    notification: NotificationEntity,
  ): NotificationResponseDto {
    return {
      id: notification.id,
      recipientId: notification.recipientId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      entityType: notification.entityType ?? null,
      entityId: notification.entityId ?? null,
      data: notification.data ?? null,
      readAt: notification.readAt?.toISOString() ?? null,
      createdAt: notification.createdAt.toISOString(),
    };
  }

  /**
   * Перетворює PushTokenEntity у DTO.
   */
  private toPushTokenResponseDto(
    pushToken: PushTokenEntity,
  ): PushTokenResponseDto {
    return {
      id: pushToken.id,
      userId: pushToken.userId,
      token: pushToken.token,
      platform: pushToken.platform,
      deviceName: pushToken.deviceName ?? null,
      isActive: pushToken.isActive,
      lastUsedAt: pushToken.lastUsedAt?.toISOString() ?? null,
      createdAt: pushToken.createdAt.toISOString(),
    };
  }
}
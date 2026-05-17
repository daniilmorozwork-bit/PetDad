import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { NotificationDeliveryLogEntity } from './entities/notification-delivery-log.entity';
import { NotificationEntity } from './entities/notification.entity';
import { PushTokenEntity } from './entities/push-token.entity';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

/**
 * Модуль повідомлень.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([
      NotificationEntity,
      PushTokenEntity,
      NotificationDeliveryLogEntity,
    ]),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { NotificationEntity } from './notification.entity';
import { PushTokenEntity } from './push-token.entity';

/**
 * Entity журналу доставки повідомлень.
 * На цьому етапі фіксуємо внутрішню доставку, push буде пізніше.
 */
@Entity('notification_delivery_logs')
export class NotificationDeliveryLogEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'notification_id', type: 'uuid' })
  notificationId: string;

  @ManyToOne(() => NotificationEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'notification_id' })
  notification: NotificationEntity;

  @Column({ name: 'push_token_id', type: 'uuid', nullable: true })
  pushTokenId?: string | null;

  @ManyToOne(() => PushTokenEntity, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'push_token_id' })
  pushToken?: PushTokenEntity | null;

  /**
   * Канал доставки: in_app або push.
   */
  @Column({ type: 'varchar', length: 32 })
  channel: string;

  @Column({
    type: 'varchar',
    length: 32,
    default: DeliveryStatus.PENDING,
  })
  status: DeliveryStatus;

  @Column({ name: 'error_message', type: 'text', nullable: true })
  errorMessage?: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
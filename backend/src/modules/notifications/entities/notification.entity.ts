import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { NotificationType } from '../../../common/enums/notification-type.enum';
import { UserEntity } from '../../users/entities/user.entity';

/**
 * Entity внутрішнього повідомлення.
 * Це повідомлення, яке користувач бачить у застосунку.
 */
@Entity('notifications')
export class NotificationEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Користувач, який отримує повідомлення.
   */
  @Column({ name: 'recipient_id', type: 'uuid' })
  recipientId: string;

  @ManyToOne(() => UserEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'recipient_id' })
  recipient: UserEntity;

  /**
   * Тип повідомлення.
   */
  @Column({ type: 'varchar', length: 64 })
  type: NotificationType;

  /**
   * Заголовок повідомлення.
   */
  @Column({ type: 'varchar', length: 255 })
  title: string;

  /**
   * Основний текст повідомлення.
   */
  @Column({ type: 'text' })
  body: string;

  /**
   * Тип сутності, до якої веде повідомлення.
   * Наприклад: lost_pet_report, sighting_report, qr_scan_event.
   */
  @Column({ name: 'entity_type', type: 'varchar', length: 120, nullable: true })
  entityType?: string | null;

  /**
   * ID сутності, до якої веде повідомлення.
   */
  @Column({ name: 'entity_id', type: 'uuid', nullable: true })
  entityId?: string | null;

  /**
   * Додаткові дані у JSON.
   * Наприклад petId, lostReportId, scanId.
   */
  @Column({ type: 'jsonb', nullable: true })
  data?: Record<string, unknown> | null;

  /**
   * Дата прочитання.
   * Якщо null — повідомлення непрочитане.
   */
  @Column({ name: 'read_at', type: 'timestamp', nullable: true })
  readAt?: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
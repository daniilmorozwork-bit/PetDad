import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { DevicePlatform } from '../../../common/enums/device-platform.enum';
import { UserEntity } from '../../users/entities/user.entity';

/**
 * Entity push-токена пристрою.
 * Firebase під'єднаємо пізніше, але токени вже зберігаємо.
 */
@Entity('push_tokens')
@Index('idx_push_tokens_token_unique', ['token'], { unique: true })
export class PushTokenEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => UserEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user: UserEntity;

  /**
   * FCM token або інший push token.
   */
  @Column({ type: 'varchar', length: 512 })
  token: string;

  @Column({
    type: 'varchar',
    length: 32,
    default: DevicePlatform.UNKNOWN,
  })
  platform: DevicePlatform;

  @Column({ name: 'device_name', type: 'varchar', length: 255, nullable: true })
  deviceName?: string | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @Column({ name: 'last_used_at', type: 'timestamp', nullable: true })
  lastUsedAt?: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { UserEntity } from '../../users/entities/user.entity';
import { LocationEntity } from './location.entity';

/**
 * Поточна або історична локація користувача.
 * Для MVP використовуємо це для майбутніх геосповіщень.
 */
@Entity('user_locations')
export class UserLocationEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ name: 'location_id', type: 'uuid' })
  locationId: string;

  /**
   * Активна поточна локація користувача.
   * Перед створенням нової активної локації старі можна деактивувати.
   */
  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @ManyToOne(() => UserEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user: UserEntity;

  @ManyToOne(() => LocationEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'location_id' })
  location: LocationEntity;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
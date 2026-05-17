import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { MapEventStatus } from '../../../common/enums/map-event-status.enum';
import { MapEventType } from '../../../common/enums/map-event-type.enum';
import { LocationEntity } from '../../locations/entities/location.entity';

/**
 * Entity події на карті.
 * Це універсальний шар для SOS, знайдених тварин, свідчень тощо.
 */
@Entity('map_events')
export class MapEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 64 })
  type: MapEventType;

  @Column({
    type: 'varchar',
    length: 64,
    default: MapEventStatus.ACTIVE,
  })
  status: MapEventStatus;

  /**
   * Назва події для відображення на карті.
   */
  @Column({ type: 'varchar', length: 255 })
  title: string;

  /**
   * Короткий опис події.
   */
  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column({ name: 'location_id', type: 'uuid' })
  locationId: string;

  @ManyToOne(() => LocationEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'location_id' })
  location: LocationEntity;

  /**
   * Тип джерела події.
   * Наприклад: lost_pet_report, found_pet_report, sighting_report.
   */
  @Column({ name: 'source_entity_type', type: 'varchar', length: 120, nullable: true })
  sourceEntityType?: string | null;

  /**
   * ID джерела події.
   */
  @Column({ name: 'source_entity_id', type: 'uuid', nullable: true })
  sourceEntityId?: string | null;

  /**
   * ID тварини, якщо подія пов'язана з твариною.
   */
  @Column({ name: 'pet_id', type: 'uuid', nullable: true })
  petId?: string | null;

  /**
   * Користувач, який створив подію.
   */
  @Column({ name: 'created_by_id', type: 'uuid', nullable: true })
  createdById?: string | null;

  /**
   * Дата завершення актуальності події.
   */
  @Column({ name: 'expires_at', type: 'timestamp', nullable: true })
  expiresAt?: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
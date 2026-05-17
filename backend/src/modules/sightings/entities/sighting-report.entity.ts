import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { ConfidenceLevel } from '../../../common/enums/confidence-level.enum';
import { SightingStatus } from '../../../common/enums/sighting-status.enum';
import { LocationEntity } from '../../locations/entities/location.entity';
import { LostPetReportEntity } from '../../lost-reports/entities/lost-pet-report.entity';
import { MapEventEntity } from '../../map-events/entities/map-event.entity';
import { PetEntity } from '../../pets/entities/pet.entity';
import { UserEntity } from '../../users/entities/user.entity';

/**
 * Entity свідчення про можливе місце перебування зниклої тварини.
 */
@Entity('sighting_reports')
export class SightingReportEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * SOS-оголошення, до якого належить свідчення.
   */
  @Column({ name: 'lost_report_id', type: 'uuid' })
  lostReportId: string;

  @ManyToOne(() => LostPetReportEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'lost_report_id' })
  lostReport: LostPetReportEntity;

  /**
   * Тварина, яку нібито бачили.
   * Дублюється для зручності запитів і зв’язку з картою.
   */
  @Column({ name: 'pet_id', type: 'uuid' })
  petId: string;

  @ManyToOne(() => PetEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'pet_id' })
  pet: PetEntity;

  /**
   * Користувач, який додав свідчення.
   */
  @Column({ name: 'reporter_id', type: 'uuid' })
  reporterId: string;

  @ManyToOne(() => UserEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'reporter_id' })
  reporter: UserEntity;

  /**
   * Локація, де користувач бачив схожу тварину.
   */
  @Column({ name: 'location_id', type: 'uuid' })
  locationId: string;

  @ManyToOne(() => LocationEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'location_id' })
  location: LocationEntity;

  /**
   * Подія карти, створена для цього свідчення.
   */
  @Column({ name: 'map_event_id', type: 'uuid', nullable: true })
  mapEventId?: string | null;

  @ManyToOne(() => MapEventEntity, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'map_event_id' })
  mapEvent?: MapEventEntity | null;

  /**
   * Коли користувач бачив схожу тварину.
   */
  @Column({ name: 'seen_at', type: 'timestamp' })
  seenAt: Date;

  /**
   * Опис свідчення.
   */
  @Column({ type: 'text' })
  description: string;

  /**
   * Рівень впевненості користувача.
   */
  @Column({ name: 'confidence_level', type: 'varchar', length: 32 })
  confidenceLevel: ConfidenceLevel;

  @Column({
    type: 'varchar',
    length: 32,
    default: SightingStatus.ACTIVE,
  })
  status: SightingStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
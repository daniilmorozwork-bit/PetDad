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

import { CloseReason } from '../../../common/enums/close-reason.enum';
import { ReportStatus } from '../../../common/enums/report-status.enum';
import { LocationEntity } from '../../locations/entities/location.entity';
import { PetEntity } from '../../pets/entities/pet.entity';
import { UserEntity } from '../../users/entities/user.entity';

/**
 * Entity SOS-оголошення про зникнення тварини.
 */
@Entity('lost_pet_reports')
@Index('idx_one_active_lost_report_per_pet', ['petId'], {
  unique: true,
  where: `"status" = 'active'`,
})
export class LostPetReportEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Тварина, яка зникла.
   */
  @Column({ name: 'pet_id', type: 'uuid' })
  petId: string;

  @ManyToOne(() => PetEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'pet_id' })
  pet: PetEntity;

  /**
   * Власник тварини, який створив SOS.
   */
  @Column({ name: 'owner_id', type: 'uuid' })
  ownerId: string;

  @ManyToOne(() => UserEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'owner_id' })
  owner: UserEntity;

  /**
   * Локація, де тварину бачили востаннє.
   */
  @Column({ name: 'last_seen_location_id', type: 'uuid' })
  lastSeenLocationId: string;

  @ManyToOne(() => LocationEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'last_seen_location_id' })
  lastSeenLocation: LocationEntity;

  /**
   * Час, коли тварину бачили востаннє.
   */
  @Column({ name: 'last_seen_at', type: 'timestamp' })
  lastSeenAt: Date;

  /**
   * Опис ситуації.
   */
  @Column({ type: 'text' })
  description: string;

  /**
   * Контактний телефон для зв'язку.
   * Для MVP зберігаємо в SOS, щоб власник міг вказати актуальний контакт.
   */
  @Column({ name: 'contact_phone', type: 'varchar', length: 64, nullable: true })
  contactPhone?: string | null;

  /**
   * Винагорода, якщо власник її вказує.
   */
  @Column({
    name: 'reward_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  rewardAmount?: number | null;

  /**
   * Радіус сповіщення користувачів у метрах.
   */
  @Column({ name: 'search_radius_meters', type: 'integer', default: 3000 })
  searchRadiusMeters: number;

  @Column({
    type: 'varchar',
    length: 32,
    default: ReportStatus.ACTIVE,
  })
  status: ReportStatus;

  @Column({ name: 'close_reason', type: 'varchar', length: 64, nullable: true })
  closeReason?: CloseReason | null;

  @Column({ name: 'close_comment', type: 'text', nullable: true })
  closeComment?: string | null;

  @Column({ name: 'closed_at', type: 'timestamp', nullable: true })
  closedAt?: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
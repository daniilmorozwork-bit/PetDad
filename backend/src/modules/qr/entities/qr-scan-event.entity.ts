import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { QrCodeEntity } from './qr-code.entity';

/**
 * Entity події сканування QR-коду.
 * Фіксує факт відкриття QR-профілю.
 */
@Entity('qr_scan_events')
export class QrScanEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'qr_code_id', type: 'uuid' })
  qrCodeId: string;

  @Column({ name: 'pet_id', type: 'uuid' })
  petId: string;

  /**
   * Широта, якщо користувач дозволив передати геолокацію.
   * На цьому етапі не використовуємо LocationsModule, щоб не тягнути зайву залежність.
   */
  @Column({ type: 'decimal', precision: 9, scale: 6, nullable: true })
  latitude?: number | null;

  /**
   * Довгота, якщо користувач дозволив передати геолокацію.
   */
  @Column({ type: 'decimal', precision: 9, scale: 6, nullable: true })
  longitude?: number | null;

  /**
   * Точність геолокації в метрах.
   */
  @Column({ name: 'accuracy_meters', type: 'integer', nullable: true })
  accuracyMeters?: number | null;

  @Column({ name: 'ip_address', type: 'varchar', length: 64, nullable: true })
  ipAddress?: string | null;

  @Column({ name: 'user_agent', type: 'text', nullable: true })
  userAgent?: string | null;

  @ManyToOne(() => QrCodeEntity, (qrCode) => qrCode.scanEvents, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'qr_code_id' })
  qrCode: QrCodeEntity;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { PetEntity } from '../../pets/entities/pet.entity';
import { QrScanEventEntity } from './qr-scan-event.entity';

/**
 * Entity QR-коду тварини.
 * Один профіль тварини може мати багато QR-кодів за всю історію,
 * але активним має бути тільки один.
 */
@Entity('qr_codes')
export class QrCodeEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * ID тварини, до якої належить QR-код.
   */
  @Column({ name: 'pet_id', type: 'uuid' })
  petId: string;

  /**
   * Унікальний токен QR-коду.
   * Саме він використовується в публічному URL.
   */
  @Column({ type: 'varchar', length: 128, unique: true })
  token: string;

  /**
   * Публічне посилання, яке буде закодовано в QR.
   */
  @Column({ name: 'public_url', type: 'varchar', length: 500 })
  publicUrl: string;

  /**
   * Активність QR-коду.
   * Якщо QR перевипустили, старий стає неактивним.
   */
  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  /**
   * Дата відкликання QR-коду.
   */
  @Column({ name: 'revoked_at', type: 'timestamp', nullable: true })
  revokedAt?: Date | null;

  @ManyToOne(() => PetEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'pet_id' })
  pet: PetEntity;

  @OneToMany(() => QrScanEventEntity, (scanEvent) => scanEvent.qrCode)
  scanEvents: QrScanEventEntity[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
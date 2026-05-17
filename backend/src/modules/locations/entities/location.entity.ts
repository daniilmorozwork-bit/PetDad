import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { LocationSource } from '../../../common/enums/location-source.enum';

/**
 * Entity геолокації.
 * Зберігає координати та PostGIS-точку.
 */
@Entity('locations')
export class LocationEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Широта.
   */
  @Column({ type: 'decimal', precision: 9, scale: 6 })
  latitude: number;

  /**
   * Довгота.
   */
  @Column({ type: 'decimal', precision: 9, scale: 6 })
  longitude: number;

  /**
   * PostGIS-точка.
   * Використовується для пошуку подій у радіусі та межах карти.
   */
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  point: string;

  /**
   * Точність координат у метрах.
   */
  @Column({ name: 'accuracy_meters', type: 'integer', nullable: true })
  accuracyMeters?: number | null;

  /**
   * Людська адреса, якщо вона є.
   * Для MVP можна залишати null.
   */
  @Column({ type: 'varchar', length: 500, nullable: true })
  address?: string | null;

  @Column({ type: 'varchar', length: 120, nullable: true })
  city?: string | null;

  @Column({
    type: 'varchar',
    length: 64,
    default: LocationSource.MANUAL,
  })
  source: LocationSource;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
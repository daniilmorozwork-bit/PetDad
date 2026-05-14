import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { FileEntityType } from '../../../common/enums/file-entity-type.enum';
import { FileStorageProvider } from '../../../common/enums/file-storage-provider.enum';

/**
 * Entity файлу.
 * Зберігає метадані файлу, а не сам файл.
 * Сам файл для MVP лежить у backend/uploads.
 */
@Entity('files')
export class FileEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Користувач, який завантажив файл.
   */
  @Column({ name: 'uploaded_by_id', type: 'uuid' })
  uploadedById: string;

  /**
   * Тип сутності, до якої належить файл.
   */
  @Column({ name: 'entity_type', type: 'varchar', length: 64 })
  entityType: FileEntityType;

  /**
   * ID сутності, до якої прив'язаний файл.
   * Наприклад, ID тварини.
   */
  @Column({ name: 'entity_id', type: 'uuid', nullable: true })
  entityId?: string | null;

  /**
   * Оригінальна назва файлу від користувача.
   */
  @Column({ name: 'original_name', type: 'varchar', length: 255 })
  originalName: string;

  /**
   * Назва файлу після збереження на сервері.
   */
  @Column({ name: 'stored_name', type: 'varchar', length: 255 })
  storedName: string;

  /**
   * MIME-тип файлу.
   */
  @Column({ name: 'mime_type', type: 'varchar', length: 120 })
  mimeType: string;

  /**
   * Розширення файлу.
   */
  @Column({ type: 'varchar', length: 20 })
  extension: string;

  /**
   * Розмір файлу в байтах.
   */
  @Column({ name: 'size_bytes', type: 'integer' })
  sizeBytes: number;

  /**
   * Де зберігається файл.
   */
  @Column({
    name: 'storage_provider',
    type: 'varchar',
    length: 32,
    default: FileStorageProvider.LOCAL,
  })
  storageProvider: FileStorageProvider;

  /**
   * Відносний шлях до файлу на сервері.
   */
  @Column({ type: 'varchar', length: 500 })
  path: string;

  /**
   * URL, який можна використати для показу файлу у frontend.
   */
  @Column({ type: 'varchar', length: 500 })
  url: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  /**
   * Soft delete для файлів.
   */
  @DeleteDateColumn({ name: 'deleted_at', nullable: true })
  deletedAt?: Date | null;
}
import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

import { FileEntity } from '../../files/entities/file.entity';
import { PetEntity } from './pet.entity';

/**
 * Entity фото тварини.
 * Зв'язує профіль тварини з файлом.
 */
@Entity('pet_photos')
@Unique(['petId', 'fileId'])
export class PetPhotoEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'pet_id', type: 'uuid' })
  petId: string;

  @Column({ name: 'file_id', type: 'uuid' })
  fileId: string;

  /**
   * Головне фото тварини.
   * У тварини має бути тільки одне головне фото.
   */
  @Column({ name: 'is_main', type: 'boolean', default: false })
  isMain: boolean;

  /**
   * Порядок відображення фото.
   */
  @Column({ name: 'display_order', type: 'integer', default: 0 })
  displayOrder: number;

  @ManyToOne(() => PetEntity, (pet) => pet.photos, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'pet_id' })
  pet: PetEntity;

  @ManyToOne(() => FileEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'file_id' })
  file: FileEntity;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @DeleteDateColumn({ name: 'deleted_at', nullable: true })
  deletedAt?: Date | null;
}
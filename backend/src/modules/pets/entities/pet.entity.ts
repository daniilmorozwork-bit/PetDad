import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { PetGender } from '../../../common/enums/pet-gender.enum';
import { PetSpecies } from '../../../common/enums/pet-species.enum';
import { PetStatus } from '../../../common/enums/pet-status.enum';
import { UserEntity } from '../../users/entities/user.entity';
import { PetPhotoEntity } from './pet-photo.entity';

/**
 * Entity профілю тварини.
 * Відповідає таблиці pets.
 */
@Entity('pets')
export class PetEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Власник тварини.
   */
  @Column({ name: 'owner_id', type: 'uuid' })
  ownerId: string;

  @ManyToOne(() => UserEntity, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'owner_id' })
  owner: UserEntity;

  /**
   * Фото тварини.
   */
  @OneToMany(() => PetPhotoEntity, (photo) => photo.pet)
  photos: PetPhotoEntity[];

  /**
   * Кличка тварини.
   */
  @Column({ type: 'varchar', length: 120 })
  name: string;

  /**
   * Вид тварини: dog, cat, bird тощо.
   */
  @Column({ type: 'varchar', length: 64 })
  species: PetSpecies;

  /**
   * Порода не завжди відома, тому поле необов’язкове.
   */
  @Column({ type: 'varchar', length: 120, nullable: true })
  breed?: string | null;

  /**
   * Стать тварини.
   */
  @Column({ type: 'varchar', length: 32 })
  gender: PetGender;

  /**
   * Дата народження може бути невідомою.
   */
  @Column({ name: 'birth_date', type: 'date', nullable: true })
  birthDate?: string | null;

  /**
   * Основний колір / окрас.
   */
  @Column({ type: 'varchar', length: 120 })
  color: string;

  /**
   * Вага тварини в кілограмах.
   */
  @Column({ type: 'decimal', precision: 6, scale: 2, nullable: true })
  weightKg?: number | null;

  /**
   * Особливі прикмети: шрам, пляма, нашийник тощо.
   */
  @Column({ name: 'special_marks', type: 'text', nullable: true })
  specialMarks?: string | null;

  /**
   * Номер чіпа, якщо є.
   */
  @Column({ name: 'chip_number', type: 'varchar', length: 120, nullable: true })
  chipNumber?: string | null;

  /**
   * Чи можна показувати обмежений публічний профіль.
   */
  @Column({ name: 'is_public', type: 'boolean', default: true })
  isPublic: boolean;

  /**
   * Поточний статус тварини.
   */
  @Column({
    type: 'varchar',
    length: 32,
    default: PetStatus.OWNED,
  })
  status: PetStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  /**
   * Soft delete.
   * Потрібен, щоб не видаляти історично важливі записи фізично.
   */
  @DeleteDateColumn({ name: 'deleted_at', nullable: true })
  deletedAt?: Date | null;
}
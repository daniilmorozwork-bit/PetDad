import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { UserStatus } from '../../../common/enums/user-status.enum';
import { UserRoleEntity } from '../../roles/entities/user-role.entity';
import { AuthSessionEntity } from '../../auth/entities/auth-session.entity';

/**
 * Entity користувача.
 * Відповідає таблиці users у базі даних.
 */
@Entity('users')
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Email користувача.
   * Має бути унікальним.
   */
  @Column({ type: 'varchar', length: 255, unique: true })
  email: string;

  /**
   * Хеш пароля.
   * select: false означає, що поле не буде автоматично повертатися з БД.
   * Це потрібно, щоб випадково не віддати passwordHash у response.
   */
  @Column({ name: 'password_hash', type: 'varchar', length: 255, select: false })
  passwordHash: string;

  @Column({ name: 'full_name', type: 'varchar', length: 255 })
  fullName: string;

  @Column({ type: 'varchar', length: 32, nullable: true })
  phone?: string | null;

  @Column({
    type: 'varchar',
    length: 32,
    default: UserStatus.ACTIVE,
  })
  status: UserStatus;

  /**
   * Ролі користувача.
   */
  @OneToMany(() => UserRoleEntity, (userRole) => userRole.user)
  userRoles: UserRoleEntity[];

  /**
   * Активні та старі сесії користувача.
   */
  @OneToMany(() => AuthSessionEntity, (session) => session.user)
  authSessions: AuthSessionEntity[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  /**
   * Soft delete.
   * Користувача краще не видаляти фізично одразу.
   */
  @DeleteDateColumn({ name: 'deleted_at', nullable: true })
  deletedAt?: Date | null;
}
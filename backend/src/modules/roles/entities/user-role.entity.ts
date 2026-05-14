import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

import { VerificationStatus } from '../../../common/enums/verification-status.enum';
import { UserEntity } from '../../users/entities/user.entity';
import { RoleEntity } from './role.entity';

/**
 * Зв'язок користувача з роллю.
 * Один користувач може мати кілька ролей.
 */
@Entity('user_roles')
@Unique(['userId', 'roleId'])
export class UserRoleEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ name: 'role_id', type: 'uuid' })
  roleId: string;

  @Column({
    name: 'verification_status',
    type: 'varchar',
    length: 64,
    default: VerificationStatus.NOT_REQUIRED,
  })
  verificationStatus: VerificationStatus;

  @ManyToOne(() => UserEntity, (user) => user.userRoles, {
    onDelete: 'CASCADE',
  })
  user: UserEntity;

  @ManyToOne(() => RoleEntity, (role) => role.userRoles, {
    onDelete: 'CASCADE',
  })
  role: RoleEntity;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
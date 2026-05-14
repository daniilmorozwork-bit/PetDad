import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { RoleCode } from '../../../common/enums/role-code.enum';
import { UserRoleEntity } from './user-role.entity';

/**
 * Entity ролі.
 * Ролі зберігаються в таблиці roles.
 */
@Entity('roles')
export class RoleEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Системний код ролі: user, pet_owner, admin тощо.
   */
  @Column({ type: 'varchar', length: 64, unique: true })
  code: RoleCode;

  /**
   * Людська назва ролі.
   */
  @Column({ type: 'varchar', length: 120 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @OneToMany(() => UserRoleEntity, (userRole) => userRole.role)
  userRoles: UserRoleEntity[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
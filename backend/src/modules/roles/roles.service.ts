import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { RoleCode } from '../../common/enums/role-code.enum';
import { VerificationStatus } from '../../common/enums/verification-status.enum';
import { RoleEntity } from './entities/role.entity';
import { UserRoleEntity } from './entities/user-role.entity';

/**
 * Сервіс ролей.
 * Для MVP створює базові ролі за потреби та призначає роль користувачу.
 */
@Injectable()
export class RolesService {
  constructor(
    @InjectRepository(RoleEntity)
    private readonly rolesRepository: Repository<RoleEntity>,

    @InjectRepository(UserRoleEntity)
    private readonly userRolesRepository: Repository<UserRoleEntity>,
  ) {}

  /**
   * Повертає роль за code.
   * Якщо ролі ще немає в БД, створює її.
   */
  async ensureRole(code: RoleCode): Promise<RoleEntity> {
    const existingRole = await this.rolesRepository.findOne({
      where: { code },
    });

    if (existingRole) {
      return existingRole;
    }

    const role = this.rolesRepository.create({
      code,
      name: this.getDefaultRoleName(code),
      description: `Системна роль ${code}`,
    });

    return this.rolesRepository.save(role);
  }

  /**
   * Призначає роль користувачу, якщо вона ще не призначена.
   */
  async assignRoleToUser(
    userId: string,
    roleCode: RoleCode,
    verificationStatus = VerificationStatus.NOT_REQUIRED,
  ): Promise<UserRoleEntity> {
    const role = await this.ensureRole(roleCode);

    const existingUserRole = await this.userRolesRepository.findOne({
      where: {
        userId,
        roleId: role.id,
      },
      relations: {
        role: true,
      },
    });

    if (existingUserRole) {
      return existingUserRole;
    }

    const userRole = this.userRolesRepository.create({
      userId,
      roleId: role.id,
      verificationStatus,
    });

    return this.userRolesRepository.save(userRole);
  }

  /**
   * Повертає список кодів ролей користувача.
   */
  async getUserRoleCodes(userId: string): Promise<string[]> {
    const userRoles = await this.userRolesRepository.find({
      where: { userId },
      relations: {
        role: true,
      },
    });

    return userRoles.map((userRole) => userRole.role.code);
  }

  /**
   * Людські назви ролей для першого seed-створення.
   */
  private getDefaultRoleName(code: RoleCode): string {
    const names: Record<RoleCode, string> = {
      [RoleCode.USER]: 'Користувач',
      [RoleCode.PET_OWNER]: 'Власник тварини',
      [RoleCode.VOLUNTEER]: 'Волонтер',
      [RoleCode.SHELTER_REPRESENTATIVE]: 'Представник притулку',
      [RoleCode.MODERATOR]: 'Модератор',
      [RoleCode.ADMIN]: 'Адміністратор',
    };

    return names[code];
  }
}
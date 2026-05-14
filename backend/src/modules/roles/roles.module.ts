import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { RoleEntity } from './entities/role.entity';
import { UserRoleEntity } from './entities/user-role.entity';
import { RolesService } from './roles.service';

/**
 * Модуль ролей.
 */
@Module({
  imports: [TypeOrmModule.forFeature([RoleEntity, UserRoleEntity])],
  providers: [RolesService],
  exports: [RolesService],
})
export class RolesModule {}
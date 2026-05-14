import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { RolesModule } from '../roles/roles.module';
import { PetEntity } from './entities/pet.entity';
import { PetsController } from './pets.controller';
import { PetsService } from './pets.service';

/**
 * Модуль профілів тварин.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([PetEntity]),
    RolesModule,
  ],
  controllers: [PetsController],
  providers: [PetsService],
  exports: [PetsService],
})
export class PetsModule {}
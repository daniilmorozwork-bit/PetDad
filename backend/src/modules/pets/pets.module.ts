import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { FilesModule } from '../files/files.module';
import { RolesModule } from '../roles/roles.module';
import { PetPhotoEntity } from './entities/pet-photo.entity';
import { PetEntity } from './entities/pet.entity';
import { PetsController } from './pets.controller';
import { PetsService } from './pets.service';

/**
 * Модуль профілів тварин.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([PetEntity, PetPhotoEntity]),
    RolesModule,
    FilesModule,
  ],
  controllers: [PetsController],
  providers: [PetsService],
  exports: [PetsService],
})
export class PetsModule {}
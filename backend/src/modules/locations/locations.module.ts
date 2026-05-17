import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { LocationEntity } from './entities/location.entity';
import { UserLocationEntity } from './entities/user-location.entity';
import { LocationsService } from './locations.service';

/**
 * Модуль геолокацій.
 */
@Module({
  imports: [TypeOrmModule.forFeature([LocationEntity, UserLocationEntity])],
  providers: [LocationsService],
  exports: [LocationsService],
})
export class LocationsModule {}
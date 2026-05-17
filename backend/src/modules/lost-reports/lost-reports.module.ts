import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { LocationsModule } from '../locations/locations.module';
import { MapEventsModule } from '../map-events/map-events.module';
import { PetsModule } from '../pets/pets.module';
import { LostPetReportEntity } from './entities/lost-pet-report.entity';
import { LostReportsController } from './lost-reports.controller';
import { LostReportsService } from './lost-reports.service';

/**
 * Модуль SOS-оголошень про зникнення тварин.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([LostPetReportEntity]),
    PetsModule,
    LocationsModule,
    MapEventsModule,
  ],
  controllers: [LostReportsController],
  providers: [LostReportsService],
  exports: [LostReportsService],
})
export class LostReportsModule {}
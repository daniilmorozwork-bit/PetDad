import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { LocationsModule } from '../locations/locations.module';
import { LostPetReportEntity } from '../lost-reports/entities/lost-pet-report.entity';
import { MapEventEntity } from '../map-events/entities/map-event.entity';
import { MapEventsModule } from '../map-events/map-events.module';
import { SightingReportEntity } from './entities/sighting-report.entity';
import { SightingsController } from './sightings.controller';
import { SightingsService } from './sightings.service';

/**
 * Модуль свідчень.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([
      SightingReportEntity,
      LostPetReportEntity,
      MapEventEntity,
    ]),
    LocationsModule,
    MapEventsModule,
  ],
  controllers: [SightingsController],
  providers: [SightingsService],
  exports: [SightingsService],
})
export class SightingsModule {}
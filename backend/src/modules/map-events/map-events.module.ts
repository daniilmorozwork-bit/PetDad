import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { LocationsModule } from '../locations/locations.module';
import { MapEventEntity } from './entities/map-event.entity';
import { MapEventsController } from './map-events.controller';
import { MapEventsService } from './map-events.service';

/**
 * Модуль подій карти.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([MapEventEntity]),
    LocationsModule,
  ],
  controllers: [MapEventsController],
  providers: [MapEventsService],
  exports: [MapEventsService],
})
export class MapEventsModule {}
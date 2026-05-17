import { Controller, Get, Param, ParseUUIDPipe, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { MapEventsQueryDto } from './dto/map-events-query.dto';
import { NearbyEventsQueryDto } from './dto/nearby-events-query.dto';
import { MapEventsService } from './map-events.service';

/**
 * Controller для карти.
 */
@ApiTags('map')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('map')
export class MapEventsController {
  constructor(private readonly mapEventsService: MapEventsService) {}

  /**
   * Події карти.
   * Може працювати з межами карти або без них.
   */
  @Get('events')
  findEvents(@Query() query: MapEventsQueryDto) {
    return this.mapEventsService.findEvents(query);
  }

  /**
   * Події поруч із заданими координатами.
   */
  @Get('events/nearby')
  findNearbyEvents(@Query() query: NearbyEventsQueryDto) {
    return this.mapEventsService.findNearbyEvents(query);
  }

  /**
   * Деталі однієї події карти.
   */
  @Get('events/:id')
  getMapEventById(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.mapEventsService.getMapEventById(id);
  }
}
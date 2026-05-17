import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import type { JwtUserPayload } from '../auth/interfaces/jwt-user-payload.interface';
import { CreateSightingDto } from './dto/create-sighting.dto';
import { SightingsService } from './sightings.service';

/**
 * Controller свідчень.
 */
@ApiTags('sightings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class SightingsController {
  constructor(private readonly sightingsService: SightingsService) {}

  /**
   * Створення свідчення до активного SOS.
   */
  @Post('reports/lost/:id/sightings')
  createSighting(
    @Param('id', new ParseUUIDPipe()) lostReportId: string,
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: CreateSightingDto,
  ) {
    return this.sightingsService.createSighting(
      lostReportId,
      user.sub,
      dto,
    );
  }

  /**
   * Список свідчень для SOS.
   */
  @Get('reports/lost/:id/sightings')
  getSightingsByLostReport(
    @Param('id', new ParseUUIDPipe()) lostReportId: string,
  ) {
    return this.sightingsService.getSightingsByLostReport(lostReportId);
  }

  /**
   * Деталі одного свідчення.
   */
  @Get('sightings/:id')
  getSightingById(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.sightingsService.getSightingById(id);
  }
}
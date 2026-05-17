import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import type { JwtUserPayload } from '../auth/interfaces/jwt-user-payload.interface';
import { CloseLostReportDto } from './dto/close-lost-report.dto';
import { CreateLostReportDto } from './dto/create-lost-report.dto';
import { LostReportsQueryDto } from './dto/lost-reports-query.dto';
import { LostReportsService } from './lost-reports.service';

/**
 * Controller SOS-оголошень.
 */
@ApiTags('lost-reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reports/lost')
export class LostReportsController {
  constructor(private readonly lostReportsService: LostReportsService) {}

  /**
   * Створення SOS-оголошення.
   */
  @Post()
  createLostReport(
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: CreateLostReportDto,
  ) {
    return this.lostReportsService.createLostReport(user.sub, dto);
  }

  /**
   * Список SOS-оголошень.
   */
  @Get()
  getLostReports(@Query() query: LostReportsQueryDto) {
    return this.lostReportsService.getLostReports(query);
  }

  /**
   * Деталі SOS-оголошення.
   */
  @Get(':id')
  getLostReportById(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.lostReportsService.getLostReportById(id);
  }

  /**
   * Закриття SOS-оголошення.
   */
  @Patch(':id/close')
  closeLostReport(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: CloseLostReportDto,
  ) {
    return this.lostReportsService.closeLostReport(id, user.sub, dto);
  }
}
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional } from 'class-validator';

import { ReportStatus } from '../../../common/enums/report-status.enum';

/**
 * Query DTO для списку SOS-оголошень.
 */
export class LostReportsQueryDto {
  @ApiPropertyOptional({
    enum: ReportStatus,
    description: 'Фільтр за статусом SOS',
  })
  @IsOptional()
  @IsEnum(ReportStatus)
  status?: ReportStatus;
}
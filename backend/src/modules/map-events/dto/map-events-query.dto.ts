import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, Max, Min } from 'class-validator';

import { MapEventStatus } from '../../../common/enums/map-event-status.enum';
import { MapEventType } from '../../../common/enums/map-event-type.enum';

/**
 * Query DTO для отримання подій у межах карти.
 */
export class MapEventsQueryDto {
  @ApiPropertyOptional({
    example: 50.5000,
    description: 'Північна межа карти',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  north?: number;

  @ApiPropertyOptional({
    example: 50.4000,
    description: 'Південна межа карти',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  south?: number;

  @ApiPropertyOptional({
    example: 30.6000,
    description: 'Східна межа карти',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  east?: number;

  @ApiPropertyOptional({
    example: 30.4000,
    description: 'Західна межа карти',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  west?: number;

  @ApiPropertyOptional({
    enum: MapEventType,
    description: 'Фільтр за типом події',
  })
  @IsOptional()
  @IsEnum(MapEventType)
  type?: MapEventType;

  @ApiPropertyOptional({
    enum: MapEventStatus,
    description: 'Фільтр за статусом події',
  })
  @IsOptional()
  @IsEnum(MapEventStatus)
  status?: MapEventStatus;
}
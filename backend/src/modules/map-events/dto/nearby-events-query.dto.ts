import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, Max, Min } from 'class-validator';

import { MapEventStatus } from '../../../common/enums/map-event-status.enum';
import { MapEventType } from '../../../common/enums/map-event-type.enum';

/**
 * Query DTO для пошуку подій у радіусі.
 */
export class NearbyEventsQueryDto {
  @ApiProperty({
    example: 50.4501,
    description: 'Широта точки, від якої виконується пошук',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({
    example: 30.5234,
    description: 'Довгота точки, від якої виконується пошук',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiPropertyOptional({
    example: 3000,
    description: 'Радіус пошуку в метрах',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(100)
  @Max(50000)
  radiusMeters?: number;

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
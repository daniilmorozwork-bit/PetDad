import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

import { LocationSource } from '../../../common/enums/location-source.enum';

/**
 * DTO для створення геолокації.
 */
export class CreateLocationDto {
  @Type(() => Number)
  @IsNumber({}, { message: 'Широта має бути числом' })
  @Min(-90)
  @Max(90)
  latitude: number;

  @Type(() => Number)
  @IsNumber({}, { message: 'Довгота має бути числом' })
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({}, { message: 'Точність має бути числом' })
  @Min(0)
  @Max(10000)
  accuracyMeters?: number;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsEnum(LocationSource)
  source?: LocationSource;
}
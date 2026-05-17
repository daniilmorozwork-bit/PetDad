import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

import { ConfidenceLevel } from '../../../common/enums/confidence-level.enum';

/**
 * DTO для створення свідчення.
 */
export class CreateSightingDto {
  @ApiProperty({
    example: 50.451,
    description: 'Широта місця, де бачили схожу тварину',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({
    example: 30.525,
    description: 'Довгота місця, де бачили схожу тварину',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiPropertyOptional({
    example: 20,
    description: 'Точність координат у метрах',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10000)
  accuracyMeters?: number;

  @ApiProperty({
    example: '2026-05-17T16:00:00.000Z',
    description: 'Коли бачили схожу тварину',
  })
  @IsDateString()
  seenAt: string;

  @ApiProperty({
    example:
      'Бачив схожу собаку біля зупинки. Була у синьому нашийнику, бігла в напрямку магазину.',
    description: 'Опис свідчення',
  })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({
    enum: ConfidenceLevel,
    example: ConfidenceLevel.HIGH,
    description: 'Рівень впевненості користувача',
  })
  @IsEnum(ConfidenceLevel)
  confidenceLevel: ConfidenceLevel;
}
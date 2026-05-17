import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

/**
 * DTO для створення SOS-оголошення.
 */
export class CreateLostReportDto {
  @ApiProperty({
    example: '07754244-d098-49da-bc3d-8ae8eeee8fd63',
    description: 'ID тварини, яка зникла',
  })
  @IsUUID()
  petId: string;

  @ApiProperty({
    example: 50.4501,
    description: 'Широта місця, де тварину бачили востаннє',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({
    example: 30.5234,
    description: 'Довгота місця, де тварину бачили востаннє',
  })
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiPropertyOptional({
    example: 25,
    description: 'Точність координат у метрах',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(10000)
  accuracyMeters?: number;

  @ApiProperty({
    example: '2026-05-17T15:30:00.000Z',
    description: 'Коли тварину бачили востаннє',
  })
  @IsDateString()
  lastSeenAt: string;

  @ApiProperty({
    example:
      'Собаку бачили біля парку. Була у синьому нашийнику, могла побігти в бік зупинки.',
    description: 'Опис ситуації',
  })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({
    example: '+380501112233',
    description: 'Контактний телефон',
  })
  @IsOptional()
  @IsString()
  contactPhone?: string;

  @ApiPropertyOptional({
    example: 500,
    description: 'Винагорода, якщо є',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(1000000)
  rewardAmount?: number;

  @ApiPropertyOptional({
    example: 3000,
    description: 'Радіус пошуку в метрах',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(500)
  @Max(50000)
  searchRadiusMeters?: number;
}
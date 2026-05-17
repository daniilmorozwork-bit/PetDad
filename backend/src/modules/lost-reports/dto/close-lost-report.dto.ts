import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

import { CloseReason } from '../../../common/enums/close-reason.enum';

/**
 * DTO для закриття SOS-пошуку.
 */
export class CloseLostReportDto {
  @ApiProperty({
    enum: CloseReason,
    example: CloseReason.PET_FOUND,
    description: 'Причина закриття SOS',
  })
  @IsEnum(CloseReason)
  closeReason: CloseReason;

  @ApiPropertyOptional({
    example: 'Тварину знайшли біля сусіднього будинку.',
    description: 'Коментар до закриття пошуку',
  })
  @IsOptional()
  @IsString()
  closeComment?: string;
}
import { Type } from 'class-transformer';
import { IsNumber, IsOptional, Max, Min } from 'class-validator';

/**
 * DTO для фіксації сканування QR-коду.
 * Геолокація необов'язкова, бо користувач може не надати дозвіл.
 */
export class RegisterQrScanDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber({}, { message: 'Широта має бути числом' })
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({}, { message: 'Довгота має бути числом' })
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({}, { message: 'Точність має бути числом' })
  @Min(0)
  @Max(10000)
  accuracyMeters?: number;
}
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

import { DevicePlatform } from '../../../common/enums/device-platform.enum';

/**
 * DTO для реєстрації push-токена пристрою.
 */
export class RegisterPushTokenDto {
  @ApiProperty({
    example: 'fake-fcm-token-for-development',
    description: 'Push token пристрою',
  })
  @IsString()
  @IsNotEmpty()
  token: string;

  @ApiProperty({
    enum: DevicePlatform,
    example: DevicePlatform.ANDROID,
    description: 'Платформа пристрою',
  })
  @IsEnum(DevicePlatform)
  platform: DevicePlatform;

  @ApiPropertyOptional({
    example: 'Samsung Galaxy A52',
    description: 'Назва пристрою',
  })
  @IsOptional()
  @IsString()
  deviceName?: string;
}
import { IsString } from 'class-validator';

/**
 * DTO для оновлення access token через refresh token.
 */
export class RefreshTokenDto {
  @IsString()
  refreshToken: string;
}
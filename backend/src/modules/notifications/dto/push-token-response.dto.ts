/**
 * DTO відповіді після реєстрації push-токена.
 */
export class PushTokenResponseDto {
  id: string;
  userId: string;
  token: string;
  platform: string;
  deviceName?: string | null;
  isActive: boolean;
  lastUsedAt?: string | null;
  createdAt: string;
}
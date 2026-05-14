import { UserResponseDto } from '../../users/dto/user-response.dto';

/**
 * Відповідь backend після login/register/refresh.
 */
export class AuthResponseDto {
  accessToken: string;
  refreshToken: string;
  user: UserResponseDto;
}
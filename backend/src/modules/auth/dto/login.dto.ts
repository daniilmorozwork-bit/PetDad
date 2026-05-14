import { IsEmail, IsString } from 'class-validator';

/**
 * DTO для входу користувача.
 */
export class LoginDto {
  @IsEmail({}, { message: 'Email має некоректний формат' })
  email: string;

  @IsString()
  password: string;
}
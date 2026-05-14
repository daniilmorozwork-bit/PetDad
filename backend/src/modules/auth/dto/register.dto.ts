import { IsEmail, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';

/**
 * DTO для реєстрації користувача.
 * Описує дані, які frontend надсилає на POST /auth/register.
 */
export class RegisterDto {
  @IsEmail({}, { message: 'Email має некоректний формат' })
  email: string;

  @IsString()
  @MinLength(8, { message: 'Пароль має містити мінімум 8 символів' })
  password: string;

  @IsString()
  @IsNotEmpty({ message: 'Імʼя користувача є обовʼязковим' })
  fullName: string;

  @IsOptional()
  @IsString()
  phone?: string;
}
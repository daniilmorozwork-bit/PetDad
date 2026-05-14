/**
 * DTO ролі користувача у відповіді API.
 */
export class UserRoleResponseDto {
  code: string;
  name: string;
  verificationStatus: string;
}

/**
 * Безпечна відповідь з даними користувача.
 * passwordHash тут принципово немає.
 */
export class UserResponseDto {
  id: string;
  email: string;
  fullName: string;
  phone?: string | null;
  status: string;
  roles: UserRoleResponseDto[];
  createdAt: string;
}
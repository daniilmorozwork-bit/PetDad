/**
 * Статус користувача в системі.
 * Використовується для перевірки, чи може користувач входити та створювати контент.
 */
export enum UserStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  BLOCKED = 'blocked',
  DELETED = 'deleted',
}
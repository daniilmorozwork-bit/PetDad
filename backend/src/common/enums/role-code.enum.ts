/**
 * Системні ролі користувачів.
 * Для MVP критичні user, pet_owner, moderator, admin.
 */
export enum RoleCode {
  USER = 'user',
  PET_OWNER = 'pet_owner',
  VOLUNTEER = 'volunteer',
  SHELTER_REPRESENTATIVE = 'shelter_representative',
  MODERATOR = 'moderator',
  ADMIN = 'admin',
}
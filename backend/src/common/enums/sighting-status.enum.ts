/**
 * Статус свідчення.
 * Для MVP основним є active.
 */
export enum SightingStatus {
  ACTIVE = 'active',
  CONFIRMED = 'confirmed',
  REJECTED = 'rejected',
  ARCHIVED = 'archived',
}
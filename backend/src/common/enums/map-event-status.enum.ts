/**
 * Статус події карти.
 * На карті показуються тільки active-події.
 */
export enum MapEventStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  RESOLVED = 'resolved',
  BLOCKED = 'blocked',
  ARCHIVED = 'archived',
}
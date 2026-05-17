/**
 * Тип системного повідомлення.
 */
export enum NotificationType {
  LOST_PET_CREATED = 'lost_pet_created',
  LOST_PET_NEARBY = 'lost_pet_nearby',
  NEW_SIGHTING = 'new_sighting',
  QR_SCANNED = 'qr_scanned',
  REPORT_STATUS_CHANGED = 'report_status_changed',
}
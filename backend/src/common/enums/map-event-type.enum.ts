/**
 * Тип події на карті.
 * Для MVP критичні lost_pet, found_pet і sighting.
 */
export enum MapEventType {
  LOST_PET = 'lost_pet',
  FOUND_PET = 'found_pet',
  SIGHTING = 'sighting',
  QR_SCAN = 'qr_scan',
  HELP_REQUEST = 'help_request',
}
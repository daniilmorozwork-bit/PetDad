/**
 * Джерело створення геолокації.
 * Потрібно, щоб розуміти, звідки взялися координати.
 */
export enum LocationSource {
  USER_CURRENT = 'user_current',
  LOST_REPORT = 'lost_report',
  FOUND_REPORT = 'found_report',
  SIGHTING = 'sighting',
  QR_SCAN = 'qr_scan',
  MANUAL = 'manual',
}
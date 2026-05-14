/**
 * Провайдер зберігання файлів.
 * Для MVP використовуємо локальне сховище.
 */
export enum FileStorageProvider {
  LOCAL = 'local',
  S3 = 's3',
}
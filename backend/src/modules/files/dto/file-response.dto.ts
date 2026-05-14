/**
 * DTO відповіді з даними файлу.
 */
export class FileResponseDto {
  id: string;
  originalName: string;
  storedName: string;
  mimeType: string;
  extension: string;
  sizeBytes: number;
  url: string;
  createdAt: string;
}
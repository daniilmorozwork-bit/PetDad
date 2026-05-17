/**
 * DTO відповіді з геолокацією.
 */
export class LocationResponseDto {
  id: string;
  latitude: number;
  longitude: number;
  accuracyMeters?: number | null;
  address?: string | null;
  city?: string | null;
  source: string;
  createdAt: string;
}
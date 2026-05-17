import { LocationResponseDto } from '../../locations/dto/location-response.dto';

/**
 * DTO події карти.
 */
export class MapEventResponseDto {
  id: string;
  type: string;
  status: string;
  title: string;
  description?: string | null;
  location: LocationResponseDto;
  sourceEntityType?: string | null;
  sourceEntityId?: string | null;
  petId?: string | null;
  distanceMeters?: number | null;
  createdAt: string;
}
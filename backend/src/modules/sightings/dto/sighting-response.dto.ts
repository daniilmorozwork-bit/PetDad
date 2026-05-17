import { LocationResponseDto } from '../../locations/dto/location-response.dto';

/**
 * Скорочені дані про SOS, до якого належить свідчення.
 */
export class SightingLostReportDto {
  id: string;
  status: string;
}

/**
 * Скорочені дані тварини.
 */
export class SightingPetDto {
  id: string;
  name: string;
  species: string;
  breed?: string | null;
  color: string;
  status: string;
  mainPhotoUrl?: string | null;
}

/**
 * DTO відповіді зі свідченням.
 */
export class SightingResponseDto {
  id: string;
  lostReportId: string;
  petId: string;
  reporterId: string;

  status: string;
  confidenceLevel: string;

  seenAt: string;
  description: string;

  location: LocationResponseDto;

  mapEventId?: string | null;

  lostReport?: SightingLostReportDto;
  pet?: SightingPetDto;

  createdAt: string;
  updatedAt: string;
}
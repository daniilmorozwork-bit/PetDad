import { LocationResponseDto } from '../../locations/dto/location-response.dto';

/**
 * Обмежені дані тварини всередині SOS.
 * Не повертаємо chipNumber і приватні поля.
 */
export class LostReportPetDto {
  id: string;
  name: string;
  species: string;
  breed?: string | null;
  gender: string;
  color: string;
  specialMarks?: string | null;
  status: string;
  mainPhotoUrl?: string | null;
}

/**
 * DTO відповіді з SOS-оголошенням.
 */
export class LostReportResponseDto {
  id: string;
  petId: string;
  ownerId: string;
  status: string;

  pet: LostReportPetDto;
  lastSeenLocation: LocationResponseDto;

  lastSeenAt: string;
  description: string;
  contactPhone?: string | null;
  rewardAmount?: number | null;
  searchRadiusMeters: number;

  closeReason?: string | null;
  closeComment?: string | null;
  closedAt?: string | null;

  createdAt: string;
  updatedAt: string;
}
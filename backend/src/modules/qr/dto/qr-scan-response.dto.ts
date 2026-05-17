import { PublicPetProfileDto } from './public-pet-profile.dto';

/**
 * DTO відповіді після сканування QR-коду.
 */
export class QrScanResponseDto {
  success: boolean;
  scanId: string;
  pet: PublicPetProfileDto;
}
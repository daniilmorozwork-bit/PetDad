import { PetPhotoResponseDto } from './pet-photo-response.dto';

/**
 * DTO відповіді з профілем тварини.
 * Entity напряму не повертаємо, щоб контролювати API-відповідь.
 */
export class PetResponseDto {
  id: string;
  ownerId: string;
  name: string;
  species: string;
  breed?: string | null;
  gender: string;
  birthDate?: string | null;
  color: string;
  weightKg?: number | null;
  specialMarks?: string | null;
  chipNumber?: string | null;
  isPublic: boolean;
  status: string;

  /**
   * URL головного фото.
   * Зручно для списку тварин у Flutter.
   */
  mainPhotoUrl?: string | null;

  /**
   * Список фото тварини.
   */
  photos?: PetPhotoResponseDto[];

  createdAt: string;
  updatedAt: string;
}
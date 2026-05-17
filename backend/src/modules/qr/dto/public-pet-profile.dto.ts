/**
 * Безпечний публічний профіль тварини.
 * Тут немає приватних даних власника, chipNumber, телефону, email тощо.
 */
export class PublicPetProfileDto {
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
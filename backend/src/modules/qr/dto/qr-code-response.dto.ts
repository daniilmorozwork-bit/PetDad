/**
 * DTO відповіді з даними QR-коду.
 */
export class QrCodeResponseDto {
  id: string;
  petId: string;
  token: string;
  publicUrl: string;
  isActive: boolean;
  revokedAt?: string | null;
  createdAt: string;
}
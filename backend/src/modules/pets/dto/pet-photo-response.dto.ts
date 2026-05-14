import { FileResponseDto } from '../../files/dto/file-response.dto';

/**
 * DTO відповіді з фото тварини.
 */
export class PetPhotoResponseDto {
  id: string;
  petId: string;
  fileId: string;
  isMain: boolean;
  displayOrder: number;
  file: FileResponseDto;
  createdAt: string;
}
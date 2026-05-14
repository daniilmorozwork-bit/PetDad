import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import type { Express } from 'express';
import { Repository } from 'typeorm';

import { PetStatus } from '../../common/enums/pet-status.enum';
import { RoleCode } from '../../common/enums/role-code.enum';
import { FilesService } from '../files/files.service';
import { RolesService } from '../roles/roles.service';
import { CreatePetDto } from './dto/create-pet.dto';
import { PetPhotoResponseDto } from './dto/pet-photo-response.dto';
import { PetResponseDto } from './dto/pet-response.dto';
import { UpdatePetDto } from './dto/update-pet.dto';
import { PetPhotoEntity } from './entities/pet-photo.entity';
import { PetEntity } from './entities/pet.entity';

/**
 * Сервіс профілів тварин.
 * Тут зберігається основна бізнес-логіка роботи з pets.
 */
@Injectable()
export class PetsService {
  private readonly maxPetPhotos = 5;

  constructor(
    @InjectRepository(PetEntity)
    private readonly petsRepository: Repository<PetEntity>,

    @InjectRepository(PetPhotoEntity)
    private readonly petPhotosRepository: Repository<PetPhotoEntity>,

    private readonly rolesService: RolesService,
    private readonly filesService: FilesService,
  ) {}

  /**
   * Створює профіль тварини для поточного користувача.
   */
  async createPet(ownerId: string, dto: CreatePetDto): Promise<PetResponseDto> {
    this.validateBirthDate(dto.birthDate);

    const pet = this.petsRepository.create({
      ownerId,
      name: dto.name.trim(),
      species: dto.species,
      breed: dto.breed?.trim() || null,
      gender: dto.gender,
      birthDate: dto.birthDate || null,
      color: dto.color.trim(),
      weightKg: dto.weightKg ?? null,
      specialMarks: dto.specialMarks?.trim() || null,
      chipNumber: dto.chipNumber?.trim() || null,
      isPublic: dto.isPublic ?? true,
      status: PetStatus.OWNED,
    });

    const savedPet = await this.petsRepository.save(pet);

    /**
     * Після створення першої тварини користувач отримує роль pet_owner.
     */
    await this.rolesService.assignRoleToUser(ownerId, RoleCode.PET_OWNER);

    return this.toResponseDto(savedPet);
  }

  /**
   * Повертає всіх тварин поточного користувача.
   */
  async getMyPets(ownerId: string): Promise<PetResponseDto[]> {
    const pets = await this.petsRepository.find({
      where: { ownerId },
      relations: {
        photos: {
          file: true,
        },
      },
      order: {
        createdAt: 'DESC',
      },
    });

    return pets.map((pet) => this.toResponseDto(pet));
  }

  /**
   * Повертає тварину за id.
   * Для MVP детальний профіль бачить тільки власник.
   */
  async getPetById(
    petId: string,
    currentUserId: string,
  ): Promise<PetResponseDto> {
    const pet = await this.findPetWithPhotosOrFail(petId);

    this.ensureOwner(pet, currentUserId);

    return this.toResponseDto(pet);
  }

  /**
   * Оновлює профіль тварини.
   */
  async updatePet(
    petId: string,
    currentUserId: string,
    dto: UpdatePetDto,
  ): Promise<PetResponseDto> {
    const pet = await this.findPetOrFail(petId);

    this.ensureOwner(pet, currentUserId);
    this.ensurePetIsEditable(pet);
    this.validateBirthDate(dto.birthDate);

    if (dto.name !== undefined) {
      pet.name = dto.name.trim();
    }

    if (dto.species !== undefined) {
      pet.species = dto.species;
    }

    if (dto.breed !== undefined) {
      pet.breed = dto.breed?.trim() || null;
    }

    if (dto.gender !== undefined) {
      pet.gender = dto.gender;
    }

    if (dto.birthDate !== undefined) {
      pet.birthDate = dto.birthDate || null;
    }

    if (dto.color !== undefined) {
      pet.color = dto.color.trim();
    }

    if (dto.weightKg !== undefined) {
      pet.weightKg = dto.weightKg;
    }

    if (dto.specialMarks !== undefined) {
      pet.specialMarks = dto.specialMarks?.trim() || null;
    }

    if (dto.chipNumber !== undefined) {
      pet.chipNumber = dto.chipNumber?.trim() || null;
    }

    if (dto.isPublic !== undefined) {
      pet.isPublic = dto.isPublic;
    }

    const savedPet = await this.petsRepository.save(pet);
    const petWithPhotos = await this.findPetWithPhotosOrFail(savedPet.id);

    return this.toResponseDto(petWithPhotos);
  }

  /**
   * Архівує профіль тварини.
   */
  async archivePet(
    petId: string,
    currentUserId: string,
  ): Promise<{ success: boolean }> {
    const pet = await this.findPetOrFail(petId);

    this.ensureOwner(pet, currentUserId);

    pet.status = PetStatus.ARCHIVED;

    await this.petsRepository.save(pet);
    await this.petsRepository.softDelete(pet.id);

    return { success: true };
  }

  /**
   * Додає фото до профілю тварини.
   */
  async addPhoto(
    petId: string,
    currentUserId: string,
    file: Express.Multer.File | undefined,
  ): Promise<PetPhotoResponseDto> {
    const pet = await this.findPetOrFail(petId);

    this.ensureOwner(pet, currentUserId);
    this.ensurePetIsEditable(pet);

    const existingPhotosCount = await this.petPhotosRepository.count({
      where: { petId },
    });

    if (existingPhotosCount >= this.maxPetPhotos) {
      throw new UnprocessableEntityException({
        errorCode: 'MAX_FILES_LIMIT_REACHED',
        message: 'До однієї тварини можна додати максимум 5 фото',
      });
    }

    const uploadedFile = await this.filesService.uploadPetPhoto(
      file,
      currentUserId,
      pet.id,
    );

    /**
     * Якщо це перше фото тварини, воно автоматично стає головним.
     */
    const isMain = existingPhotosCount === 0;

    const petPhoto = this.petPhotosRepository.create({
      petId: pet.id,
      fileId: uploadedFile.id,
      isMain,
      displayOrder: existingPhotosCount,
    });

    const savedPhoto = await this.petPhotosRepository.save(petPhoto);

    const photoWithFile = await this.findPhotoOrFail(pet.id, savedPhoto.id);

    return this.toPhotoResponseDto(photoWithFile);
  }

  /**
   * Робить фото головним.
   */
  async setMainPhoto(
    petId: string,
    photoId: string,
    currentUserId: string,
  ): Promise<PetPhotoResponseDto> {
    const pet = await this.findPetOrFail(petId);

    this.ensureOwner(pet, currentUserId);
    this.ensurePetIsEditable(pet);

    const photo = await this.findPhotoOrFail(pet.id, photoId);

    /**
     * Спочатку прибираємо isMain з усіх фото тварини.
     */
    await this.petPhotosRepository.update(
      { petId: pet.id },
      { isMain: false },
    );

    photo.isMain = true;

    const savedPhoto = await this.petPhotosRepository.save(photo);
    const photoWithFile = await this.findPhotoOrFail(pet.id, savedPhoto.id);

    return this.toPhotoResponseDto(photoWithFile);
  }

  /**
   * Видаляє фото тварини.
   */
  async deletePhoto(
    petId: string,
    photoId: string,
    currentUserId: string,
  ): Promise<{ success: boolean }> {
    const pet = await this.findPetOrFail(petId);

    this.ensureOwner(pet, currentUserId);
    this.ensurePetIsEditable(pet);

    const photo = await this.findPhotoOrFail(pet.id, photoId);
    const wasMain = photo.isMain;

    await this.petPhotosRepository.softDelete(photo.id);
    await this.filesService.deleteFile(photo.fileId);

    /**
     * Якщо видалили головне фото, призначаємо головним наступне доступне.
     */
    if (wasMain) {
      const nextPhoto = await this.petPhotosRepository.findOne({
        where: { petId: pet.id },
        relations: { file: true },
        order: { createdAt: 'ASC' },
      });

      if (nextPhoto) {
        nextPhoto.isMain = true;
        await this.petPhotosRepository.save(nextPhoto);
      }
    }

    return { success: true };
  }

  /**
   * Перевіряє, чи тварина належить користувачу.
   * Метод знадобиться іншим модулям: QR, SOS, Files.
   */
  async checkPetOwnership(petId: string, userId: string): Promise<PetEntity> {
    const pet = await this.findPetOrFail(petId);

    this.ensureOwner(pet, userId);

    return pet;
  }

  /**
   * Знаходить тварину або повертає 404.
   */
  private async findPetOrFail(petId: string): Promise<PetEntity> {
    const pet = await this.petsRepository.findOne({
      where: { id: petId },
    });

    if (!pet) {
      throw new NotFoundException({
        errorCode: 'PET_NOT_FOUND',
        message: 'Тварину не знайдено',
      });
    }

    return pet;
  }

  /**
   * Знаходить тварину разом із фото.
   */
  private async findPetWithPhotosOrFail(petId: string): Promise<PetEntity> {
    const pet = await this.petsRepository.findOne({
      where: { id: petId },
      relations: {
        photos: {
          file: true,
        },
      },
    });

    if (!pet) {
      throw new NotFoundException({
        errorCode: 'PET_NOT_FOUND',
        message: 'Тварину не знайдено',
      });
    }

    return pet;
  }

  /**
   * Знаходить фото тварини або повертає 404.
   */
  private async findPhotoOrFail(
    petId: string,
    photoId: string,
  ): Promise<PetPhotoEntity> {
    const photo = await this.petPhotosRepository.findOne({
      where: {
        id: photoId,
        petId,
      },
      relations: {
        file: true,
      },
    });

    if (!photo) {
      throw new NotFoundException({
        errorCode: 'PET_PHOTO_NOT_FOUND',
        message: 'Фото тварини не знайдено',
      });
    }

    return photo;
  }

  /**
   * Перевіряє, що поточний користувач є власником тварини.
   */
  private ensureOwner(pet: PetEntity, currentUserId: string): void {
    if (pet.ownerId !== currentUserId) {
      throw new ForbiddenException({
        errorCode: 'PET_ACCESS_DENIED',
        message: 'Ви не маєте доступу до цієї тварини',
      });
    }
  }

  /**
   * Забороняє редагування архівованої тварини.
   */
  private ensurePetIsEditable(pet: PetEntity): void {
    if (pet.status === PetStatus.ARCHIVED) {
      throw new UnprocessableEntityException({
        errorCode: 'PET_ARCHIVED',
        message: 'Архівований профіль тварини не можна редагувати',
      });
    }
  }

  /**
   * Перевіряє, що дата народження не в майбутньому.
   */
  private validateBirthDate(birthDate?: string): void {
    if (!birthDate) {
      return;
    }

    const date = new Date(birthDate);
    const now = new Date();

    if (date.getTime() > now.getTime()) {
      throw new UnprocessableEntityException({
        errorCode: 'INVALID_BIRTH_DATE',
        message: 'Дата народження не може бути в майбутньому',
      });
    }
  }

  /**
   * Перетворює Entity тварини у DTO.
   */
  private toResponseDto(pet: PetEntity): PetResponseDto {
    const photos = pet.photos?.map((photo) => this.toPhotoResponseDto(photo)) ?? [];
    const mainPhoto = photos.find((photo) => photo.isMain);

    return {
      id: pet.id,
      ownerId: pet.ownerId,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      gender: pet.gender,
      birthDate: pet.birthDate,
      color: pet.color,
      weightKg: pet.weightKg === null ? null : Number(pet.weightKg),
      specialMarks: pet.specialMarks,
      chipNumber: pet.chipNumber,
      isPublic: pet.isPublic,
      status: pet.status,
      mainPhotoUrl: mainPhoto?.file.url ?? null,
      photos,
      createdAt: pet.createdAt.toISOString(),
      updatedAt: pet.updatedAt.toISOString(),
    };
  }

  /**
   * Перетворює Entity фото тварини у DTO.
   */
  private toPhotoResponseDto(photo: PetPhotoEntity): PetPhotoResponseDto {
    return {
      id: photo.id,
      petId: photo.petId,
      fileId: photo.fileId,
      isMain: photo.isMain,
      displayOrder: photo.displayOrder,
      file: this.filesService.toResponseDto(photo.file),
      createdAt: photo.createdAt.toISOString(),
    };
  }
}
import {
  ConflictException,
  GoneException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import type { Request } from 'express';
import { randomBytes } from 'crypto';
import { Repository } from 'typeorm';

import { PetStatus } from '../../common/enums/pet-status.enum';
import { PetEntity } from '../pets/entities/pet.entity';
import { PetsService } from '../pets/pets.service';
import { PublicPetProfileDto } from './dto/public-pet-profile.dto';
import { QrCodeResponseDto } from './dto/qr-code-response.dto';
import { QrScanResponseDto } from './dto/qr-scan-response.dto';
import { RegisterQrScanDto } from './dto/register-qr-scan.dto';
import { QrCodeEntity } from './entities/qr-code.entity';
import { QrScanEventEntity } from './entities/qr-scan-event.entity';

import { NotificationType } from '../../common/enums/notification-type.enum';
import { NotificationsService } from '../notifications/notifications.service';

/**
 * Сервіс QR-кодів.
 * Відповідає за створення QR, перевипуск, публічний профіль і сканування.
 */
@Injectable()
export class QrService {
  constructor(
    @InjectRepository(QrCodeEntity)
    private readonly qrCodesRepository: Repository<QrCodeEntity>,

    @InjectRepository(QrScanEventEntity)
    private readonly qrScanEventsRepository: Repository<QrScanEventEntity>,

    @InjectRepository(PetEntity)
    private readonly petsRepository: Repository<PetEntity>,

    private readonly petsService: PetsService,

    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Створює активний QR-код для тварини.
   * Якщо активний QR вже є, повертає існуючий.
   */
  async generateQrForPet(
    petId: string,
    currentUserId: string,
  ): Promise<QrCodeResponseDto> {
    const pet = await this.petsService.checkPetOwnership(petId, currentUserId);

    this.ensurePetCanHaveQr(pet);

    const existingQr = await this.qrCodesRepository.findOne({
      where: {
        petId: pet.id,
        isActive: true,
      },
    });

    if (existingQr) {
      return this.toQrCodeResponseDto(existingQr);
    }

    const qrCode = await this.createNewQrCode(pet.id);

    return this.toQrCodeResponseDto(qrCode);
  }

  /**
   * Повертає активний QR-код тварини.
   */
  async getActiveQrForPet(
    petId: string,
    currentUserId: string,
  ): Promise<QrCodeResponseDto> {
    const pet = await this.petsService.checkPetOwnership(petId, currentUserId);

    const qrCode = await this.qrCodesRepository.findOne({
      where: {
        petId: pet.id,
        isActive: true,
      },
    });

    if (!qrCode) {
      throw new NotFoundException({
        errorCode: 'QR_CODE_NOT_FOUND',
        message: 'Активний QR-код для цієї тварини не знайдено',
      });
    }

    return this.toQrCodeResponseDto(qrCode);
  }

  /**
   * Перевипускає QR-код.
   * Старий активний QR стає неактивним.
   */
  async reissueQrForPet(
    petId: string,
    currentUserId: string,
  ): Promise<QrCodeResponseDto> {
    const pet = await this.petsService.checkPetOwnership(petId, currentUserId);

    this.ensurePetCanHaveQr(pet);

    const activeQrCodes = await this.qrCodesRepository.find({
      where: {
        petId: pet.id,
        isActive: true,
      },
    });

    for (const qrCode of activeQrCodes) {
      qrCode.isActive = false;
      qrCode.revokedAt = new Date();
      await this.qrCodesRepository.save(qrCode);
    }

    const newQrCode = await this.createNewQrCode(pet.id);

    return this.toQrCodeResponseDto(newQrCode);
  }

  /**
   * Повертає публічний профіль тварини за QR token.
   */
  async getPublicPetProfileByToken(token: string): Promise<PublicPetProfileDto> {
    const qrCode = await this.findQrByTokenWithPet(token);

    this.ensureQrIsActive(qrCode);

    return this.toPublicPetProfileDto(qrCode.pet);
  }

  /**
   * Фіксує сканування QR-коду.
   */
  async registerScan(
    token: string,
    dto: RegisterQrScanDto,
    request: Request,
  ): Promise<QrScanResponseDto> {
    const qrCode = await this.findQrByTokenWithPet(token);

    this.ensureQrIsActive(qrCode);

    const scanEvent = this.qrScanEventsRepository.create({
      qrCodeId: qrCode.id,
      petId: qrCode.petId,
      latitude: dto.latitude ?? null,
      longitude: dto.longitude ?? null,
      accuracyMeters: dto.accuracyMeters ?? null,
      ipAddress: this.getRequestIp(request),
      userAgent: request.headers['user-agent'] ?? null,
    });

    const savedScanEvent = await this.qrScanEventsRepository.save(scanEvent);

        /**
     * Повідомляємо власника тварини про сканування QR.
     */
    await this.notificationsService.createNotification({
      recipientId: qrCode.pet.ownerId,
      type: NotificationType.QR_SCANNED,
      title: 'QR-код тварини проскановано',
      body: `QR-код тварини ${qrCode.pet.name} було відкрито.`,
      entityType: 'qr_scan_event',
      entityId: savedScanEvent.id,
      data: {
        petId: qrCode.petId,
        qrCodeId: qrCode.id,
        latitude: dto.latitude ?? null,
        longitude: dto.longitude ?? null,
      },
    });

    return {
      success: true,
      scanId: savedScanEvent.id,
      pet: this.toPublicPetProfileDto(qrCode.pet),
    };
  }

  /**
   * Створює новий QR-код.
   */
  private async createNewQrCode(petId: string): Promise<QrCodeEntity> {
    const token = await this.generateUniqueToken();
    const publicUrl = this.buildPublicUrl(token);

    const qrCode = this.qrCodesRepository.create({
      petId,
      token,
      publicUrl,
      isActive: true,
      revokedAt: null,
    });

    return this.qrCodesRepository.save(qrCode);
  }

  /**
   * Генерує унікальний токен.
   */
  private async generateUniqueToken(): Promise<string> {
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const token = randomBytes(32).toString('hex');

      const existingQrCode = await this.qrCodesRepository.findOne({
        where: { token },
      });

      if (!existingQrCode) {
        return token;
      }
    }

    throw new ConflictException({
      errorCode: 'QR_TOKEN_GENERATION_FAILED',
      message: 'Не вдалося згенерувати унікальний QR-токен',
    });
  }

  /**
   * Формує публічний URL для QR-коду.
   */
  private buildPublicUrl(token: string): string {
    const baseUrl = process.env.APP_PUBLIC_URL || 'http://localhost:3000';

    return `${baseUrl}/api/v1/qr/${token}`;
  }

  /**
   * Шукає QR за токеном разом із твариними фото.
   */
  private async findQrByTokenWithPet(token: string): Promise<QrCodeEntity> {
    const qrCode = await this.qrCodesRepository.findOne({
      where: { token },
      relations: {
        pet: {
          photos: {
            file: true,
          },
        },
      },
    });

    if (!qrCode) {
      throw new NotFoundException({
        errorCode: 'QR_CODE_NOT_FOUND',
        message: 'QR-код не знайдено',
      });
    }

    return qrCode;
  }

  /**
   * Перевіряє, чи QR-код активний.
   */
  private ensureQrIsActive(qrCode: QrCodeEntity): void {
    if (!qrCode.isActive || qrCode.revokedAt) {
      throw new GoneException({
        errorCode: 'QR_CODE_INACTIVE',
        message: 'QR-код більше неактивний',
      });
    }
  }

  /**
   * Забороняє QR для архівованої тварини.
   */
  private ensurePetCanHaveQr(pet: PetEntity): void {
    if (pet.status === PetStatus.ARCHIVED) {
      throw new UnprocessableEntityException({
        errorCode: 'PET_ARCHIVED',
        message: 'Для архівованої тварини не можна створити QR-код',
      });
    }
  }

  /**
   * Перетворює QR Entity у DTO.
   */
  private toQrCodeResponseDto(qrCode: QrCodeEntity): QrCodeResponseDto {
    return {
      id: qrCode.id,
      petId: qrCode.petId,
      token: qrCode.token,
      publicUrl: qrCode.publicUrl,
      isActive: qrCode.isActive,
      revokedAt: qrCode.revokedAt?.toISOString() ?? null,
      createdAt: qrCode.createdAt.toISOString(),
    };
  }

  /**
   * Перетворює PetEntity у безпечний публічний профіль.
   */
  private toPublicPetProfileDto(pet: PetEntity): PublicPetProfileDto {
    const photos = pet.photos ?? [];
    const mainPhoto = photos.find((photo) => photo.isMain);
    const fallbackPhoto = photos[0];

    return {
      id: pet.id,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      gender: pet.gender,
      color: pet.color,
      specialMarks: pet.specialMarks,
      status: pet.status,
      mainPhotoUrl:
        mainPhoto?.file?.url ?? fallbackPhoto?.file?.url ?? null,
    };
  }

  /**
   * Отримує IP-адресу запиту.
   */
  private getRequestIp(request: Request): string | null {
    const forwardedFor = request.headers['x-forwarded-for'];

    if (Array.isArray(forwardedFor)) {
      return forwardedFor[0] ?? null;
    }

    if (typeof forwardedFor === 'string') {
      return forwardedFor.split(',')[0]?.trim() || null;
    }

    return request.ip ?? null;
  }
}
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { LocationSource } from '../../common/enums/location-source.enum';
import { MapEventStatus } from '../../common/enums/map-event-status.enum';
import { MapEventType } from '../../common/enums/map-event-type.enum';
import { PetStatus } from '../../common/enums/pet-status.enum';
import { ReportStatus } from '../../common/enums/report-status.enum';
import { LocationsService } from '../locations/locations.service';
import { MapEventsService } from '../map-events/map-events.service';
import { PetEntity } from '../pets/entities/pet.entity';
import { PetsService } from '../pets/pets.service';
import { CloseLostReportDto } from './dto/close-lost-report.dto';
import { CreateLostReportDto } from './dto/create-lost-report.dto';
import { LostReportResponseDto } from './dto/lost-report-response.dto';
import { LostReportsQueryDto } from './dto/lost-reports-query.dto';
import { LostPetReportEntity } from './entities/lost-pet-report.entity';

import { NotificationType } from '../../common/enums/notification-type.enum';
import { NotificationsService } from '../notifications/notifications.service';

/**
 * Сервіс SOS-оголошень про зникнення тварин.
 */
@Injectable()
export class LostReportsService {
  private readonly sourceEntityType = 'lost_pet_report';

  constructor(
    @InjectRepository(LostPetReportEntity)
    private readonly lostReportsRepository: Repository<LostPetReportEntity>,

    private readonly petsService: PetsService,
    private readonly locationsService: LocationsService,
    private readonly mapEventsService: MapEventsService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Створює SOS-оголошення.
   */
  async createLostReport(
    currentUserId: string,
    dto: CreateLostReportDto,
  ): Promise<LostReportResponseDto> {
    const pet = await this.petsService.checkPetOwnership(
      dto.petId,
      currentUserId,
    );

    this.ensurePetCanBeReportedLost(pet);
    await this.ensureNoActiveLostReport(dto.petId);
    this.validateLastSeenAt(dto.lastSeenAt);

    const location = await this.locationsService.createLocation({
      latitude: dto.latitude,
      longitude: dto.longitude,
      accuracyMeters: dto.accuracyMeters,
      source: LocationSource.LOST_REPORT,
    });

    const lostReport = this.lostReportsRepository.create({
      petId: pet.id,
      ownerId: currentUserId,
      lastSeenLocationId: location.id,
      lastSeenAt: new Date(dto.lastSeenAt),
      description: dto.description.trim(),
      contactPhone: dto.contactPhone?.trim() || null,
      rewardAmount: dto.rewardAmount ?? null,
      searchRadiusMeters: dto.searchRadiusMeters ?? 3000,
      status: ReportStatus.ACTIVE,
      closeReason: null,
      closeComment: null,
      closedAt: null,
    });

    const savedReport = await this.lostReportsRepository.save(lostReport);

    /**
     * Після створення SOS статус тварини змінюється на lost.
     */
    await this.petsService.changePetStatus(pet.id, PetStatus.LOST);

    /**
     * Створюємо подію карти.
     * Саме її буде читати MapScreen у Flutter.
     */
    const mapEvent = await this.mapEventsService.createMapEvent({
      type: MapEventType.LOST_PET,
      title: `Зникла тварина: ${pet.name}`,
      description: dto.description.trim(),
      locationId: location.id,
      sourceEntityType: this.sourceEntityType,
      sourceEntityId: savedReport.id,
      petId: pet.id,
      createdById: currentUserId,
    });

    /**
     * Створюємо внутрішнє повідомлення власнику.
     * На цьому етапі це підтвердження створення SOS.
     */
    await this.notificationsService.createNotification({
      recipientId: currentUserId,
      type: NotificationType.LOST_PET_CREATED,
      title: 'SOS-оголошення створено',
      body: `SOS-пошук для тварини ${pet.name} опубліковано.`,
      entityType: this.sourceEntityType,
      entityId: savedReport.id,
      data: {
        petId: pet.id,
        mapEventId: mapEvent.id,
        searchRadiusMeters: savedReport.searchRadiusMeters,
      },
      });

    return this.getLostReportById(savedReport.id);
  }

  /**
   * Повертає список SOS-оголошень.
   * За замовчуванням повертає active.
   */
  async getLostReports(
    query: LostReportsQueryDto,
  ): Promise<LostReportResponseDto[]> {
    const status = query.status ?? ReportStatus.ACTIVE;

    const reports = await this.lostReportsRepository.find({
      where: { status },
      relations: {
        pet: {
          photos: {
            file: true,
          },
        },
        lastSeenLocation: true,
      },
      order: {
        createdAt: 'DESC',
      },
    });

    return reports.map((report) => this.toResponseDto(report));
  }

  /**
   * Повертає SOS за id.
   */
  async getLostReportById(id: string): Promise<LostReportResponseDto> {
    const report = await this.findReportWithRelationsOrFail(id);

    return this.toResponseDto(report);
  }

  /**
   * Закриває активне SOS-оголошення.
   */
  async closeLostReport(
    reportId: string,
    currentUserId: string,
    dto: CloseLostReportDto,
  ): Promise<LostReportResponseDto> {
    const report = await this.findReportWithRelationsOrFail(reportId);

    this.ensureOwner(report, currentUserId);
    this.ensureReportIsActive(report);

    report.status = ReportStatus.CLOSED;
    report.closeReason = dto.closeReason;
    report.closeComment = dto.closeComment?.trim() || null;
    report.closedAt = new Date();

    await this.lostReportsRepository.save(report);

    /**
     * Після закриття SOS повертаємо статус тварини до owned.
     * Пізніше можна зробити складнішу логіку для found.
     */
    await this.petsService.changePetStatus(report.petId, PetStatus.OWNED);

    /**
     * Подія карти більше не має бути активною.
     */
    await this.mapEventsService.updateStatusBySource(
      this.sourceEntityType,
      report.id,
      MapEventStatus.RESOLVED,
    );

    return this.getLostReportById(report.id);
  }

  /**
   * Перевіряє, що тварина може отримати SOS.
   */
  private ensurePetCanBeReportedLost(pet: PetEntity): void {
    if (pet.status === PetStatus.ARCHIVED) {
      throw new UnprocessableEntityException({
        errorCode: 'PET_ARCHIVED',
        message: 'Для архівованої тварини не можна створити SOS',
      });
    }

    if (pet.status === PetStatus.LOST) {
      throw new UnprocessableEntityException({
        errorCode: 'PET_ALREADY_LOST',
        message: 'Ця тварина вже має статус lost',
      });
    }
  }

  /**
   * Забороняє створювати друге активне SOS для тієї ж тварини.
   */
  private async ensureNoActiveLostReport(petId: string): Promise<void> {
    const activeReport = await this.lostReportsRepository.findOne({
      where: {
        petId,
        status: ReportStatus.ACTIVE,
      },
    });

    if (activeReport) {
      throw new UnprocessableEntityException({
        errorCode: 'ACTIVE_LOST_REPORT_EXISTS',
        message: 'Для цієї тварини вже існує активне SOS-оголошення',
      });
    }
  }

  /**
   * Дата останнього спостереження не може бути в майбутньому.
   */
  private validateLastSeenAt(lastSeenAt: string): void {
    const date = new Date(lastSeenAt);

    if (Number.isNaN(date.getTime())) {
      throw new UnprocessableEntityException({
        errorCode: 'INVALID_LAST_SEEN_AT',
        message: 'Некоректна дата останнього спостереження',
      });
    }

    if (date.getTime() > Date.now()) {
      throw new UnprocessableEntityException({
        errorCode: 'LAST_SEEN_AT_IN_FUTURE',
        message: 'Дата останнього спостереження не може бути в майбутньому',
      });
    }
  }

  private ensureOwner(
    report: LostPetReportEntity,
    currentUserId: string,
  ): void {
    if (report.ownerId !== currentUserId) {
      throw new ForbiddenException({
        errorCode: 'LOST_REPORT_ACCESS_DENIED',
        message: 'Ви не можете закрити чуже SOS-оголошення',
      });
    }
  }

  private ensureReportIsActive(report: LostPetReportEntity): void {
    if (report.status !== ReportStatus.ACTIVE) {
      throw new UnprocessableEntityException({
        errorCode: 'LOST_REPORT_NOT_ACTIVE',
        message: 'SOS-оголошення вже неактивне',
      });
    }
  }

  private async findReportWithRelationsOrFail(
    id: string,
  ): Promise<LostPetReportEntity> {
    const report = await this.lostReportsRepository.findOne({
      where: { id },
      relations: {
        pet: {
          photos: {
            file: true,
          },
        },
        lastSeenLocation: true,
      },
    });

    if (!report) {
      throw new NotFoundException({
        errorCode: 'LOST_REPORT_NOT_FOUND',
        message: 'SOS-оголошення не знайдено',
      });
    }

    return report;
  }

  /**
   * Перетворює Entity у DTO.
   */
  private toResponseDto(report: LostPetReportEntity): LostReportResponseDto {
    const photos = report.pet.photos ?? [];
    const mainPhoto = photos.find((photo) => photo.isMain);
    const fallbackPhoto = photos[0];

    return {
      id: report.id,
      petId: report.petId,
      ownerId: report.ownerId,
      status: report.status,

      pet: {
        id: report.pet.id,
        name: report.pet.name,
        species: report.pet.species,
        breed: report.pet.breed,
        gender: report.pet.gender,
        color: report.pet.color,
        specialMarks: report.pet.specialMarks,
        status: report.pet.status,
        mainPhotoUrl:
          mainPhoto?.file?.url ?? fallbackPhoto?.file?.url ?? null,
      },

      lastSeenLocation: this.locationsService.toResponseDto(
        report.lastSeenLocation,
      ),

      lastSeenAt: report.lastSeenAt.toISOString(),
      description: report.description,
      contactPhone: report.contactPhone ?? null,
      rewardAmount:
        report.rewardAmount === null || report.rewardAmount === undefined
          ? null
          : Number(report.rewardAmount),
      searchRadiusMeters: report.searchRadiusMeters,

      closeReason: report.closeReason ?? null,
      closeComment: report.closeComment ?? null,
      closedAt: report.closedAt?.toISOString() ?? null,

      createdAt: report.createdAt.toISOString(),
      updatedAt: report.updatedAt.toISOString(),
    };
  }
}
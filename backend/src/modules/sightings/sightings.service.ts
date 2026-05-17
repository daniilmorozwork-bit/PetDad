import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { LocationSource } from '../../common/enums/location-source.enum';
import { MapEventType } from '../../common/enums/map-event-type.enum';
import { ReportStatus } from '../../common/enums/report-status.enum';
import { SightingStatus } from '../../common/enums/sighting-status.enum';
import { LocationsService } from '../locations/locations.service';
import { LostPetReportEntity } from '../lost-reports/entities/lost-pet-report.entity';
import { MapEventsService } from '../map-events/map-events.service';
import { CreateSightingDto } from './dto/create-sighting.dto';
import { SightingResponseDto } from './dto/sighting-response.dto';
import { SightingReportEntity } from './entities/sighting-report.entity';

/**
 * Сервіс свідчень.
 * Відповідає за створення свідчень до активного SOS і створення подій карти.
 */
@Injectable()
export class SightingsService {
  private readonly sourceEntityType = 'sighting_report';

  constructor(
    @InjectRepository(SightingReportEntity)
    private readonly sightingsRepository: Repository<SightingReportEntity>,

    @InjectRepository(LostPetReportEntity)
    private readonly lostReportsRepository: Repository<LostPetReportEntity>,

    private readonly locationsService: LocationsService,
    private readonly mapEventsService: MapEventsService,
  ) {}

  /**
   * Створює свідчення до активного SOS-оголошення.
   */
  async createSighting(
    lostReportId: string,
    reporterId: string,
    dto: CreateSightingDto,
  ): Promise<SightingResponseDto> {
    const lostReport = await this.findActiveLostReportOrFail(lostReportId);

    /**
     * Власник теж може додати свідчення вручну, але для MVP краще заборонити.
     * Інакше власник сам собі буде створювати "свідчення", і цей хаос нам не потрібен.
     */
    if (lostReport.ownerId === reporterId) {
      throw new ForbiddenException({
        errorCode: 'OWNER_CANNOT_CREATE_SIGHTING',
        message: 'Власник не може додавати свідчення до власного SOS',
      });
    }

    this.validateSeenAt(dto.seenAt, lostReport.lastSeenAt);

    const location = await this.locationsService.createLocation({
      latitude: dto.latitude,
      longitude: dto.longitude,
      accuracyMeters: dto.accuracyMeters,
      source: LocationSource.SIGHTING,
    });

    const sighting = this.sightingsRepository.create({
      lostReportId: lostReport.id,
      petId: lostReport.petId,
      reporterId,
      locationId: location.id,
      seenAt: new Date(dto.seenAt),
      description: dto.description.trim(),
      confidenceLevel: dto.confidenceLevel,
      status: SightingStatus.ACTIVE,
      mapEventId: null,
    });

    const savedSighting = await this.sightingsRepository.save(sighting);

    const mapEvent = await this.mapEventsService.createMapEvent({
      type: MapEventType.SIGHTING,
      title: `Свідчення щодо тварини: ${lostReport.pet.name}`,
      description: dto.description.trim(),
      locationId: location.id,
      sourceEntityType: this.sourceEntityType,
      sourceEntityId: savedSighting.id,
      petId: lostReport.petId,
      createdById: reporterId,
    });

    savedSighting.mapEventId = mapEvent.id;
    await this.sightingsRepository.save(savedSighting);

    return this.getSightingById(savedSighting.id);
  }

  /**
   * Повертає свідчення для конкретного SOS.
   */
  async getSightingsByLostReport(
    lostReportId: string,
  ): Promise<SightingResponseDto[]> {
    const lostReport = await this.lostReportsRepository.findOne({
      where: { id: lostReportId },
    });

    if (!lostReport) {
      throw new NotFoundException({
        errorCode: 'LOST_REPORT_NOT_FOUND',
        message: 'SOS-оголошення не знайдено',
      });
    }

    const sightings = await this.sightingsRepository.find({
      where: {
        lostReportId,
      },
      relations: {
        location: true,
        pet: {
          photos: {
            file: true,
          },
        },
        lostReport: true,
      },
      order: {
        createdAt: 'DESC',
      },
    });

    return sightings.map((sighting) => this.toResponseDto(sighting));
  }

  /**
   * Повертає одне свідчення за id.
   */
  async getSightingById(id: string): Promise<SightingResponseDto> {
    const sighting = await this.sightingsRepository.findOne({
      where: { id },
      relations: {
        location: true,
        pet: {
          photos: {
            file: true,
          },
        },
        lostReport: true,
      },
    });

    if (!sighting) {
      throw new NotFoundException({
        errorCode: 'SIGHTING_NOT_FOUND',
        message: 'Свідчення не знайдено',
      });
    }

    return this.toResponseDto(sighting);
  }

  /**
   * Шукає активне SOS разом із даними тварини.
   */
  private async findActiveLostReportOrFail(
    lostReportId: string,
  ): Promise<LostPetReportEntity> {
    const lostReport = await this.lostReportsRepository.findOne({
      where: {
        id: lostReportId,
        status: ReportStatus.ACTIVE,
      },
      relations: {
        pet: {
          photos: {
            file: true,
          },
        },
      },
    });

    if (!lostReport) {
      throw new NotFoundException({
        errorCode: 'ACTIVE_LOST_REPORT_NOT_FOUND',
        message: 'Активне SOS-оголошення не знайдено',
      });
    }

    return lostReport;
  }

  /**
   * Перевіряє дату свідчення.
   */
  private validateSeenAt(seenAt: string, lastSeenAt: Date): void {
    const seenDate = new Date(seenAt);

    if (Number.isNaN(seenDate.getTime())) {
      throw new UnprocessableEntityException({
        errorCode: 'INVALID_SEEN_AT',
        message: 'Некоректна дата свідчення',
      });
    }

    if (seenDate.getTime() > Date.now()) {
      throw new UnprocessableEntityException({
        errorCode: 'SEEN_AT_IN_FUTURE',
        message: 'Дата свідчення не може бути в майбутньому',
      });
    }

    /**
     * Свідчення не має бути раніше часу зникнення.
     */
    if (seenDate.getTime() < lastSeenAt.getTime()) {
      throw new UnprocessableEntityException({
        errorCode: 'SEEN_AT_BEFORE_LAST_SEEN',
        message: 'Дата свідчення не може бути раніше часу зникнення',
      });
    }
  }

  /**
   * Перетворює Entity у DTO.
   */
  private toResponseDto(sighting: SightingReportEntity): SightingResponseDto {
    const photos = sighting.pet?.photos ?? [];
    const mainPhoto = photos.find((photo) => photo.isMain);
    const fallbackPhoto = photos[0];

    return {
      id: sighting.id,
      lostReportId: sighting.lostReportId,
      petId: sighting.petId,
      reporterId: sighting.reporterId,

      status: sighting.status,
      confidenceLevel: sighting.confidenceLevel,

      seenAt: sighting.seenAt.toISOString(),
      description: sighting.description,

      location: this.locationsService.toResponseDto(sighting.location),

      mapEventId: sighting.mapEventId ?? null,

      lostReport: sighting.lostReport
        ? {
            id: sighting.lostReport.id,
            status: sighting.lostReport.status,
          }
        : undefined,

      pet: sighting.pet
        ? {
            id: sighting.pet.id,
            name: sighting.pet.name,
            species: sighting.pet.species,
            breed: sighting.pet.breed,
            color: sighting.pet.color,
            status: sighting.pet.status,
            mainPhotoUrl:
              mainPhoto?.file?.url ?? fallbackPhoto?.file?.url ?? null,
          }
        : undefined,

      createdAt: sighting.createdAt.toISOString(),
      updatedAt: sighting.updatedAt.toISOString(),
    };
  }
}
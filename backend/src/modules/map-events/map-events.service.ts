import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';

import { MapEventStatus } from '../../common/enums/map-event-status.enum';
import { MapEventType } from '../../common/enums/map-event-type.enum';
import { LocationEntity } from '../locations/entities/location.entity';
import { LocationsService } from '../locations/locations.service';
import { MapEventResponseDto } from './dto/map-event-response.dto';
import { MapEventsQueryDto } from './dto/map-events-query.dto';
import { NearbyEventsQueryDto } from './dto/nearby-events-query.dto';
import { MapEventEntity } from './entities/map-event.entity';

interface CreateMapEventInput {
  type: MapEventType;
  title: string;
  description?: string | null;
  locationId: string;
  sourceEntityType?: string | null;
  sourceEntityId?: string | null;
  petId?: string | null;
  createdById?: string | null;
  expiresAt?: Date | null;
}

/**
 * Сервіс подій карти.
 * Надалі LostReportsModule, FoundReportsModule і SightingsModule будуть створювати map_events через цей сервіс.
 */
@Injectable()
export class MapEventsService {
  constructor(
    @InjectRepository(MapEventEntity)
    private readonly mapEventsRepository: Repository<MapEventEntity>,

    @InjectDataSource()
    private readonly dataSource: DataSource,

    private readonly locationsService: LocationsService,
  ) {}

  /**
   * Створює подію карти.
   * Цей метод потрібен майбутнім бізнес-модулям.
   */
  async createMapEvent(input: CreateMapEventInput): Promise<MapEventResponseDto> {
    const event = this.mapEventsRepository.create({
      type: input.type,
      status: MapEventStatus.ACTIVE,
      title: input.title,
      description: input.description ?? null,
      locationId: input.locationId,
      sourceEntityType: input.sourceEntityType ?? null,
      sourceEntityId: input.sourceEntityId ?? null,
      petId: input.petId ?? null,
      createdById: input.createdById ?? null,
      expiresAt: input.expiresAt ?? null,
    });

    const savedEvent = await this.mapEventsRepository.save(event);

    return this.getMapEventById(savedEvent.id);
  }

  /**
   * Повертає події карти.
   * Якщо передано межі карти, шукає події всередині цих меж.
   */
  async findEvents(query: MapEventsQueryDto): Promise<MapEventResponseDto[]> {
    const status = query.status ?? MapEventStatus.ACTIVE;

    const params: unknown[] = [status];
    let paramIndex = 2;

    let sql = `
      SELECT
        e.id AS "id",
        e.type AS "type",
        e.status AS "status",
        e.title AS "title",
        e.description AS "description",
        e.source_entity_type AS "sourceEntityType",
        e.source_entity_id AS "sourceEntityId",
        e.pet_id AS "petId",
        e.created_at AS "createdAt",

        l.id AS "locationId",
        l.latitude AS "latitude",
        l.longitude AS "longitude",
        l.accuracy_meters AS "accuracyMeters",
        l.address AS "address",
        l.city AS "city",
        l.source AS "locationSource",
        l.created_at AS "locationCreatedAt"

      FROM map_events e
      JOIN locations l ON l.id = e.location_id
      WHERE e.status = $1
    `;

    if (query.type) {
      sql += ` AND e.type = $${paramIndex}`;
      params.push(query.type);
      paramIndex += 1;
    }

    const hasBounds =
      query.north !== undefined &&
      query.south !== undefined &&
      query.east !== undefined &&
      query.west !== undefined;

    if (hasBounds) {
      sql += `
        AND ST_Intersects(
          l.point::geometry,
          ST_MakeEnvelope(
            $${paramIndex},
            $${paramIndex + 1},
            $${paramIndex + 2},
            $${paramIndex + 3},
            4326
          )
        )
      `;

      /**
       * ST_MakeEnvelope очікує порядок:
       * west, south, east, north.
       */
      params.push(query.west, query.south, query.east, query.north);
      paramIndex += 4;
    }

    sql += ` ORDER BY e.created_at DESC LIMIT 200`;

    const rows = await this.dataSource.query(sql, params);

    return rows.map((row) => this.mapRawRowToResponseDto(row));
  }

  /**
   * Пошук подій у радіусі.
   */
  async findNearbyEvents(
    query: NearbyEventsQueryDto,
  ): Promise<MapEventResponseDto[]> {
    const radiusMeters = query.radiusMeters ?? 3000;
    const status = query.status ?? MapEventStatus.ACTIVE;

    const params: unknown[] = [
      query.longitude,
      query.latitude,
      radiusMeters,
      status,
    ];

    let sql = `
      SELECT
        e.id AS "id",
        e.type AS "type",
        e.status AS "status",
        e.title AS "title",
        e.description AS "description",
        e.source_entity_type AS "sourceEntityType",
        e.source_entity_id AS "sourceEntityId",
        e.pet_id AS "petId",
        e.created_at AS "createdAt",

        l.id AS "locationId",
        l.latitude AS "latitude",
        l.longitude AS "longitude",
        l.accuracy_meters AS "accuracyMeters",
        l.address AS "address",
        l.city AS "city",
        l.source AS "locationSource",
        l.created_at AS "locationCreatedAt",

        ST_Distance(
          l.point,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) AS "distanceMeters"

      FROM map_events e
      JOIN locations l ON l.id = e.location_id
      WHERE ST_DWithin(
        l.point,
        ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
        $3
      )
      AND e.status = $4
    `;

    if (query.type) {
      sql += ` AND e.type = $5`;
      params.push(query.type);
    }

    sql += ` ORDER BY "distanceMeters" ASC LIMIT 100`;

    const rows = await this.dataSource.query(sql, params);

    return rows.map((row) => this.mapRawRowToResponseDto(row));
  }

  /**
   * Повертає одну подію карти.
   */
  async getMapEventById(id: string): Promise<MapEventResponseDto> {
    const event = await this.mapEventsRepository.findOne({
      where: { id },
      relations: {
        location: true,
      },
    });

    if (!event) {
      throw new NotFoundException({
        errorCode: 'MAP_EVENT_NOT_FOUND',
        message: 'Подію карти не знайдено',
      });
    }

    return this.toResponseDto(event);
  }

  /**
   * Оновлює статус події за джерелом.
   * Буде потрібно для закриття SOS.
   */
  async updateStatusBySource(
    sourceEntityType: string,
    sourceEntityId: string,
    status: MapEventStatus,
  ): Promise<void> {
    await this.mapEventsRepository.update(
      {
        sourceEntityType,
        sourceEntityId,
      },
      {
        status,
      },
    );
  }

  private toResponseDto(event: MapEventEntity): MapEventResponseDto {
    return {
      id: event.id,
      type: event.type,
      status: event.status,
      title: event.title,
      description: event.description ?? null,
      sourceEntityType: event.sourceEntityType ?? null,
      sourceEntityId: event.sourceEntityId ?? null,
      petId: event.petId ?? null,
      distanceMeters: null,
      location: this.locationsService.toResponseDto(event.location),
      createdAt: event.createdAt.toISOString(),
    };
  }

  /**
   * Мапінг raw SQL-рядка в DTO.
   */
  private mapRawRowToResponseDto(row: any): MapEventResponseDto {
    return {
      id: row.id,
      type: row.type,
      status: row.status,
      title: row.title,
      description: row.description ?? null,
      sourceEntityType: row.sourceEntityType ?? null,
      sourceEntityId: row.sourceEntityId ?? null,
      petId: row.petId ?? null,
      distanceMeters:
        row.distanceMeters === undefined || row.distanceMeters === null
          ? null
          : Number(row.distanceMeters),
      location: {
        id: row.locationId,
        latitude: Number(row.latitude),
        longitude: Number(row.longitude),
        accuracyMeters: row.accuracyMeters ?? null,
        address: row.address ?? null,
        city: row.city ?? null,
        source: row.locationSource,
        createdAt: new Date(row.locationCreatedAt).toISOString(),
      },
      createdAt: new Date(row.createdAt).toISOString(),
    };
  }
}
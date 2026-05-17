import { Injectable } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';

import { LocationSource } from '../../common/enums/location-source.enum';
import { CreateLocationDto } from './dto/create-location.dto';
import { LocationResponseDto } from './dto/location-response.dto';
import { UpdateUserLocationDto } from './dto/update-user-location.dto';
import { LocationEntity } from './entities/location.entity';
import { UserLocationEntity } from './entities/user-location.entity';

/**
 * Сервіс геолокацій.
 * Працює з PostGIS-точками та поточною локацією користувача.
 */
@Injectable()
export class LocationsService {
  constructor(
    @InjectRepository(LocationEntity)
    private readonly locationsRepository: Repository<LocationEntity>,

    @InjectRepository(UserLocationEntity)
    private readonly userLocationsRepository: Repository<UserLocationEntity>,

    @InjectDataSource()
    private readonly dataSource: DataSource,
  ) {}

  /**
 * Створює LocationEntity з PostGIS-точкою.
 * Використовуємо raw SQL, щоб коректно створити geography(Point, 4326).
 */
async createLocation(dto: CreateLocationDto): Promise<LocationEntity> {
  const source = dto.source ?? LocationSource.MANUAL;

  const rows = await this.dataSource.query(
    `
      INSERT INTO locations (
        latitude,
        longitude,
        accuracy_meters,
        address,
        city,
        source,
        point,
        created_at,
        updated_at
      )
      VALUES (
        $1::numeric,
        $2::numeric,
        $3::integer,
        $4::varchar,
        $5::varchar,
        $6::varchar,
        ST_SetSRID(
          ST_MakePoint($2::double precision, $1::double precision),
          4326
        )::geography,
        NOW(),
        NOW()
      )
      RETURNING
        id,
        latitude,
        longitude,
        accuracy_meters AS "accuracyMeters",
        address,
        city,
        source,
        created_at AS "createdAt",
        updated_at AS "updatedAt"
    `,
    [
      dto.latitude,
      dto.longitude,
      dto.accuracyMeters ?? null,
      dto.address ?? null,
      dto.city ?? null,
      source,
    ],
  );

  const row = rows[0];

  return {
    id: row.id,
    latitude: Number(row.latitude),
    longitude: Number(row.longitude),
    accuracyMeters: row.accuracyMeters,
    address: row.address,
    city: row.city,
    source: row.source,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    point: '',
  } as LocationEntity;
}

  /**
   * Оновлює поточну локацію користувача.
   */
  async updateUserCurrentLocation(
    userId: string,
    dto: UpdateUserLocationDto,
  ): Promise<LocationResponseDto> {
    const location = await this.createLocation({
      latitude: dto.latitude,
      longitude: dto.longitude,
      accuracyMeters: dto.accuracyMeters,
      source: LocationSource.USER_CURRENT,
    });

    /**
     * Старі активні локації користувача деактивуються.
     */
    await this.userLocationsRepository.update(
      {
        userId,
        isActive: true,
      },
      {
        isActive: false,
      },
    );

    const userLocation = this.userLocationsRepository.create({
      userId,
      locationId: location.id,
      isActive: true,
    });

    await this.userLocationsRepository.save(userLocation);

    return this.toResponseDto(location);
  }

  /**
   * Повертає поточну активну локацію користувача.
   */
  async getUserCurrentLocation(userId: string): Promise<LocationResponseDto | null> {
    const userLocation = await this.userLocationsRepository.findOne({
      where: {
        userId,
        isActive: true,
      },
      relations: {
        location: true,
      },
      order: {
        createdAt: 'DESC',
      },
    });

    if (!userLocation?.location) {
      return null;
    }

    return this.toResponseDto(userLocation.location);
  }

  /**
   * Перетворює LocationEntity у DTO.
   */
  toResponseDto(location: LocationEntity): LocationResponseDto {
    return {
      id: location.id,
      latitude: Number(location.latitude),
      longitude: Number(location.longitude),
      accuracyMeters: location.accuracyMeters ?? null,
      address: location.address ?? null,
      city: location.city ?? null,
      source: location.source,
      createdAt: location.createdAt.toISOString(),
    };
  }
}
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './modules/users/users.module';
import { RolesModule } from './modules/roles/roles.module';
import { AuthModule } from './modules/auth/auth.module';
import { PetsModule } from './modules/pets/pets.module';
import { FilesModule } from './modules/files/files.module';
import { QrModule } from './modules/qr/qr.module';
import { LocationsModule } from './modules/locations/locations.module';
import { MapEventsModule } from './modules/map-events/map-events.module';
import { LostReportsModule } from './modules/lost-reports/lost-reports.module';
import { SightingsModule } from './modules/sightings/sightings.module';

import databaseConfig from './config/database.config';

/**
 * Головний модуль backend-застосунку.
 * Тут підключаються глобальні модулі, база даних і майбутні feature-модулі.
 */
@Module({
  imports: [
    /**
     * ConfigModule читає .env файл і робить змінні доступними в усьому застосунку.
     */
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig],
    }),

    /**
     * Підключення TypeORM до PostgreSQL.
     * synchronize: true тимчасово дозволяє TypeORM автоматично створювати таблиці.
     * Для production і нормальних міграцій пізніше потрібно буде поставити false.
     */
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('database.host'),
        port: configService.get<number>('database.port'),
        username: configService.get<string>('database.username'),
        password: configService.get<string>('database.password'),
        database: configService.get<string>('database.database'),

        /**
         * autoLoadEntities дозволяє автоматично підхоплювати Entity,
         * які будуть підключені через TypeOrmModule.forFeature().
         */
        autoLoadEntities: true,

        /**
         * Для старту розробки можна true.
         * Коли структура стабілізується, перейдемо на міграції.
         */
        synchronize: true,
      }),
    }),

    UsersModule,

    RolesModule,

    AuthModule,

    PetsModule,

    FilesModule,

    QrModule,

    LocationsModule,

    MapEventsModule,

    LostReportsModule,

    SightingsModule,
  ],
})
export class AppModule {}
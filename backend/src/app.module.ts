import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './modules/users/users.module';
import { RolesModule } from './modules/roles/roles.module';
import { AuthModule } from './modules/auth/auth.module';

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
  ],
})
export class AppModule {}
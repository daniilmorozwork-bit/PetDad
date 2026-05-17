import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { PetEntity } from '../pets/entities/pet.entity';
import { PetsModule } from '../pets/pets.module';
import { QrController } from './qr.controller';
import { QrCodeEntity } from './entities/qr-code.entity';
import { QrScanEventEntity } from './entities/qr-scan-event.entity';
import { QrService } from './qr.service';
import { NotificationsModule } from '../notifications/notifications.module';

/**
 * Модуль QR-кодів.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([
      QrCodeEntity,
      QrScanEventEntity,
      PetEntity,
    ]),
    PetsModule,
    NotificationsModule,
  ],
  controllers: [QrController],
  providers: [QrService],
  exports: [QrService],
})
export class QrModule {}
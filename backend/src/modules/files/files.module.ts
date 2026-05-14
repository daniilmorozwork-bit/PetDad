import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { FileEntity } from './entities/file.entity';
import { FilesService } from './files.service';

/**
 * Модуль файлів.
 * Для MVP відповідає за локальне збереження фото тварин.
 */
@Module({
  imports: [TypeOrmModule.forFeature([FileEntity])],
  providers: [FilesService],
  exports: [FilesService],
})
export class FilesModule {}
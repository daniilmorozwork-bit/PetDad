import {
  BadRequestException,
  Injectable,
  PayloadTooLargeException,
  UnsupportedMediaTypeException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import type { Express } from 'express';
import { mkdir, unlink, writeFile } from 'fs/promises';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';
import { Repository } from 'typeorm';

import { FileEntityType } from '../../common/enums/file-entity-type.enum';
import { FileStorageProvider } from '../../common/enums/file-storage-provider.enum';
import { FileResponseDto } from './dto/file-response.dto';
import { FileEntity } from './entities/file.entity';

/**
 * Сервіс для роботи з файлами.
 * Для MVP файли зберігаються локально у backend/uploads.
 */
@Injectable()
export class FilesService {
  private readonly allowedImageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  private readonly maxFileSizeBytes = Number(
    process.env.MAX_FILE_SIZE || 10 * 1024 * 1024,
  );

  constructor(
    @InjectRepository(FileEntity)
    private readonly filesRepository: Repository<FileEntity>,
  ) {}

  /**
   * Завантажує фото тварини у локальне сховище.
   */
  async uploadPetPhoto(
    file: Express.Multer.File | undefined,
    uploadedById: string,
    petId: string,
  ): Promise<FileEntity> {
    this.validateImageFile(file);

    if (!file) {
      throw new BadRequestException({
        errorCode: 'FILE_REQUIRED',
        message: 'Файл є обовʼязковим',
      });
    }

    const extension = this.getExtensionFromMimeType(file.mimetype);
    const storedName = `${randomUUID()}.${extension}`;

    const uploadDir = join(process.cwd(), 'uploads', 'pets');
    const relativePath = `uploads/pets/${storedName}`;
    const filePath = join(uploadDir, storedName);
    const publicUrl = `/uploads/pets/${storedName}`;

    /**
     * Створюємо папку, якщо її ще немає.
     */
    await mkdir(uploadDir, { recursive: true });

    /**
     * Записуємо файл на диск.
     */
    await writeFile(filePath, file.buffer);

    const fileEntity = this.filesRepository.create({
      uploadedById,
      entityType: FileEntityType.PET_PHOTO,
      entityId: petId,
      originalName: file.originalname,
      storedName,
      mimeType: file.mimetype,
      extension,
      sizeBytes: file.size,
      storageProvider: FileStorageProvider.LOCAL,
      path: relativePath,
      url: publicUrl,
    });

    return this.filesRepository.save(fileEntity);
  }

  /**
   * Видаляє файл фізично і робить soft delete запису в БД.
   */
  async deleteFile(fileId: string): Promise<void> {
    const file = await this.filesRepository.findOne({
      where: { id: fileId },
    });

    if (!file) {
      return;
    }

    const absolutePath = join(process.cwd(), file.path);

    try {
      await unlink(absolutePath);
    } catch {
      /**
       * Якщо файлу фізично вже немає, не ламаємо запит.
       * Запис у БД все одно буде видалено через soft delete.
       */
    }

    await this.filesRepository.softDelete(file.id);
  }

  /**
   * Перетворює FileEntity у DTO.
   */
  toResponseDto(file: FileEntity): FileResponseDto {
    return {
      id: file.id,
      originalName: file.originalName,
      storedName: file.storedName,
      mimeType: file.mimeType,
      extension: file.extension,
      sizeBytes: file.sizeBytes,
      url: file.url,
      createdAt: file.createdAt.toISOString(),
    };
  }

  /**
   * Перевіряє, чи файл є коректним зображенням.
   */
  private validateImageFile(file?: Express.Multer.File): void {
    if (!file) {
      throw new BadRequestException({
        errorCode: 'FILE_REQUIRED',
        message: 'Файл є обовʼязковим',
      });
    }

    if (!this.allowedImageMimeTypes.includes(file.mimetype)) {
      throw new UnsupportedMediaTypeException({
        errorCode: 'UNSUPPORTED_FILE_TYPE',
        message: 'Підтримуються лише JPG, PNG або WEBP зображення',
      });
    }

    if (file.size > this.maxFileSizeBytes) {
      throw new PayloadTooLargeException({
        errorCode: 'FILE_TOO_LARGE',
        message: 'Файл занадто великий',
      });
    }

    if (!file.buffer || file.buffer.length === 0) {
      throw new BadRequestException({
        errorCode: 'EMPTY_FILE',
        message: 'Файл порожній',
      });
    }
  }

  /**
   * Визначає розширення за MIME-типом.
   * Не довіряємо лише назві файлу від користувача.
   */
  private getExtensionFromMimeType(mimeType: string): string {
    const map: Record<string, string> = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
    };

    const extension = map[mimeType];

    if (!extension) {
      /**
       * Запасний варіант. Теоретично сюди не потрапимо,
       * бо MIME вже перевірений у validateImageFile().
       */
      return extname(mimeType).replace('.', '') || 'bin';
    }

    return extension;
  }
}
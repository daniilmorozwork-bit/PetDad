import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiTags,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Express } from 'express';
import { memoryStorage } from 'multer';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import type { JwtUserPayload } from '../auth/interfaces/jwt-user-payload.interface';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';
import { PetsService } from './pets.service';

/**
 * Controller для роботи з профілями тварин.
 */
@ApiTags('pets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('pets')
export class PetsController {
  constructor(private readonly petsService: PetsService) {}

  /**
   * Створення профілю тварини.
   */
  @Post()
  createPet(
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: CreatePetDto,
  ) {
    return this.petsService.createPet(user.sub, dto);
  }

  /**
   * Список тварин поточного користувача.
   * Має бути перед /:id, інакше Nest може сприйняти "my" як id.
   */
  @Get('my')
  getMyPets(@CurrentUser() user: JwtUserPayload) {
    return this.petsService.getMyPets(user.sub);
  }

  /**
   * Додавання фото до профілю тварини.
   */
  @Post(':id/photos')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'Фото тварини у форматі JPG, PNG або WEBP',
        },
      },
      required: ['file'],
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: {
        fileSize: 10 * 1024 * 1024,
      },
    }),
  )
  addPhoto(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: JwtUserPayload,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.petsService.addPhoto(id, user.sub, file);
  }

  /**
   * Детальний профіль тварини.
   */
  @Get(':id')
  getPetById(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.petsService.getPetById(id, user.sub);
  }

  /**
   * Редагування профілю тварини.
   */
  @Patch(':id')
  updatePet(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: UpdatePetDto,
  ) {
    return this.petsService.updatePet(id, user.sub, dto);
  }

  /**
   * Встановлення головного фото.
   */
  @Patch(':id/photos/:photoId/main')
  setMainPhoto(
    @Param('id', new ParseUUIDPipe()) id: string,
    @Param('photoId', new ParseUUIDPipe()) photoId: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.petsService.setMainPhoto(id, photoId, user.sub);
  }

  /**
   * Видалення фото тварини.
   */
  @Delete(':id/photos/:photoId')
  deletePhoto(
    @Param('id', new ParseUUIDPipe()) id: string,
    @Param('photoId', new ParseUUIDPipe()) photoId: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.petsService.deletePhoto(id, photoId, user.sub);
  }

  /**
   * Архівація профілю тварини.
   */
  @Delete(':id')
  archivePet(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.petsService.archivePet(id, user.sub);
  }
}
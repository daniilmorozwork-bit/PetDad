import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import type { JwtUserPayload } from '../auth/interfaces/jwt-user-payload.interface';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';
import { PetsService } from './pets.service';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

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
   * Детальний профіль тварини.
   */
  @Get(':id')
  getPetById(
    @Param('id') id: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.petsService.getPetById(id, user.sub);
  }

  /**
   * Редагування профілю тварини.
   */
  @Patch(':id')
  updatePet(
    @Param('id') id: string,
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: UpdatePetDto,
  ) {
    return this.petsService.updatePet(id, user.sub, dto);
  }

  /**
   * Архівація профілю тварини.
   */
  @Delete(':id')
  archivePet(
    @Param('id') id: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.petsService.archivePet(id, user.sub);
  }
}
import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import type { Request } from 'express';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import type { JwtUserPayload } from '../auth/interfaces/jwt-user-payload.interface';
import { RegisterQrScanDto } from './dto/register-qr-scan.dto';
import { QrService } from './qr.service';

/**
 * Controller QR-кодів.
 * Частина endpoints захищена, частина публічна.
 */
@ApiTags('qr')
@Controller()
export class QrController {
  constructor(private readonly qrService: QrService) {}

  /**
   * Створення QR-коду для тварини.
   */
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('pets/:petId/qr-code')
  generateQrForPet(
    @Param('petId', new ParseUUIDPipe()) petId: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.qrService.generateQrForPet(petId, user.sub);
  }

  /**
   * Отримання активного QR-коду тварини.
   */
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('pets/:petId/qr-code')
  getActiveQrForPet(
    @Param('petId', new ParseUUIDPipe()) petId: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.qrService.getActiveQrForPet(petId, user.sub);
  }

  /**
   * Перевипуск QR-коду.
   */
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('pets/:petId/qr-code/reissue')
  reissueQrForPet(
    @Param('petId', new ParseUUIDPipe()) petId: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.qrService.reissueQrForPet(petId, user.sub);
  }

  /**
   * Публічний профіль тварини за QR token.
   * Авторизація не потрібна.
   */
  @ApiParam({
    name: 'token',
    description: 'Унікальний token QR-коду',
  })
  @Get('qr/:token')
  getPublicPetProfile(@Param('token') token: string) {
    return this.qrService.getPublicPetProfileByToken(token);
  }

  /**
   * Фіксація сканування QR.
   * Авторизація не потрібна.
   */
  @ApiParam({
    name: 'token',
    description: 'Унікальний token QR-коду',
  })
  @ApiBody({
    type: RegisterQrScanDto,
    required: false,
    description: 'Опціональні координати місця сканування',
  })
  @Post('qr/:token/scan')
  registerScan(
    @Param('token') token: string,
    @Body() dto: RegisterQrScanDto,
    @Req() request: Request,
  ) {
    return this.qrService.registerScan(token, dto, request);
  }
}
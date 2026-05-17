import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import type { JwtUserPayload } from '../auth/interfaces/jwt-user-payload.interface';
import { RegisterPushTokenDto } from './dto/register-push-token.dto';
import { NotificationsService } from './notifications.service';

/**
 * Controller повідомлень.
 */
@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  /**
   * Список повідомлень поточного користувача.
   */
  @Get()
  getMyNotifications(@CurrentUser() user: JwtUserPayload) {
    return this.notificationsService.getMyNotifications(user.sub);
  }

  /**
   * Позначити повідомлення як прочитане.
   */
  @Patch(':id/read')
  markAsRead(
    @Param('id', new ParseUUIDPipe()) id: string,
    @CurrentUser() user: JwtUserPayload,
  ) {
    return this.notificationsService.markAsRead(id, user.sub);
  }

  /**
   * Реєстрація push-токена пристрою.
   * Firebase-доставку підключимо пізніше.
   */
  @Post('register-token')
  registerPushToken(
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: RegisterPushTokenDto,
  ) {
    return this.notificationsService.registerPushToken(user.sub, dto);
  }
}
import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { UpdateUserLocationDto } from '../locations/dto/update-user-location.dto';
import { LocationsService } from '../locations/locations.service';
import type { JwtUserPayload } from '../auth/interfaces/jwt-user-payload.interface';
import { UsersService } from './users.service';

/**
 * Controller користувачів.
 * Тут розміщені endpoints профілю та поточної локації користувача.
 */
@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly locationsService: LocationsService,
  ) {}

  /**
   * Поточний користувач.
   */
  @Get('me')
  getMe(@CurrentUser() user: JwtUserPayload) {
    return this.usersService.findByIdWithRoles(user.sub).then((foundUser) => {
      if (!foundUser) {
        return null;
      }

      return this.usersService.toResponseDto(foundUser);
    });
  }

  /**
   * Оновлення поточної локації користувача.
   */
  @Patch('me/location')
  updateMyLocation(
    @CurrentUser() user: JwtUserPayload,
    @Body() dto: UpdateUserLocationDto,
  ) {
    return this.locationsService.updateUserCurrentLocation(user.sub, dto);
  }

  /**
   * Отримання поточної локації користувача.
   */
  @Get('me/location')
  getMyLocation(@CurrentUser() user: JwtUserPayload) {
    return this.locationsService.getUserCurrentLocation(user.sub);
  }
}
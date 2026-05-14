import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import type { JwtUserPayload } from './interfaces/jwt-user-payload.interface';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';


/**
 * Controller авторизації.
 * Базові endpoints:
 * POST /auth/register
 * POST /auth/login
 * POST /auth/refresh
 * POST /auth/logout
 * GET  /auth/me
 */
@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Реєстрація нового користувача.
   */
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  /**
   * Вхід користувача.
   */
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  /**
   * Оновлення access token.
   */
  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshTokens(dto);
  }

  /**
   * Logout.
   * Для MVP відкликаємо всі активні сесії користувача.
   */
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('logout')
  logout(@CurrentUser() user: JwtUserPayload) {
    return this.authService.logout(user.sub);
  }

  /**
   * Поточний користувач.
   */
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me')
  getMe(@CurrentUser() user: JwtUserPayload) {
    return this.authService.getMe(user.sub);
  }
}
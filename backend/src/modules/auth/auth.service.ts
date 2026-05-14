import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { JwtSignOptions } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { IsNull, Repository } from 'typeorm';

import { RoleCode } from '../../common/enums/role-code.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { RolesService } from '../roles/roles.service';
import { UsersService } from '../users/users.service';
import { AuthResponseDto } from './dto/auth-response.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { AuthSessionEntity } from './entities/auth-session.entity';
import { JwtUserPayload } from './interfaces/jwt-user-payload.interface';

/**
 * Сервіс авторизації.
 * Відповідає за register, login, refresh token, logout і поточного користувача.
 */
@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly rolesService: RolesService,
    private readonly jwtService: JwtService,

    @InjectRepository(AuthSessionEntity)
    private readonly authSessionsRepository: Repository<AuthSessionEntity>,
  ) {}

  /**
   * Реєстрація нового користувача.
   */
  async register(dto: RegisterDto): Promise<AuthResponseDto> {
    const normalizedEmail = dto.email.toLowerCase().trim();

    const existingUser = await this.usersService.findByEmail(normalizedEmail);

    if (existingUser) {
      throw new ConflictException({
        errorCode: 'EMAIL_ALREADY_EXISTS',
        message: 'Користувач із таким email уже існує',
      });
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.usersService.createUser({
      email: normalizedEmail,
      passwordHash,
      fullName: dto.fullName,
      phone: dto.phone,
    });

    await this.rolesService.assignRoleToUser(user.id, RoleCode.USER);

    const userWithRoles = await this.usersService.findByIdWithRoles(user.id);

    if (!userWithRoles) {
      throw new UnauthorizedException('Не вдалося створити користувача');
    }

    const tokens = await this.generateTokensForUser(userWithRoles.id);

    await this.createAuthSession(userWithRoles.id, tokens.refreshToken);

    return {
      ...tokens,
      user: this.usersService.toResponseDto(userWithRoles),
    };
  }

  /**
   * Вхід користувача.
   */
  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const user = await this.usersService.findByEmailWithPassword(dto.email);

    if (!user) {
      throw new UnauthorizedException({
        errorCode: 'INVALID_CREDENTIALS',
        message: 'Неправильний email або пароль',
      });
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        errorCode: 'ACCOUNT_BLOCKED',
        message: 'Акаунт неактивний або заблокований',
      });
    }

    const passwordIsValid = await bcrypt.compare(dto.password, user.passwordHash);

    if (!passwordIsValid) {
      throw new UnauthorizedException({
        errorCode: 'INVALID_CREDENTIALS',
        message: 'Неправильний email або пароль',
      });
    }

    const userWithRoles = await this.usersService.findByIdWithRoles(user.id);

    if (!userWithRoles) {
      throw new UnauthorizedException({
        errorCode: 'USER_NOT_FOUND',
        message: 'Користувача не знайдено',
      });
    }

    const tokens = await this.generateTokensForUser(userWithRoles.id);

    await this.createAuthSession(userWithRoles.id, tokens.refreshToken);

    return {
      ...tokens,
      user: this.usersService.toResponseDto(userWithRoles),
    };
  }

  /**
   * Оновлення access token через refresh token.
   */
  async refreshTokens(dto: RefreshTokenDto): Promise<AuthResponseDto> {
    let payload: JwtUserPayload;

    try {
      payload = await this.jwtService.verifyAsync<JwtUserPayload>(
        dto.refreshToken,
        {
          secret: process.env.JWT_REFRESH_SECRET || 'petdad_refresh_secret_dev',
        },
      );
    } catch {
      throw new UnauthorizedException({
        errorCode: 'REFRESH_TOKEN_INVALID',
        message: 'Refresh token недійсний',
      });
    }

    const user = await this.usersService.findByIdWithRoles(payload.sub);

    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        errorCode: 'USER_NOT_ACTIVE',
        message: 'Користувач неактивний або не знайдений',
      });
    }

    const activeSessions = await this.authSessionsRepository.find({
      where: {
        userId: user.id,
        revokedAt: IsNull(),
      },
    });

    let matchedSession: AuthSessionEntity | null = null;

    for (const session of activeSessions) {
      const tokenMatches = await bcrypt.compare(
        dto.refreshToken,
        session.refreshTokenHash,
      );

      if (tokenMatches) {
        matchedSession = session;
        break;
      }
    }

    if (!matchedSession) {
      throw new UnauthorizedException({
        errorCode: 'SESSION_REVOKED',
        message: 'Сесія недійсна або відкликана',
      });
    }

    const tokens = await this.generateTokensForUser(user.id);

    /**
     * Rotation refresh token.
     * Старий refresh token замінюється новим.
     */
    matchedSession.refreshTokenHash = await bcrypt.hash(tokens.refreshToken, 10);
    matchedSession.expiresAt = this.getRefreshTokenExpirationDate();

    await this.authSessionsRepository.save(matchedSession);

    return {
      ...tokens,
      user: this.usersService.toResponseDto(user),
    };
  }

  /**
   * Logout для MVP.
   * Відкликає всі активні сесії користувача.
   */
  async logout(userId: string): Promise<{ success: boolean }> {
    await this.authSessionsRepository.update(
      {
        userId,
        revokedAt: IsNull(),
      },
      {
        revokedAt: new Date(),
      },
    );

    return { success: true };
  }

  /**
   * Повертає поточного користувача.
   */
  async getMe(userId: string) {
    const user = await this.usersService.findByIdWithRoles(userId);

    if (!user) {
      throw new UnauthorizedException({
        errorCode: 'USER_NOT_FOUND',
        message: 'Користувача не знайдено',
      });
    }

    return this.usersService.toResponseDto(user);
  }

  /**
 * Генерує access і refresh token.
 */
private async generateTokensForUser(userId: string): Promise<{
  accessToken: string;
  refreshToken: string;
}> {
  const user = await this.usersService.findByIdWithRoles(userId);

  if (!user) {
    throw new UnauthorizedException('Користувача не знайдено');
  }

  const roles = user.userRoles?.map((userRole) => userRole.role.code) ?? [];

  const payload: JwtUserPayload = {
    sub: user.id,
    email: user.email,
    roles,
  };

  /**
   * Явно приводимо expiresIn до типу, який очікує JwtService.
   * process.env завжди повертає string | undefined, а TypeScript хоче точніший тип.
   */
  const accessTokenOptions: JwtSignOptions = {
    secret: process.env.JWT_ACCESS_SECRET || 'petdad_access_secret_dev',
    expiresIn: (process.env.JWT_ACCESS_EXPIRES_IN ||
      '15m') as JwtSignOptions['expiresIn'],
  };

  const refreshTokenOptions: JwtSignOptions = {
    secret: process.env.JWT_REFRESH_SECRET || 'petdad_refresh_secret_dev',
    expiresIn: (process.env.JWT_REFRESH_EXPIRES_IN ||
      '30d') as JwtSignOptions['expiresIn'],
  };

  const accessToken = await this.jwtService.signAsync(
    payload,
    accessTokenOptions,
  );

  const refreshToken = await this.jwtService.signAsync(
    payload,
    refreshTokenOptions,
  );

  return {
    accessToken,
    refreshToken,
  };
}

  /**
   * Створює auth session із hash refresh token.
   */
  private async createAuthSession(
    userId: string,
    refreshToken: string,
  ): Promise<AuthSessionEntity> {
    const refreshTokenHash = await bcrypt.hash(refreshToken, 10);

    const session = this.authSessionsRepository.create({
      userId,
      refreshTokenHash,
      expiresAt: this.getRefreshTokenExpirationDate(),
    });

    return this.authSessionsRepository.save(session);
  }

  /**
   * Для MVP ставимо 30 днів.
   * Пізніше можна брати значення з config.
   */
  private getRefreshTokenExpirationDate(): Date {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);
    return expiresAt;
  }
}
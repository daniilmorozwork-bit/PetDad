import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

import { UserStatus } from '../../../common/enums/user-status.enum';
import { UsersService } from '../../users/users.service';
import { JwtUserPayload } from '../interfaces/jwt-user-payload.interface';

/**
 * JWT strategy перевіряє access token.
 * Якщо токен валідний, результат validate() потрапляє в request.user.
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey:
        configService.get<string>('JWT_ACCESS_SECRET') ||
        'petdad_access_secret_dev',
    });
  }

  /**
   * Додаткова перевірка користувача після перевірки JWT.
   */
  async validate(payload: JwtUserPayload): Promise<JwtUserPayload> {
    const user = await this.usersService.findByIdWithRoles(payload.sub);

    if (!user) {
      throw new UnauthorizedException('Користувача не знайдено');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Акаунт неактивний або заблокований');
    }

    return {
      sub: user.id,
      email: user.email,
      roles: user.userRoles?.map((userRole) => userRole.role.code) ?? [],
    };
  }
}
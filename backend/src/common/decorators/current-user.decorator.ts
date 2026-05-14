import { createParamDecorator, ExecutionContext } from '@nestjs/common';

import { JwtUserPayload } from '../../modules/auth/interfaces/jwt-user-payload.interface';

/**
 * Декоратор для отримання поточного користувача з request.user.
 * Використовується після JwtAuthGuard.
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): JwtUserPayload => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

/**
 * Точка входу backend-застосунку.
 * Тут налаштовується глобальний prefix API, валідація, CORS і Swagger.
 */
async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

    /**
   * Віддаємо локально завантажені файли через /uploads.
   * Наприклад: http://localhost:3000/uploads/pets/photo.jpg
   */
  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
  });

  /**
   * Усі endpoints будуть починатися з /api/v1.
   * Наприклад: /api/v1/auth/login
   */
  app.setGlobalPrefix('api/v1');

  /**
   * Глобальна валідація DTO.
   * whitelist прибирає зайві поля.
   * forbidNonWhitelisted забороняє невідомі поля.
   * transform автоматично перетворює типи.
   */
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  /**
   * CORS потрібен, щоб mobile/frontend міг звертатися до backend.
   * Для локальної розробки дозволяємо всі origin.
   */
  app.enableCors({
    origin: process.env.CORS_ORIGIN || '*',
  });

  /**
   * Swagger-документація API.
   * Відкриватиметься за адресою /api/docs.
   */
  const swaggerConfig = new DocumentBuilder()
    .setTitle('PetDad API')
    .setDescription('API для MVP застосунку пошуку зниклих тварин')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, swaggerDocument);

  const port = process.env.PORT || 3000;
  await app.listen(port);

  console.log(`Backend запущено: http://localhost:${port}/api/v1`);
  console.log(`Swagger доступний: http://localhost:${port}/api/docs`);
}

bootstrap();
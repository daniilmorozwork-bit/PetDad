import { registerAs } from '@nestjs/config';

/**
 * Конфігурація підключення до PostgreSQL.
 * Дані беруться з .env, щоб не зберігати паролі та налаштування прямо в коді.
 */
export default registerAs('database', () => ({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'petdad',
}));
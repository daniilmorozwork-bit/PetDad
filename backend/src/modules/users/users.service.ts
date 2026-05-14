import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { UserEntity } from './entities/user.entity';
import { UserResponseDto } from './dto/user-response.dto';
import { UserStatus } from '../../common/enums/user-status.enum';

interface CreateUserInput {
  email: string;
  passwordHash: string;
  fullName: string;
  phone?: string;
}

/**
 * Сервіс користувачів.
 * Відповідає за створення, пошук і перетворення користувача у безпечний DTO.
 */
@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly usersRepository: Repository<UserEntity>,
  ) {}

  /**
   * Створює нового користувача.
   */
  async createUser(input: CreateUserInput): Promise<UserEntity> {
    const user = this.usersRepository.create({
      email: input.email.toLowerCase().trim(),
      passwordHash: input.passwordHash,
      fullName: input.fullName.trim(),
      phone: input.phone?.trim() || null,
      status: UserStatus.ACTIVE,
    });

    return this.usersRepository.save(user);
  }

  /**
   * Шукає користувача за email без passwordHash.
   */
  async findByEmail(email: string): Promise<UserEntity | null> {
    return this.usersRepository.findOne({
      where: { email: email.toLowerCase().trim() },
    });
  }

  /**
   * Шукає користувача за email разом із passwordHash.
   * Це потрібно тільки для login.
   */
  async findByEmailWithPassword(email: string): Promise<UserEntity | null> {
    return this.usersRepository
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('user.email = :email', { email: email.toLowerCase().trim() })
      .getOne();
  }

  /**
   * Шукає користувача за id разом із ролями.
   */
  async findByIdWithRoles(id: string): Promise<UserEntity | null> {
    return this.usersRepository.findOne({
      where: { id },
      relations: {
        userRoles: {
          role: true,
        },
      },
    });
  }

  /**
   * Перетворює UserEntity у безпечний UserResponseDto.
   */
  toResponseDto(user: UserEntity): UserResponseDto {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      status: user.status,
      roles:
        user.userRoles?.map((userRole) => ({
          code: userRole.role.code,
          name: userRole.role.name,
          verificationStatus: userRole.verificationStatus,
        })) ?? [],
      createdAt: user.createdAt.toISOString(),
    };
  }
}
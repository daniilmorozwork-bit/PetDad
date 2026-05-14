import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

import { PetGender } from '../../../common/enums/pet-gender.enum';
import { PetSpecies } from '../../../common/enums/pet-species.enum';

/**
 * DTO для створення профілю тварини.
 */
export class CreatePetDto {
  @IsString()
  @IsNotEmpty({ message: 'Кличка тварини є обовʼязковою' })
  name: string;

  @IsEnum(PetSpecies, { message: 'Некоректний вид тварини' })
  species: PetSpecies;

  @IsOptional()
  @IsString()
  breed?: string;

  @IsEnum(PetGender, { message: 'Некоректна стать тварини' })
  gender: PetGender;

  @IsOptional()
  @IsDateString({}, { message: 'Дата народження має бути коректною датою' })
  birthDate?: string;

  @IsString()
  @IsNotEmpty({ message: 'Окрас тварини є обовʼязковим' })
  color: string;

  @IsOptional()
  @IsNumber({}, { message: 'Вага має бути числом' })
  @Min(0.1, { message: 'Вага має бути більшою за 0' })
  @Max(300, { message: 'Вага має бути реалістичною' })
  weightKg?: number;

  @IsOptional()
  @IsString()
  specialMarks?: string;

  @IsOptional()
  @IsString()
  chipNumber?: string;

  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}
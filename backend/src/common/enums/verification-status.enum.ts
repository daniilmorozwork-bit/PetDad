/**
 * Статус підтвердження ролі або організації.
 * Для базової ролі user верифікація не потрібна.
 */
export enum VerificationStatus {
  NOT_REQUIRED = 'not_required',
  PENDING = 'pending',
  VERIFIED = 'verified',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
  REVOKED = 'revoked',
}
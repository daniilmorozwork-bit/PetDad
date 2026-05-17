/**
 * DTO відповіді з повідомленням.
 */
export class NotificationResponseDto {
  id: string;
  recipientId: string;
  type: string;
  title: string;
  body: string;
  entityType?: string | null;
  entityId?: string | null;
  data?: Record<string, unknown> | null;
  readAt?: string | null;
  createdAt: string;
}
/**
 * Дані користувача, які зберігаються всередині access token.
 */
export interface JwtUserPayload {
  sub: string;
  email: string;
  roles: string[];
}
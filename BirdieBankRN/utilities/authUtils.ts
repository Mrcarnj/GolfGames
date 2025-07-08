export function validateEmail(email: string): boolean {
  const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
  return emailRegex.test(email);
}

export function validatePassword(password: string): boolean {
  // At least 8 characters, at least one letter and one number
  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/;
  return passwordRegex.test(password);
}

export function validateName(name: string): boolean {
  const nameRegex = /^[a-zA-Z ]{1,50}$/;
  return nameRegex.test(name);
}

export function validateHandicap(handicap: string): boolean {
  const handicapRegex = /^\d{1,2}(\.\d)?$/;
  if (!handicapRegex.test(handicap)) return false;
  const value = parseFloat(handicap);
  return value >= 0 && value <= 54;
}

export function validateGHIN(ghin: string): boolean {
  const ghinRegex = /^\d{7}$/;
  return ghinRegex.test(ghin);
} 
export const isValidInput = (input: string) => {
  const emailRegex = /^\S+@\S+\.\S+$/;
  const nameSurnameRegex = /^[a-zA-Z]+ [a-zA-Z]+$/;

  return emailRegex.test(input) || nameSurnameRegex.test(input);
};

namespace SportLinea.Api;

public record ApiMessage(bool Success, string Message, object? Data = null);

public record LoginRequest(string Email, string Password);

public record RegisterRequest(
    string Email,
    string Password,
    string ConfirmPassword,
    string FirstName,
    string LastName,
    string? Patronymic,
    string CountryOfResidence);

public record PlaceBetRequest(int CoefficientId, decimal Amount, bool UseFreeBet = false);

public record AmountRequest(decimal Amount);

public record ProfileEditRequest(
    string FirstName,
    string LastName,
    string? Patronymic,
    string CountryOfResidence,
    string? NewPassword);

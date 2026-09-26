using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using SportLinea.Models;
using SportLinea.Services;

namespace SportLinea.Api;

[ApiController]
[Route("api/auth")]
public class AuthApiController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly JwtTokenService _jwt;
    private readonly IActionLogService _actionLog;
    private readonly IBonusService _bonusService;
    private readonly INotificationService _notificationService;

    public AuthApiController(
        UserManager<ApplicationUser> userManager,
        JwtTokenService jwt,
        IActionLogService actionLog,
        IBonusService bonusService,
        INotificationService notificationService)
    {
        _userManager = userManager;
        _jwt = jwt;
        _actionLog = actionLog;
        _bonusService = bonusService;
        _notificationService = notificationService;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiMessage>> Login([FromBody] LoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            return BadRequest(new ApiMessage(false, "Укажите email и пароль"));

        var user = await _userManager.FindByEmailAsync(request.Email.Trim());
        if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
            return Unauthorized(new ApiMessage(false, "Неверный email или пароль"));

        if (user.Status == UserStatus.Blocked)
            return StatusCode(403, new ApiMessage(false, "Учётная запись заблокирована"));

        var isStaff = await _userManager.IsInRoleAsync(user, Roles.Bookmaker)
                      || await _userManager.IsInRoleAsync(user, Roles.SuperUser);
        if (isStaff || !await _userManager.IsInRoleAsync(user, Roles.Player))
            return StatusCode(403, new ApiMessage(false, "Мобильное приложение доступно только игроку"));

        await _actionLog.LogAsync(user.Id, "Авторизация (мобильное API)", HttpContext.Connection.RemoteIpAddress?.ToString());
        return Ok(new ApiMessage(true, "Вход выполнен", new
        {
            token = _jwt.Create(user),
            user = MeDto(user)
        }));
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiMessage>> Register([FromBody] RegisterRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            return BadRequest(new ApiMessage(false, "Укажите email и пароль"));
        if (request.Password != request.ConfirmPassword)
            return BadRequest(new ApiMessage(false, "Пароли не совпадают"));
        if (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName))
            return BadRequest(new ApiMessage(false, "Укажите фамилию и имя"));
        if (await _userManager.FindByEmailAsync(request.Email.Trim()) != null)
            return BadRequest(new ApiMessage(false, "Пользователь с таким email уже существует"));

        var country = string.Equals(request.CountryOfResidence, "Russia", StringComparison.OrdinalIgnoreCase)
            ? CountryOfResidence.Russia
            : CountryOfResidence.USA;

        var user = new ApplicationUser
        {
            UserName = request.Email.Trim(),
            Email = request.Email.Trim(),
            EmailConfirmed = true,
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            Patronymic = string.IsNullOrWhiteSpace(request.Patronymic) ? null : request.Patronymic.Trim(),
            Balance = 0,
            Status = UserStatus.Active,
            RegistrationDate = DateTime.UtcNow,
            CountryOfResidence = country
        };

        var created = await _userManager.CreateAsync(user, request.Password);
        if (!created.Succeeded)
            return BadRequest(new ApiMessage(false, string.Join(" ", created.Errors.Select(e => e.Description))));

        await _userManager.AddToRoleAsync(user, Roles.Player);
        await _bonusService.AwardRegistrationBonusesAsync(user.Id);
        await _notificationService.SendAsync(user.Id, NotificationType.Registration,
            "Добро пожаловать в БК «СпортЛиния»! Ваша учётная запись успешно создана.");
        await _actionLog.LogAsync(user.Id, "Регистрация нового игрока (мобильное API)", HttpContext.Connection.RemoteIpAddress?.ToString());

        return Ok(new ApiMessage(true, "Регистрация выполнена", new
        {
            token = _jwt.Create(user),
            user = MeDto(user)
        }));
    }

    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpGet("me")]
    public async Task<ActionResult<ApiMessage>> Me()
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null)
            return Unauthorized(new ApiMessage(false, "Сессия истекла"));

        return Ok(new ApiMessage(true, "OK", MeDto(user)));
    }

    private static object MeDto(ApplicationUser user) => new
    {
        id = user.Id,
        email = user.Email,
        firstName = user.FirstName,
        lastName = user.LastName,
        fullName = user.FullName,
        balance = user.Balance,
        countryOfResidence = user.CountryOfResidence.ToString()
    };
}

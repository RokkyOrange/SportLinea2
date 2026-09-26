using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportLinea.Data;
using SportLinea.Models;
using SportLinea.Services;

namespace SportLinea.Api;

[ApiController]
[Route("api")]
[Authorize(AuthenticationSchemes = "Bearer")]
public class ProfileApiController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IActionLogService _actionLog;
    private readonly IBonusService _bonusService;
    private readonly IWithdrawalService _withdrawalService;
    private readonly INotificationService _notifications;

    public ProfileApiController(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        IActionLogService actionLog,
        IBonusService bonusService,
        IWithdrawalService withdrawalService,
        INotificationService notifications)
    {
        _context = context;
        _userManager = userManager;
        _actionLog = actionLog;
        _bonusService = bonusService;
        _withdrawalService = withdrawalService;
        _notifications = notifications;
    }

    [HttpGet("profile")]
    public async Task<ActionResult<ApiMessage>> Profile()
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null) return Unauthorized(new ApiMessage(false, "Сессия истекла"));

        var bets = await _context.Bets.Where(b => b.PlayerId == user.Id).ToListAsync();
        var notes = await _context.Notifications
            .Where(n => n.UserId == user.Id)
            .OrderByDescending(n => n.SentAt)
            .Take(5)
            .ToListAsync();

        return Ok(new ApiMessage(true, "OK", new
        {
            user = MapUser(user),
            stats = new
            {
                totalBets = bets.Count,
                wins = bets.Count(b => b.Status == BetStatus.Won),
                losses = bets.Count(b => b.Status == BetStatus.Lost),
                pending = bets.Count(b => b.Status == BetStatus.Accepted),
                totalWinnings = bets.Where(b => b.Status == BetStatus.Won).Sum(b => b.Winnings),
                totalStaked = bets.Sum(b => b.Amount)
            },
            notifications = notes.Select(MapNote),
            withdrawMin = WithdrawRules.MinAmount,
            depositMin = DepositRules.MinAmount
        }));
    }

    [HttpPut("profile")]
    public async Task<ActionResult<ApiMessage>> Edit([FromBody] ProfileEditRequest request)
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null) return Unauthorized(new ApiMessage(false, "Сессия истекла"));

        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Patronymic = string.IsNullOrWhiteSpace(request.Patronymic) ? null : request.Patronymic.Trim();
        user.CountryOfResidence = string.Equals(request.CountryOfResidence, "Russia", StringComparison.OrdinalIgnoreCase)
            ? CountryOfResidence.Russia
            : CountryOfResidence.USA;

        if (!string.IsNullOrEmpty(request.NewPassword))
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var result = await _userManager.ResetPasswordAsync(user, token, request.NewPassword);
            if (!result.Succeeded)
                return BadRequest(new ApiMessage(false, string.Join(" ", result.Errors.Select(e => e.Description))));
        }

        await _userManager.UpdateAsync(user);
        await _actionLog.LogAsync(user.Id, "Редактирование профиля (мобильное API)", HttpContext.Connection.RemoteIpAddress?.ToString());
        return Ok(new ApiMessage(true, "Профиль обновлён", MapUser(user)));
    }

    [HttpPost("profile/deposit")]
    public async Task<ActionResult<ApiMessage>> Deposit([FromBody] AmountRequest request)
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null) return Unauthorized(new ApiMessage(false, "Сессия истекла"));
        if (request.Amount < DepositRules.MinAmount)
            return BadRequest(new ApiMessage(false, $"Минимальная сумма пополнения — {DepositRules.MinAmount:N0} ₽"));

        user.Balance += request.Amount;
        await _userManager.UpdateAsync(user);
        _context.AccountOperations.Add(new AccountOperation
        {
            PlayerId = user.Id,
            OperationType = OperationType.Deposit,
            Amount = request.Amount,
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync();
        await _notifications.SendAsync(user.Id, NotificationType.BalanceDeposit, $"Ваш баланс пополнен на {request.Amount:N2} ₽.");
        await _actionLog.LogAsync(user.Id, $"Пополнение счёта на {request.Amount:N2} ₽", HttpContext.Connection.RemoteIpAddress?.ToString());
        return Ok(new ApiMessage(true, $"Счёт пополнен на {request.Amount:N2} ₽", new { balance = user.Balance }));
    }

    [HttpPost("profile/withdraw")]
    public async Task<ActionResult<ApiMessage>> Withdraw([FromBody] AmountRequest request)
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null) return Unauthorized(new ApiMessage(false, "Сессия истекла"));
        var (success, message, _) = await _withdrawalService.RequestWithdrawalAsync(user.Id, request.Amount);
        if (!success) return BadRequest(new ApiMessage(false, message));
        await _actionLog.LogAsync(user.Id, $"Заявка на вывод {request.Amount:N2} ₽", HttpContext.Connection.RemoteIpAddress?.ToString());
        await _context.Entry(user).ReloadAsync();
        return Ok(new ApiMessage(true, message, new { balance = user.Balance }));
    }

    [HttpGet("bonuses")]
    public async Task<ActionResult<ApiMessage>> Bonuses()
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null) return Unauthorized(new ApiMessage(false, "Сессия истекла"));
        var list = await _context.Bonuses.Where(b => b.PlayerId == user.Id).OrderByDescending(b => b.StartDate).ToListAsync();
        var betCount = await _context.Bets.CountAsync(b => b.PlayerId == user.Id);
        return Ok(new ApiMessage(true, "OK", new
        {
            betsUntilNext = BonusRules.BetsPerFreeBet - betCount % BonusRules.BetsPerFreeBet,
            items = list.Select(b => new
            {
                b.Id,
                b.Description,
                type = b.Type.ToString(),
                b.Amount,
                status = b.Status.ToString(),
                b.StartDate,
                b.EndDate,
                b.BookmakerComment,
                b.UsesRemaining,
                b.UsesTotal,
                canActivate = b.Status == BonusStatus.Pending
            })
        }));
    }

    [HttpPost("bonuses/{id:int}/activate")]
    public async Task<ActionResult<ApiMessage>> ActivateBonus(int id)
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null) return Unauthorized(new ApiMessage(false, "Сессия истекла"));
        var (success, message) = await _bonusService.ActivateAsync(user.Id, id);
        return success ? Ok(new ApiMessage(true, message)) : BadRequest(new ApiMessage(false, message));
    }

    [HttpGet("notifications")]
    public async Task<ActionResult<ApiMessage>> Notifications()
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null) return Unauthorized(new ApiMessage(false, "Сессия истекла"));
        var list = await _context.Notifications.Where(n => n.UserId == user.Id).OrderByDescending(n => n.SentAt).ToListAsync();
        foreach (var n in list.Where(n => n.Status != NotificationStatus.Read))
            n.Status = NotificationStatus.Read;
        await _context.SaveChangesAsync();
        return Ok(new ApiMessage(true, "OK", list.Select(MapNote)));
    }

    private static object MapUser(ApplicationUser user) => new
    {
        id = user.Id,
        email = user.Email,
        firstName = user.FirstName,
        lastName = user.LastName,
        patronymic = user.Patronymic,
        fullName = user.FullName,
        balance = user.Balance,
        countryOfResidence = user.CountryOfResidence.ToString(),
        countryName = CountryPolicy.GetDisplayName(user.CountryOfResidence),
        registrationDate = user.RegistrationDate
    };

    private static object MapNote(Notification n) => new
    {
        n.Id,
        type = n.Type.ToString(),
        text = n.Text,
        sentAt = n.SentAt,
        status = n.Status.ToString()
    };
}

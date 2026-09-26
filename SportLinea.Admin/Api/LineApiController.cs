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
public class LineApiController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IBetService _betService;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IBonusService _bonusService;
    private readonly PlayerLineStore _lineStore;

    public LineApiController(
        ApplicationDbContext context,
        IBetService betService,
        UserManager<ApplicationUser> userManager,
        IBonusService bonusService,
        PlayerLineStore lineStore)
    {
        _context = context;
        _betService = betService;
        _userManager = userManager;
        _bonusService = bonusService;
        _lineStore = lineStore;
    }

    [AllowAnonymous]
    [HttpGet("home")]
    public async Task<ActionResult<ApiMessage>> Home()
    {
        var (events, totalActive) = await LoadPlayerEventsAsync();
        var top = events.OrderByDescending(e => e.Bets.Count).Take(3).Select(MapEvent);
        var newest = events.OrderByDescending(e => e.CreatedAt).Take(3).Select(MapEvent);
        return Ok(new ApiMessage(true, "OK", new
        {
            lineEmpty = events.Count == 0,
            totalActive,
            topEvents = top,
            newEvents = newest
        }));
    }

    [AllowAnonymous]
    [HttpGet("line")]
    public async Task<ActionResult<ApiMessage>> Line([FromQuery] string? sport, [FromQuery] string? category)
    {
        var (events, totalActive) = await LoadPlayerEventsAsync();
        var sports = events.Select(e => e.SportType).Distinct().OrderBy(s => s).ToList();
        var categories = events.Select(e => e.SportCategory).Distinct().OrderBy(c => c).ToList();
        IEnumerable<SportEvent> filtered = events;
        if (!string.IsNullOrWhiteSpace(sport))
            filtered = filtered.Where(e => e.SportType == sport);
        if (!string.IsNullOrWhiteSpace(category))
            filtered = filtered.Where(e => e.SportCategory == category);

        return Ok(new ApiMessage(true, "OK", new
        {
            totalActive,
            displayedCount = filtered.Count(),
            sports,
            categories,
            selectedSport = sport,
            selectedCategory = category,
            events = filtered.Select(MapEvent)
        }));
    }

    [AllowAnonymous]
    [HttpPost("line/refresh")]
    public async Task<ActionResult<ApiMessage>> RefreshLine()
    {
        var allIds = await _context.SportEvents
            .Where(e => e.Status == EventStatus.AcceptingBets && !e.IsDeleted)
            .Select(e => e.Id)
            .ToListAsync();
        var key = await LineKeyAsync();
        var selected = _lineStore.Refresh(key, allIds);
        return Ok(new ApiMessage(true,
            allIds.Count == 0
                ? "Нет активных событий. Дождитесь, пока букмекер обновит линию."
                : $"Линия обновлена: показано {selected.Count} событий.",
            new { count = selected.Count, totalActive = allIds.Count }));
    }

    [AllowAnonymous]
    [HttpGet("events/{id:int}")]
    public async Task<ActionResult<ApiMessage>> Event(int id)
    {
        var sportEvent = await _context.SportEvents
            .Include(e => e.Coefficients)
            .FirstOrDefaultAsync(e => e.Id == id && !e.IsDeleted);

        if (sportEvent == null)
            return NotFound(new ApiMessage(false, "Событие не найдено"));

        object? freeBet = null;
        var user = await _userManager.GetUserAsync(User);
        if (user != null && await _userManager.IsInRoleAsync(user, Roles.Player))
        {
            var bonus = await _bonusService.GetActiveFreeBetAsync(user.Id);
            if (bonus != null)
                freeBet = new { bonus.Id, bonus.Amount };
        }

        return Ok(new ApiMessage(true, "OK", new { evt = MapEvent(sportEvent), freeBet }));
    }

    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpPost("bets")]
    public async Task<ActionResult<ApiMessage>> PlaceBet([FromBody] PlaceBetRequest request)
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null)
            return Unauthorized(new ApiMessage(false, "Сессия истекла"));

        var (success, message, isWin, bonusMessage) =
            await _betService.PlaceBetAsync(user.Id, request.CoefficientId, request.Amount, request.UseFreeBet);

        if (!success)
            return BadRequest(new ApiMessage(false, message));

        await _context.Entry(user).ReloadAsync();
        return Ok(new ApiMessage(true, message, new
        {
            isWin,
            bonusMessage,
            balance = user.Balance
        }));
    }

    [Authorize(AuthenticationSchemes = "Bearer")]
    [HttpGet("bets")]
    public async Task<ActionResult<ApiMessage>> Bets([FromQuery] string? status)
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null)
            return Unauthorized(new ApiMessage(false, "Сессия истекла"));

        var query = _context.Bets.Include(b => b.SportEvent).Where(b => b.PlayerId == user.Id);
        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<BetStatus>(status, true, out var st))
            query = query.Where(b => b.Status == st);

        var bets = await query.OrderByDescending(b => b.CreatedAt).Take(80).Select(b => new
        {
            b.Id,
            eventTitle = b.SportEvent.Title,
            b.OutcomeDescription,
            b.Amount,
            b.CoefficientValue,
            b.Winnings,
            status = b.Status.ToString(),
            createdAt = b.CreatedAt
        }).ToListAsync();

        return Ok(new ApiMessage(true, "OK", bets));
    }

    [AllowAnonymous]
    [HttpGet("results")]
    public async Task<ActionResult<ApiMessage>> Results()
    {
        var events = await _context.SportEvents
            .Include(e => e.Coefficients)
            .Where(e => e.Status == EventStatus.Completed && !e.IsDeleted)
            .OrderByDescending(e => e.StartDate)
            .ToListAsync();
        return Ok(new ApiMessage(true, "OK", events.Select(MapEvent)));
    }

    [AllowAnonymous]
    [HttpGet("rating")]
    public async Task<ActionResult<ApiMessage>> Rating()
    {
        var players = await _context.Users
            .Where(u => u.Bets.Any())
            .Select(u => new
            {
                playerId = u.Id,
                playerName = u.LastName + " " + u.FirstName,
                wins = u.Bets.Count(b => b.Status == BetStatus.Won),
                losses = u.Bets.Count(b => b.Status == BetStatus.Lost),
                totalWinnings = u.Bets.Where(b => b.Status == BetStatus.Won).Sum(b => b.Winnings)
            })
            .OrderByDescending(p => p.totalWinnings)
            .ThenByDescending(p => p.wins)
            .ToListAsync();
        return Ok(new ApiMessage(true, "OK", players));
    }

    private async Task<(List<SportEvent> Events, int TotalActive)> LoadPlayerEventsAsync()
    {
        var all = await _context.SportEvents
            .Include(e => e.Coefficients)
            .Include(e => e.Bets)
            .Where(e => e.Status == EventStatus.AcceptingBets && !e.IsDeleted)
            .ToListAsync();
        var total = all.Count;
        var ids = _lineStore.Get(await LineKeyAsync(), all.Select(e => e.Id).ToList());
        var selected = all.Where(e => ids.Contains(e.Id)).OrderBy(e => e.StartDate).ToList();
        return (selected, total);
    }

    private async Task<string> LineKeyAsync()
    {
        var user = await _userManager.GetUserAsync(User);
        return user?.Id ?? "guest";
    }

    private static object MapEvent(SportEvent e) => new
    {
        e.Id,
        e.Title,
        e.SportType,
        e.SportCategory,
        startDate = e.StartDate,
        status = e.Status.ToString(),
        result = e.Result,
        coefficients = e.Coefficients.Select(c => new
        {
            c.Id,
            c.OutcomeDescription,
            c.Value
        })
    };
}

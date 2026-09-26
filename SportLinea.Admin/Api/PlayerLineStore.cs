using System.Collections.Concurrent;
using SportLinea.Models;

namespace SportLinea.Api;

public class PlayerLineStore
{
    private readonly ConcurrentDictionary<string, int[]> _ids = new();

    public IReadOnlyList<int> Get(string key, IReadOnlyList<int> available)
    {
        if (!_ids.TryGetValue(key, out var stored) || stored.Length == 0)
            return Array.Empty<int>();

        var visible = stored.Where(available.Contains).ToList();
        if (visible.Count == 0)
        {
            _ids.TryRemove(key, out _);
            return Array.Empty<int>();
        }

        return visible;
    }

    public IReadOnlyList<int> Refresh(string key, IReadOnlyList<int> available)
    {
        if (available.Count == 0)
        {
            _ids.TryRemove(key, out _);
            return Array.Empty<int>();
        }

        var selected = available
            .OrderBy(_ => Random.Shared.Next())
            .Take(LineRules.PlayerLineDisplayCount)
            .ToArray();
        _ids[key] = selected;
        return selected;
    }
}

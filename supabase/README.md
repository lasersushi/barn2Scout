# Supabase: AI assistant backend

Two pieces, both deployed by hand with the [Supabase CLI](https://supabase.com/docs/guides/cli):

- `migrations/20261120000000_ai_assistant.sql`: the `profiles.ai_access` flag, the `ai_usage` and `ai_cache` tables, and the budget functions.
- `functions/ai/`: the Edge Function the app calls for every AI feature. It holds the Anthropic API key.

## First deploy

1. Link the CLI to the project (once per machine):

   ```bash
   supabase link --project-ref <your-project-ref>
   ```

2. Apply the migration:

   ```bash
   supabase db push
   ```

3. Store the Anthropic API key as a function secret (create one at console.anthropic.com):

   ```bash
   supabase secrets set ANTHROPIC_API_KEY=<key>
   ```

4. Deploy the function:

   ```bash
   supabase functions deploy ai
   ```

5. Check that every mentor's row in `profiles` has `role` set to `admin` or `super_admin`. The function reads admin status from there, not from the app's email lists.

6. If your Anthropic Console organization offers a spend limit (Settings → Limits), set one as a second safety net.

## Settings (optional function secrets)

| Name | Default | Meaning |
|---|---|---|
| `AI_DAILY_LIMIT` | `20` | Generations per day for scouters without the AI role |
| `AI_MONTH_CAP_USD` | `20` | Team-wide spend per calendar month; everyone is refused past it |
| `AI_YEAR_CAP_USD` | `48` | Team-wide spend per calendar year |
| `AI_ALLOWED_EMAIL_DOMAINS` | `priorypanther.com,prioryca.org` | Non-admin accounts must be on one of these |

Set one with `supabase secrets set NAME=value`. It takes effect on the next request.

## Checking spend

```sql
select date_trunc('month', day) as month, sum(cost_usd) as usd, sum(requests) as requests
from ai_usage group by 1 order by 1 desc;
```

The function computes cost from each response's token counts and its price table (`functions/ai/policy.ts`). The Anthropic Console's usage page is the authoritative bill.

## Tests

```bash
deno test supabase/functions/ai
deno check supabase/functions/ai/index.ts
```

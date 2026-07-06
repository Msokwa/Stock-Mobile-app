-- Run this in your Supabase SQL editor

create extension if not exists pgcrypto;

create table if not exists public.portfolio_holdings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  shares integer not null default 1,
  updated_at timestamptz not null default now(),
  constraint portfolio_holdings_unique_user_symbol unique (user_id, symbol)
);

create table if not exists public.watchlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  updated_at timestamptz not null default now(),
  constraint watchlist_items_unique_user_symbol unique (user_id, symbol)
);

create table if not exists public.portfolio_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  action text not null check (action in ('buy', 'sell')),
  shares integer not null default 1,
  created_at timestamptz not null default now()
);

alter table public.portfolio_holdings enable row level security;
alter table public.watchlist_items enable row level security;
alter table public.portfolio_transactions enable row level security;
-- Policies for portfolio_holdings
DROP POLICY IF EXISTS "Users can view their own portfolio holdings" ON public.portfolio_holdings;
CREATE POLICY "Users can view their own portfolio holdings"
  ON public.portfolio_holdings FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own portfolio holdings" ON public.portfolio_holdings;
CREATE POLICY "Users can insert their own portfolio holdings"
  ON public.portfolio_holdings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own portfolio holdings" ON public.portfolio_holdings;
CREATE POLICY "Users can update their own portfolio holdings"
  ON public.portfolio_holdings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own portfolio holdings" ON public.portfolio_holdings;
CREATE POLICY "Users can delete their own portfolio holdings"
  ON public.portfolio_holdings FOR DELETE
  USING (auth.uid() = user_id);

-- Policies for watchlist_items
DROP POLICY IF EXISTS "Users can view their own watchlist items" ON public.watchlist_items;
CREATE POLICY "Users can view their own watchlist items"
  ON public.watchlist_items FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own watchlist items" ON public.watchlist_items;
CREATE POLICY "Users can insert their own watchlist items"
  ON public.watchlist_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own watchlist items" ON public.watchlist_items;
CREATE POLICY "Users can update their own watchlist items"
  ON public.watchlist_items FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own watchlist items" ON public.watchlist_items;
CREATE POLICY "Users can delete their own watchlist items"
  ON public.watchlist_items FOR DELETE
  USING (auth.uid() = user_id);

-- Policies for portfolio_transactions
DROP POLICY IF EXISTS "Users can view their own portfolio transactions" ON public.portfolio_transactions;
CREATE POLICY "Users can view their own portfolio transactions"
  ON public.portfolio_transactions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own portfolio transactions" ON public.portfolio_transactions;
CREATE POLICY "Users can insert their own portfolio transactions"
  ON public.portfolio_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

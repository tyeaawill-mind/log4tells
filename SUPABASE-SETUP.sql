
-- LOG4TELLS V1 — run once in Supabase SQL Editor.
-- Browser code uses the publishable key + RLS. Never expose a secret/service_role key.

create extension if not exists pgcrypto;
do $$ begin create type public.feed_mode as enum ('relationship','balanced','discovery','chronological'); exception when duplicate_object then null; end $$;
do $$ begin create type public.post_visibility as enum ('public','followers','private'); exception when duplicate_object then null; end $$;
do $$ begin create type public.feedback_type as enum ('show_more','show_less','not_interested','hide','mute_author','mute_topic'); exception when duplicate_object then null; end $$;

create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,username text unique not null check(username ~ '^[a-z0-9_]{3,30}$'),display_name text not null check(length(trim(display_name)) between 1 and 80),bio text,avatar_url text,is_public boolean not null default true,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.follows(follower_id uuid not null references public.profiles(id) on delete cascade,followed_id uuid not null references public.profiles(id) on delete cascade,created_at timestamptz not null default now(),primary key(follower_id,followed_id),check(follower_id<>followed_id));
create table if not exists public.blocks(blocker_id uuid not null references public.profiles(id) on delete cascade,blocked_id uuid not null references public.profiles(id) on delete cascade,created_at timestamptz not null default now(),primary key(blocker_id,blocked_id));
create table if not exists public.mutes(muter_id uuid not null references public.profiles(id) on delete cascade,muted_id uuid references public.profiles(id) on delete cascade,topic text,created_at timestamptz not null default now(),check(muted_id is not null or topic is not null));
create table if not exists public.posts(id uuid primary key default gen_random_uuid(),author_id uuid not null references public.profiles(id) on delete cascade,body text not null check(length(trim(body)) between 1 and 5000),topic text,visibility public.post_visibility not null default 'public',created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.comments(id uuid primary key default gen_random_uuid(),post_id uuid not null references public.posts(id) on delete cascade,author_id uuid not null references public.profiles(id) on delete cascade,body text not null check(length(trim(body)) between 1 and 3000),created_at timestamptz not null default now());
create table if not exists public.reactions(user_id uuid not null references public.profiles(id) on delete cascade,post_id uuid not null references public.posts(id) on delete cascade,kind text not null default 'like',created_at timestamptz not null default now(),primary key(user_id,post_id));
create table if not exists public.feed_preferences(user_id uuid primary key references public.profiles(id) on delete cascade,mode public.feed_mode not null default 'balanced',relationship_weight int not null default 30,interest_weight int not null default 25,freshness_weight int not null default 20,novelty_weight int not null default 10,diversity_weight int not null default 15,max_same_author_in_window int not null default 2,max_same_topic_in_window int not null default 5,updated_at timestamptz not null default now());
create table if not exists public.feed_feedback(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,post_id uuid not null references public.posts(id) on delete cascade,feedback public.feedback_type not null,created_at timestamptz not null default now());
create table if not exists public.feed_impressions(id uuid primary key default gen_random_uuid(),user_id uuid references public.profiles(id) on delete cascade,post_id uuid not null references public.posts(id) on delete cascade,feed_mode public.feed_mode not null,ranking_version text not null,position int not null check(position>=0),reason_codes text[] not null default '{}',created_at timestamptz not null default now());
create table if not exists public.ranking_versions(id uuid primary key default gen_random_uuid(),version text unique not null,description text not null,active boolean not null default false,created_at timestamptz not null default now());
create table if not exists public.saves(user_id uuid not null references public.profiles(id) on delete cascade,post_id uuid not null references public.posts(id) on delete cascade,note text,created_at timestamptz not null default now(),primary key(user_id,post_id));
create table if not exists public.external_references(id uuid primary key default gen_random_uuid(),post_id uuid references public.posts(id) on delete set null,url text not null,title text,publisher text,published_at timestamptz,created_at timestamptz not null default now());

create index if not exists posts_created_idx on public.posts(created_at desc);
create index if not exists posts_author_created_idx on public.posts(author_id,created_at desc);
create index if not exists follows_followed_idx on public.follows(followed_id);
create index if not exists feedback_user_created_idx on public.feed_feedback(user_id,created_at desc);

alter table public.profiles enable row level security; alter table public.follows enable row level security; alter table public.blocks enable row level security; alter table public.mutes enable row level security; alter table public.posts enable row level security; alter table public.comments enable row level security; alter table public.reactions enable row level security; alter table public.feed_preferences enable row level security; alter table public.feed_feedback enable row level security; alter table public.feed_impressions enable row level security; alter table public.ranking_versions enable row level security; alter table public.saves enable row level security; alter table public.external_references enable row level security;

-- Re-runnable policy reset: this script may be run again after an earlier attempt.
do $$ begin
  execute 'drop policy if exists "profiles readable" on public.profiles';
  execute 'drop policy if exists "own profile insert" on public.profiles';
  execute 'drop policy if exists "own profile update" on public.profiles';
  execute 'drop policy if exists "follows readable" on public.follows';
  execute 'drop policy if exists "own follows insert" on public.follows';
  execute 'drop policy if exists "own follows delete" on public.follows';
  execute 'drop policy if exists "own blocks" on public.blocks';
  execute 'drop policy if exists "own mutes" on public.mutes';
  execute 'drop policy if exists "eligible posts readable" on public.posts';
  execute 'drop policy if exists "own posts insert" on public.posts';
  execute 'drop policy if exists "own posts update" on public.posts';
  execute 'drop policy if exists "own posts delete" on public.posts';
  execute 'drop policy if exists "comments readable" on public.comments';
  execute 'drop policy if exists "own comments insert" on public.comments';
  execute 'drop policy if exists "own comments update" on public.comments';
  execute 'drop policy if exists "own comments delete" on public.comments';
  execute 'drop policy if exists "reactions readable" on public.reactions';
  execute 'drop policy if exists "own reactions" on public.reactions';
  execute 'drop policy if exists "own feed preferences" on public.feed_preferences';
  execute 'drop policy if exists "own feedback readable" on public.feed_feedback';
  execute 'drop policy if exists "own feedback insert" on public.feed_feedback';
  execute 'drop policy if exists "own impressions readable" on public.feed_impressions';
  execute 'drop policy if exists "own impressions insert" on public.feed_impressions';
  execute 'drop policy if exists "active ranking versions readable" on public.ranking_versions';
  execute 'drop policy if exists "own saves" on public.saves';
  execute 'drop policy if exists "external refs readable" on public.external_references';
  execute 'drop policy if exists "post authors manage refs" on public.external_references';
end $$;

create policy "profiles readable" on public.profiles for select using(is_public or id=auth.uid());
create policy "own profile insert" on public.profiles for insert to authenticated with check(id=auth.uid());
create policy "own profile update" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "follows readable" on public.follows for select using(true);
create policy "own follows insert" on public.follows for insert to authenticated with check(follower_id=auth.uid());
create policy "own follows delete" on public.follows for delete to authenticated using(follower_id=auth.uid());
create policy "own blocks" on public.blocks for all to authenticated using(blocker_id=auth.uid()) with check(blocker_id=auth.uid());
create policy "own mutes" on public.mutes for all to authenticated using(muter_id=auth.uid()) with check(muter_id=auth.uid());
create policy "eligible posts readable" on public.posts for select using(visibility='public' or author_id=auth.uid() or (visibility='followers' and exists(select 1 from public.follows f where f.follower_id=auth.uid() and f.followed_id=posts.author_id)));
create policy "own posts insert" on public.posts for insert to authenticated with check(author_id=auth.uid());
create policy "own posts update" on public.posts for update to authenticated using(author_id=auth.uid()) with check(author_id=auth.uid());
create policy "own posts delete" on public.posts for delete to authenticated using(author_id=auth.uid());
create policy "comments readable" on public.comments for select using(exists(select 1 from public.posts p where p.id=comments.post_id and (p.visibility='public' or p.author_id=auth.uid() or (p.visibility='followers' and exists(select 1 from public.follows f where f.follower_id=auth.uid() and f.followed_id=p.author_id)))));
create policy "own comments insert" on public.comments for insert to authenticated with check(author_id=auth.uid());
create policy "own comments update" on public.comments for update to authenticated using(author_id=auth.uid()) with check(author_id=auth.uid());
create policy "own comments delete" on public.comments for delete to authenticated using(author_id=auth.uid());
create policy "reactions readable" on public.reactions for select using(true);
create policy "own reactions" on public.reactions for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "own feed preferences" on public.feed_preferences for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "own feedback readable" on public.feed_feedback for select to authenticated using(user_id=auth.uid());
create policy "own feedback insert" on public.feed_feedback for insert to authenticated with check(user_id=auth.uid());
create policy "own impressions readable" on public.feed_impressions for select to authenticated using(user_id=auth.uid());
create policy "own impressions insert" on public.feed_impressions for insert to authenticated with check(user_id=auth.uid());
create policy "active ranking versions readable" on public.ranking_versions for select using(active=true);
create policy "own saves" on public.saves for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "external refs readable" on public.external_references for select using(true);
create policy "post authors manage refs" on public.external_references for all to authenticated using(exists(select 1 from public.posts p where p.id=post_id and p.author_id=auth.uid())) with check(exists(select 1 from public.posts p where p.id=post_id and p.author_id=auth.uid()));

insert into public.ranking_versions(version,description,active) values('v1-transparent','User-controlled ranking: relationship, freshness, novelty, diversity and explicit feedback. Reaction count is not the sole ranking signal.',true)
on conflict(version) do update set active=true,description=excluded.description;

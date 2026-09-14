
create extension if not exists pgcrypto;
create extension if not exists vector;

-- Table for storing chunks + embeddings
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  metadata jsonb default '{}'::jsonb,
  embedding vector(768) not null,
  created_at timestamptz default now()
);

-- Vector index
create index if not exists documents_embedding_hnsw
on public.documents
using hnsw (embedding vector_cosine_ops);

-- Function used for vector similarity search
create or replace function public.match_documents(
  query_embedding vector(768),
  match_count int default 5
)
returns table (
  id uuid,
  content text,
  metadata jsonb,
  similarity float
)
language sql stable
as $$
  select
    d.id,
    d.content,
    d.metadata,
    1 - (d.embedding <=> query_embedding) as similarity
  from public.documents d
  order by d.embedding <=> query_embedding
  limit match_count;
$$;

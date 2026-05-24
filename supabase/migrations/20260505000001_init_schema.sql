-- BikinStiker initial schema
-- Tables: user_wallets, credit_transactions, sticker_generations
-- RPCs:   deduct_credit_for_sticker, refund_failed_sticker
-- RLS:    SELECT-only for owners; all mutations go through SECURITY DEFINER RPCs or service role.

-- ---------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------

CREATE TABLE public.user_wallets (
    user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
    balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TYPE transaction_type AS ENUM ('topup', 'daily_reward', 'generate_sticker', 'refund');

CREATE TABLE public.credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    amount INTEGER NOT NULL,
    type transaction_type NOT NULL,
    reference_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE INDEX credit_transactions_user_created_idx
    ON public.credit_transactions (user_id, created_at DESC);

CREATE TABLE public.sticker_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    preset_name TEXT NOT NULL,
    user_prompt TEXT NOT NULL,
    final_prompt TEXT NOT NULL,
    image_url TEXT,
    cost INTEGER NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE INDEX sticker_generations_user_created_idx
    ON public.sticker_generations (user_id, created_at DESC);

-- ---------------------------------------------------------------
-- RPC: atomic credit deduction + sticker row creation
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.deduct_credit_for_sticker(
    p_user_id UUID, p_cost INTEGER, p_preset TEXT, p_prompt TEXT
) RETURNS UUID
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
AS $$
DECLARE
    current_balance INTEGER;
    new_sticker_id  UUID;
BEGIN
    SELECT balance INTO current_balance
        FROM public.user_wallets
        WHERE user_id = p_user_id
        FOR UPDATE;

    IF current_balance IS NULL THEN
        RAISE EXCEPTION 'Wallet not found for user';
    END IF;

    IF current_balance < p_cost THEN
        RAISE EXCEPTION 'Insufficient credits';
    END IF;

    UPDATE public.user_wallets
        SET balance = balance - p_cost,
            updated_at = now()
        WHERE user_id = p_user_id;

    INSERT INTO public.sticker_generations
        (user_id, preset_name, user_prompt, final_prompt, cost, status)
    VALUES
        (p_user_id, p_preset, p_prompt, 'pending_generation', p_cost, 'pending')
    RETURNING id INTO new_sticker_id;

    INSERT INTO public.credit_transactions (user_id, amount, type, reference_id)
    VALUES (p_user_id, -p_cost, 'generate_sticker', new_sticker_id);

    RETURN new_sticker_id;
END;
$$;

-- ---------------------------------------------------------------
-- RPC: refund credits when generation fails downstream
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.refund_failed_sticker(p_sticker_id UUID)
RETURNS VOID
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_cost    INTEGER;
    v_status  TEXT;
BEGIN
    SELECT user_id, cost, status
        INTO v_user_id, v_cost, v_status
        FROM public.sticker_generations
        WHERE id = p_sticker_id
        FOR UPDATE;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Sticker generation not found';
    END IF;

    IF v_status = 'failed' OR v_status = 'success' THEN
        -- already finalized, do not double-refund
        RETURN;
    END IF;

    UPDATE public.sticker_generations
        SET status = 'failed'
        WHERE id = p_sticker_id;

    UPDATE public.user_wallets
        SET balance = balance + v_cost,
            updated_at = now()
        WHERE user_id = v_user_id;

    INSERT INTO public.credit_transactions (user_id, amount, type, reference_id)
    VALUES (v_user_id, v_cost, 'refund', p_sticker_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.deduct_credit_for_sticker(UUID, INTEGER, TEXT, TEXT) TO authenticated;
-- refund_failed_sticker is intentionally NOT granted to authenticated;
-- only the edge function (service role) may invoke it.

-- ---------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------

ALTER TABLE public.user_wallets         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sticker_generations  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallet"
    ON public.user_wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own transactions"
    ON public.credit_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own stickers"
    ON public.sticker_generations
    FOR SELECT USING (auth.uid() = user_id);

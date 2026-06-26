-- Hardening: drop caller-supplied p_user_id from deduct_credit_for_sticker.
-- The function now derives the target user from auth.uid() so an authenticated
-- caller can only ever deduct from their own wallet. The previous 4-arg
-- overload let a SECURITY DEFINER RPC (which bypasses RLS) be called with an
-- arbitrary p_user_id, allowing user A to decrement user B's balance.
--
-- Non-destructive: the old signature is dropped (no other callers in this
-- repo) and replaced with the 3-arg version. The accompanying edge function
-- is updated in the same release to match the new signature.

DROP FUNCTION IF EXISTS public.deduct_credit_for_sticker(UUID, INTEGER, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.deduct_credit_for_sticker(
    p_cost INTEGER, p_preset TEXT, p_prompt TEXT
) RETURNS UUID
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
AS $$
DECLARE
    v_user_id       UUID;
    current_balance INTEGER;
    new_sticker_id  UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT balance INTO current_balance
        FROM public.user_wallets
        WHERE user_id = v_user_id
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
        WHERE user_id = v_user_id;

    INSERT INTO public.sticker_generations
        (user_id, preset_name, user_prompt, final_prompt, cost, status)
    VALUES
        (v_user_id, p_preset, p_prompt, 'pending_generation', p_cost, 'pending')
    RETURNING id INTO new_sticker_id;

    INSERT INTO public.credit_transactions (user_id, amount, type, reference_id)
    VALUES (v_user_id, -p_cost, 'generate_sticker', new_sticker_id);

    RETURN new_sticker_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.deduct_credit_for_sticker(INTEGER, TEXT, TEXT) TO authenticated;

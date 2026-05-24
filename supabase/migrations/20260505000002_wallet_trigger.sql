-- Auto-provision a wallet (with starter credits) for every new auth user.
-- Starter grant: 5 credits, recorded as a 'topup' transaction.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
AS $$
DECLARE
    v_starter_credits CONSTANT INTEGER := 5;
BEGIN
    INSERT INTO public.user_wallets (user_id, balance)
    VALUES (NEW.id, v_starter_credits);

    INSERT INTO public.credit_transactions (user_id, amount, type)
    VALUES (NEW.id, v_starter_credits, 'topup');

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

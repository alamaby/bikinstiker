-- Private storage bucket for generated stickers.
-- Object path convention: stickers/{user_id}/{sticker_id}.png
-- Reads happen via short-lived signed URLs minted by the edge function (service role).

INSERT INTO storage.buckets (id, name, public)
VALUES ('stickers', 'stickers', false)
ON CONFLICT (id) DO NOTHING;

-- Owners may list/read their own objects (storage.foldername()[1] is the first path segment).
DROP POLICY IF EXISTS "Owners can read own sticker objects" ON storage.objects;
CREATE POLICY "Owners can read own sticker objects"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'stickers'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- No INSERT/UPDATE/DELETE policies for authenticated users — uploads happen
-- exclusively from the generate-sticker edge function using the service role key.

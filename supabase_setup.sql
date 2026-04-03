-- =============================================================================
-- Kiangthai Services - Supabase Setup SQL
-- Safe to re-run: uses IF NOT EXISTS and DROP POLICY IF EXISTS
-- =============================================================================


-- =============================================================================
-- SECTION 1: profiles table - Add columns
-- =============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'customer'
    CHECK (role IN ('customer', 'technician', 'admin'));

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;


-- =============================================================================
-- SECTION 2: Enable Row Level Security
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- SECTION 3: profiles RLS policies
-- =============================================================================

-- SELECT: users can read their own profile
DROP POLICY IF EXISTS "profiles: users can select own row" ON public.profiles;
CREATE POLICY "profiles: users can select own row"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- UPDATE: users can update their own profile
DROP POLICY IF EXISTS "profiles: users can update own row" ON public.profiles;
CREATE POLICY "profiles: users can update own row"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- INSERT: users can insert their own profile (sign-up flow)
DROP POLICY IF EXISTS "profiles: users can insert own row" ON public.profiles;
CREATE POLICY "profiles: users can insert own row"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);


-- =============================================================================
-- SECTION 4: bookings RLS policies
-- =============================================================================

-- Helper: inline role lookup used across policies
-- auth.uid() must match profiles.id, and profiles.role must equal the target role.

-- CUSTOMERS --

-- Customers can create bookings for themselves
DROP POLICY IF EXISTS "bookings: customers can insert own bookings" ON public.bookings;
CREATE POLICY "bookings: customers can insert own bookings"
  ON public.bookings
  FOR INSERT
  WITH CHECK (
    auth.uid() = customer_id
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'customer'
  );

-- Customers can read their own bookings
DROP POLICY IF EXISTS "bookings: customers can select own bookings" ON public.bookings;
CREATE POLICY "bookings: customers can select own bookings"
  ON public.bookings
  FOR SELECT
  USING (
    auth.uid() = customer_id
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'customer'
  );

-- Customers can update their own pending bookings (e.g. cancellation)
DROP POLICY IF EXISTS "bookings: customers can update own pending bookings" ON public.bookings;
CREATE POLICY "bookings: customers can update own pending bookings"
  ON public.bookings
  FOR UPDATE
  USING (
    auth.uid() = customer_id
    AND status = 'pending'
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'customer'
  )
  WITH CHECK (
    auth.uid() = customer_id
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'customer'
  );

-- TECHNICIANS --

-- Technicians can view all pending bookings (job board)
DROP POLICY IF EXISTS "bookings: technicians can select pending bookings" ON public.bookings;
CREATE POLICY "bookings: technicians can select pending bookings"
  ON public.bookings
  FOR SELECT
  USING (
    status = 'pending'
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'technician'
  );

-- Technicians can view bookings assigned to them
DROP POLICY IF EXISTS "bookings: technicians can select assigned bookings" ON public.bookings;
CREATE POLICY "bookings: technicians can select assigned bookings"
  ON public.bookings
  FOR SELECT
  USING (
    auth.uid() = technician_id
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'technician'
  );

-- Technicians can update any pending booking (accept / reject)
DROP POLICY IF EXISTS "bookings: technicians can update pending bookings" ON public.bookings;
CREATE POLICY "bookings: technicians can update pending bookings"
  ON public.bookings
  FOR UPDATE
  USING (
    status = 'pending'
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'technician'
  )
  WITH CHECK (
    (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'technician'
  );

-- Technicians can update bookings assigned to them (mark complete, etc.)
DROP POLICY IF EXISTS "bookings: technicians can update assigned bookings" ON public.bookings;
CREATE POLICY "bookings: technicians can update assigned bookings"
  ON public.bookings
  FOR UPDATE
  USING (
    auth.uid() = technician_id
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'technician'
  )
  WITH CHECK (
    auth.uid() = technician_id
    AND (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'technician'
  );

-- ADMINS --

-- Admins can read all bookings
DROP POLICY IF EXISTS "bookings: admins can select all bookings" ON public.bookings;
CREATE POLICY "bookings: admins can select all bookings"
  ON public.bookings
  FOR SELECT
  USING (
    (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'admin'
  );

-- Admins can update any booking
DROP POLICY IF EXISTS "bookings: admins can update any booking" ON public.bookings;
CREATE POLICY "bookings: admins can update any booking"
  ON public.bookings
  FOR UPDATE
  USING (
    (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'admin'
  )
  WITH CHECK (
    (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'admin'
  );


-- =============================================================================
-- SECTION 5: messages table (chat feature)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.messages (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID        NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  sender_id  UUID        NOT NULL REFERENCES auth.users(id),
  sender_role TEXT       NOT NULL CHECK (sender_role IN ('customer', 'technician', 'admin')),
  content    TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Users involved in the booking (customer or assigned technician) can read messages
DROP POLICY IF EXISTS "messages: booking participants can select" ON public.messages;
CREATE POLICY "messages: booking participants can select"
  ON public.messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.id = messages.booking_id
        AND (b.customer_id = auth.uid() OR b.technician_id = auth.uid())
    )
    OR (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'admin'
  );

-- Users can insert messages where they are the sender
DROP POLICY IF EXISTS "messages: users can insert own messages" ON public.messages;
CREATE POLICY "messages: users can insert own messages"
  ON public.messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.id = messages.booking_id
        AND (b.customer_id = auth.uid() OR b.technician_id = auth.uid())
    )
  );


-- =============================================================================
-- SECTION 6: Storage bucket - booking-images (public read)
-- =============================================================================

-- Create the bucket (public = true means unauthenticated reads are allowed)
INSERT INTO storage.buckets (id, name, public)
VALUES ('booking-images', 'booking-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;


-- =============================================================================
-- SECTION 7: Storage RLS policies - booking-images
-- =============================================================================

-- Authenticated users can upload objects to booking-images
DROP POLICY IF EXISTS "booking-images: authenticated users can upload" ON storage.objects;
CREATE POLICY "booking-images: authenticated users can upload"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'booking-images');

-- Anyone (including anonymous) can read objects from booking-images
DROP POLICY IF EXISTS "booking-images: public read access" ON storage.objects;
CREATE POLICY "booking-images: public read access"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'booking-images');

-- Authenticated users can update their own uploads (e.g. replace image)
DROP POLICY IF EXISTS "booking-images: authenticated users can update own objects" ON storage.objects;
CREATE POLICY "booking-images: authenticated users can update own objects"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'booking-images' AND owner = auth.uid())
  WITH CHECK (bucket_id = 'booking-images');

-- Authenticated users can delete their own uploads
DROP POLICY IF EXISTS "booking-images: authenticated users can delete own objects" ON storage.objects;
CREATE POLICY "booking-images: authenticated users can delete own objects"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'booking-images' AND owner = auth.uid());


-- =============================================================================
-- END OF SETUP
-- =============================================================================

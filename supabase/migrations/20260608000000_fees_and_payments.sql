-- ---------------------------------------------------------
-- FEES & PAYMENTS
-- ---------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_status') THEN
    CREATE TYPE invoice_status AS ENUM ('pending', 'partial', 'paid', 'overdue');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.fee_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  academic_year_id UUID REFERENCES public.academic_years(id) ON DELETE SET NULL,
  class_id UUID REFERENCES public.classes(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  amount NUMERIC NOT NULL CHECK (amount >= 0),
  due_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  fee_structure_id UUID NOT NULL REFERENCES public.fee_structures(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL CHECK (amount >= 0),
  amount_paid NUMERIC DEFAULT 0 NOT NULL CHECK (amount_paid >= 0),
  status invoice_status DEFAULT 'pending' NOT NULL,
  due_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE (student_id, fee_structure_id)
);

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL CHECK (amount > 0),
  payment_method TEXT NOT NULL DEFAULT 'cash',
  reference TEXT,
  recorded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  paid_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE OR REPLACE FUNCTION public.is_accountant()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'accountant'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_invoice_balance()
RETURNS TRIGGER AS $$
DECLARE
  target_invoice_id UUID;
  total_paid NUMERIC;
  invoice_amount NUMERIC;
  invoice_due DATE;
BEGIN
  target_invoice_id := COALESCE(NEW.invoice_id, OLD.invoice_id);

  SELECT COALESCE(SUM(amount), 0) INTO total_paid
  FROM public.payments WHERE invoice_id = target_invoice_id;

  SELECT amount, due_date INTO invoice_amount, invoice_due
  FROM public.invoices WHERE id = target_invoice_id;

  UPDATE public.invoices SET
    amount_paid = total_paid,
    status = CASE
      WHEN total_paid >= invoice_amount THEN 'paid'::invoice_status
      WHEN total_paid > 0 THEN 'partial'::invoice_status
      WHEN invoice_due IS NOT NULL AND invoice_due < CURRENT_DATE THEN 'overdue'::invoice_status
      ELSE 'pending'::invoice_status
    END
  WHERE id = target_invoice_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_payment_recorded ON public.payments;
CREATE TRIGGER on_payment_recorded
  AFTER INSERT OR UPDATE OR DELETE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.update_invoice_balance();

ALTER TABLE public.fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow admins/accountants to manage fee structures"
  ON public.fee_structures FOR ALL
  USING (public.is_admin() OR public.is_accountant());

CREATE POLICY "Allow authenticated users to view fee structures"
  ON public.fee_structures FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins/accountants to manage invoices"
  ON public.invoices FOR ALL
  USING (public.is_admin() OR public.is_accountant());

CREATE POLICY "Allow students to view own invoices"
  ON public.invoices FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Allow parents to view children invoices"
  ON public.invoices FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.student_parents sp
      WHERE sp.parent_id = auth.uid() AND sp.student_id = student_id
    )
  );

CREATE POLICY "Allow admins/accountants to manage payments"
  ON public.payments FOR ALL
  USING (public.is_admin() OR public.is_accountant());

CREATE POLICY "Allow students to view own payments"
  ON public.payments FOR SELECT
  USING (auth.uid() = student_id);

CREATE POLICY "Allow parents to view children payments"
  ON public.payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.student_parents sp
      WHERE sp.parent_id = auth.uid() AND sp.student_id = student_id
    )
  );

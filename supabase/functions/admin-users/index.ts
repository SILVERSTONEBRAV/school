import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()

    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    const { data: actorProfile, error: profileError } = await userClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError || actorProfile?.role !== 'admin') {
      throw new Error('Admin access required')
    }

    const adminClient = createClient(supabaseUrl, serviceKey)
    const body = await req.json()
    const { action, ...payload } = body

    const logAudit = async (
      auditAction: string,
      targetUserId?: string,
      details: Record<string, unknown> = {},
    ) => {
      await adminClient.from('admin_audit_log').insert({
        actor_id: user.id,
        action: auditAction,
        target_user_id: targetUserId ?? null,
        details,
      })
    }

    switch (action) {
      case 'create_user': {
        const {
          email,
          password,
          first_name,
          last_name,
          role,
          phone_number,
          school_id,
          status,
          roll_number,
          date_of_birth,
          address,
          occupation,
          employee_id,
          job_title,
          department,
        } = payload

        const { data, error } = await adminClient.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: {
            first_name,
            last_name,
            role,
            phone_number,
            school_id,
            status: status ?? 'active',
            created_by_admin: true,
            roll_number,
            date_of_birth,
            address,
            occupation,
            employee_id,
            job_title,
            department,
          },
        })

        if (error) throw error

        await logAudit('create_user', data.user?.id, { email, role })

        return new Response(
          JSON.stringify({ user_id: data.user?.id, email: data.user?.email }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          },
        )
      }

      case 'update_password': {
        const { user_id, password } = payload
        if (!user_id || !password || password.length < 6) {
          throw new Error('Valid user_id and password (min 6 chars) required')
        }

        const { error } = await adminClient.auth.admin.updateUserById(user_id, {
          password,
        })
        if (error) throw error

        await logAudit('update_password', user_id)

        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      case 'delete_user': {
        const { user_id } = payload
        const { error } = await adminClient.auth.admin.deleteUser(user_id)
        if (error) throw error

        await logAudit('delete_user', user_id)

        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      default:
        throw new Error(`Unknown action: ${action}`)
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

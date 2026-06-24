import { createClient } from '@supabase/supabase-js'
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js'

let supabase = null

export function initSupabase(url, key) {
  supabase = createClient(url || SUPABASE_URL, key || SUPABASE_ANON_KEY)
  return supabase
}

export function getSupabase() {
  if (!supabase) throw new Error('Supabase not initialized')
  return supabase
}

export async function signUp(email, password, username) {
  const { data, error } = await getSupabase().auth.signUp({
    email, password,
    options: { data: { username } }
  })
  return { data, error }
}

export async function signIn(email, password) {
  const { data, error } = await getSupabase().auth.signInWithPassword({ email, password })
  return { data, error }
}

export async function signOut() {
  return await getSupabase().auth.signOut()
}

export function onAuthChange(callback) {
  return getSupabase().auth.onAuthStateChange(callback)
}

export async function getCurrentUser() {
  const { data } = await getSupabase().auth.getUser()
  return data?.user || null
}

export async function fetchApprovedJobs(filters = {}) {
  let query = getSupabase()
    .from('jobs')
    .select('*')
    .eq('status', 'approved')
    .order('created_at', { ascending: false })
  if (filters.city && filters.city !== 'all') query = query.eq('city', filters.city)
  if (filters.type && filters.type !== 'all') query = query.eq('type', filters.type)
  if (filters.education && filters.education !== 'all') query = query.eq('education', filters.education)
  if (filters.friendlyOnly) query = query.eq('friendly_label', true)
  if (filters.search) query = query.or(`company.ilike.%${filters.search}%,title.ilike.%${filters.search}%`)
  const { data, error } = await query
  return { data: data || [], error }
}

export async function submitJob(jobData) {
  const user = await getCurrentUser()
  const { data, error } = await getSupabase()
    .from('jobs').insert({ ...jobData, status: 'pending', source: '用户投稿', submitted_by: user?.id }).select()
  return { data, error }
}

export async function fetchPendingJobs() {
  const { data, error } = await getSupabase()
    .from('jobs').select('*, profiles!jobs_submitted_by_fkey(username)').eq('status', 'pending').order('created_at', { ascending: false })
  return { data: data || [], error }
}

export async function fetchAllJobs() {
  const { data, error } = await getSupabase()
    .from('jobs').select('*, profiles!jobs_submitted_by_fkey(username)').order('created_at', { ascending: false })
  return { data: data || [], error }
}

export async function approveJob(jobId) {
  return await getSupabase().from('jobs').update({ status: 'approved' }).eq('id', jobId)
}

export async function rejectJob(jobId, reason) {
  return await getSupabase().from('jobs').update({ status: 'rejected', rejected_reason: reason }).eq('id', jobId)
}

export async function updateJob(jobId, updates) {
  return await getSupabase().from('jobs').update(updates).eq('id', jobId)
}

export async function deleteJob(jobId) {
  return await getSupabase().from('jobs').delete().eq('id', jobId)
}

export async function fetchUserBookmarks(userId) {
  const { data, error } = await getSupabase()
    .from('bookmarks').select('*, jobs(*)').eq('user_id', userId)
  return { data: data || [], error }
}

export async function addBookmark(userId, jobId) {
  const { data, error } = await getSupabase()
    .from('bookmarks').insert({ user_id: userId, job_id: jobId }).select()
  return { data, error }
}

export async function removeBookmark(bookmarkId) {
  return await getSupabase().from('bookmarks').delete().eq('id', bookmarkId)
}

export async function updateApplicationStatus(bookmarkId, status) {
  return await getSupabase().from('bookmarks').update({ application_status: status }).eq('id', bookmarkId)
}

export async function getUserProfile(userId) {
  const { data, error } = await getSupabase()
    .from('profiles').select('*').eq('id', userId).single()
  return { data, error }
}

export async function getUserRole(userId) {
  try {
    const { data } = await getSupabase()
      .from('profiles').select('role').eq('id', userId).single()
    return data?.role || 'user'
  } catch (e) {
    return 'user'
  }
}

export interface Profile {
  id: string
  username: string | null
  displayName: string | null
  avatarUrl: string | null
  promptpay: string | null
  onboardingCompleted: boolean
  locale: 'th' | 'en'
  createdAt: string
  updatedAt: string
}

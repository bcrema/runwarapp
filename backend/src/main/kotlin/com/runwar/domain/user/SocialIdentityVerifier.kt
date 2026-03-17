package com.runwar.domain.user

data class SocialVerificationRequest(
    val provider: SocialAuthProvider,
    val idToken: String,
    val nonce: String? = null,
    val emailHint: String? = null,
    val givenName: String? = null,
    val familyName: String? = null,
    val avatarUrl: String? = null
)

data class VerifiedSocialIdentity(
    val provider: SocialAuthProvider,
    val subject: String,
    val email: String?,
    val emailVerified: Boolean,
    val displayName: String?,
    val avatarUrl: String?
)

interface SocialIdentityVerifier {
    fun verify(request: SocialVerificationRequest): VerifiedSocialIdentity
}

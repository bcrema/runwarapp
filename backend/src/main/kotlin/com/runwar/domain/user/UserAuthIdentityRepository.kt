package com.runwar.domain.user

import java.util.UUID
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query

interface UserAuthIdentityRepository : JpaRepository<UserAuthIdentity, UUID> {
    @Query(
        """
        SELECT identity
        FROM UserAuthIdentity identity
        JOIN FETCH identity.user user
        LEFT JOIN FETCH user.bandeira
        WHERE identity.provider = :provider
          AND identity.providerSubject = :providerSubject
        """
    )
    fun findWithUserByProviderAndProviderSubject(
        provider: SocialAuthProvider,
        providerSubject: String
    ): UserAuthIdentity?
}

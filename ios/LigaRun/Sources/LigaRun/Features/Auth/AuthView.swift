import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var activeIndex = 0
    @State private var appleNonce: String?
    private let timer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    private let slides: [Slide] = [
        .init(kicker: "Conquista em tempo real",
              title: "Corra e capture áreas",
              description: "Suas rotas viram influência no mapa. Cada loop aumenta o controle da sua bandeira.",
              stat: "250m",
              statLabel: "Raio médio de cada área"),
        .init(kicker: "Defesa inteligente",
              title: "Proteja sua zona",
              description: "Áreas conquistadas ganham escudo. Defenda com corridas rápidas para não perder terreno.",
              stat: "+20",
              statLabel: "Escudo em cada defesa"),
        .init(kicker: "Comunidade em movimento",
              title: "Equipe domina regiões",
              description: "Junte sua assessoria ou grupo. A estratégia coletiva muda o ranking semanal.",
              stat: "6",
              statLabel: "Semanas por temporada")
    ]

    private let benefits: [Benefit] = [
        .init(title: "Ações diárias", description: "Ganhe novas ações a cada dia e mantenha a disputa viva mesmo com treinos curtos."),
        .init(title: "Bandeiras ativas", description: "Crie uma bandeira para sua assessoria e domine os tiles mais estratégicos."),
        .init(title: "Ranking dinâmico", description: "Acompanhe a evolução por temporada e mostre consistência.")
    ]

    private let palette = Palette()

    init(session: any SessionManaging) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroSection
                carouselSection
                benefitSection
                formSection
                socialSection
                finalCTA
            }
            .padding(.bottom, 32)
        }
        .background(appBackground)
        .sheet(item: $viewModel.socialLinkChallenge) { challenge in
            linkSheet(challenge: challenge)
        }
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                activeIndex = activeIndex >= slides.count - 1 ? 0 : activeIndex + 1
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#131522"), Color(hex: "#0b0d14")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(glowGrid)
                .overlay(angularAccent, alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 14) {
                Text("LigaRun")
                    .font(.caption.weight(.medium))
                    .foregroundColor(palette.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(palette.accentPrimary.opacity(0.15))
                    .clipShape(Capsule())

                Text("O mapa da cidade virou o seu campo de treino.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Capture áreas correndo, fortaleça sua bandeira e suba no ranking local em tempo real.")
                    .foregroundColor(palette.textSecondary)
                    .font(.callout)

                HStack(spacing: 12) {
                    primaryCTA
                    secondaryCTA
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .padding(.horizontal)
    }

    private var carouselSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Como funciona")
                .font(.headline)
                .foregroundColor(palette.textPrimary)
                .padding(.horizontal)

            TabView(selection: $activeIndex) {
                ForEach(slides.indices, id: \.self) { index in
                    let slide = slides[index]
                    VStack(alignment: .leading, spacing: 10) {
                        Text(slide.kicker.uppercased())
                            .font(.caption)
                            .foregroundColor(palette.success)
                        Text(slide.title)
                            .font(.title2.bold())
                            .foregroundColor(palette.textPrimary)
                        Text(slide.description)
                            .font(.callout)
                            .foregroundColor(palette.textSecondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slide.stat)
                                .font(.largeTitle.weight(.semibold))
                                .foregroundColor(palette.accentSecondary)
                            Text(slide.statLabel)
                                .font(.subheadline)
                                .foregroundColor(palette.textMuted)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(palette.bgTertiary.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 16)
                    .tag(index)
                }
            }
            .frame(height: 230)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
    }

    private var benefitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Por que usar")
                .font(.headline)
                .foregroundColor(palette.textPrimary)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(benefits, id: \.title) { benefit in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(benefit.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(palette.textPrimary)
                        Text(benefit.description)
                            .font(.caption)
                            .foregroundColor(palette.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.isRegistering ? "Criar conta" : "Entrar")
                .font(.headline)
                .foregroundColor(palette.textPrimary)

            VStack(spacing: 14) {
                textField("Email", text: $viewModel.email, keyboard: .emailAddress)

                if viewModel.isRegistering {
                    textField("Nome de usuário", text: $viewModel.username, keyboard: .default)
                }

                secureField("Senha", text: $viewModel.password)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button {
                Task { await viewModel.submit() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(viewModel.isRegistering ? "Criar conta" : "Entrar")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: [palette.accentPrimary, palette.accentSecondary],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isLoading)

            Button(viewModel.isRegistering ? "Já tenho conta" : "Quero me registrar") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    viewModel.isRegistering.toggle()
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(palette.textSecondary)
        }
        .padding()
        .background(palette.bgTertiary)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(palette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Continuar com")
                .font(.headline)
                .foregroundColor(palette.textPrimary)
                .padding(.horizontal)

            HStack(spacing: 12) {
                SignInWithAppleButton(.signIn, onRequest: configureAppleRequest, onCompletion: handleAppleCompletion)
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .disabled(viewModel.socialLoading)

                Button {
                    handleGoogleSignIn()
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .font(.headline)
                        Text("Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundColor(palette.textPrimary)
                    .background(palette.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
                .disabled(viewModel.socialLoading)
            }
            .padding(.horizontal)
        }
    }

    private var finalCTA: some View {
        VStack(spacing: 8) {
            Text("Pronto para correr com propósito?")
                .font(.headline)
                .foregroundColor(palette.textPrimary)
            Text("Entre no LigaRun e transforme suas rotas em território conquistado.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(palette.textSecondary)
            primaryCTA
        }
        .padding(.horizontal)
    }

    // MARK: - Components

    private var appBackground: some View {
        LinearGradient(
            colors: [palette.bgPrimary, palette.bgSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var glowGrid: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Path { path in
                let step: CGFloat = 28
                stride(from: 0, through: size.width, by: step).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: 0, through: size.height, by: step).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.04), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var angularAccent: some View {
        LinearGradient(
            colors: [
                palette.success.opacity(0.25),
                Color.clear
            ],
            startPoint: .topTrailing,
            endPoint: .center
        )
        .frame(width: 160, height: 160)
        .blur(radius: 40)
        .offset(x: 20, y: -20)
    }

    private var primaryCTA: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                viewModel.isRegistering = true
            }
        } label: {
            Text("Criar conta")
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(LinearGradient(colors: [palette.accentPrimary, palette.accentSecondary],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }

    private var secondaryCTA: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                viewModel.isRegistering = false
            }
        } label: {
            Text("Entrar")
                .fontWeight(.semibold)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(palette.bgTertiary)
                .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                .foregroundColor(palette.textPrimary)
                .clipShape(Capsule())
        }
    }

    private func textField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textContentType(keyboard == .emailAddress ? .emailAddress : .username)
            .autocapitalization(.none)
            .padding()
            .background(palette.bgTertiary)
            .foregroundColor(palette.textPrimary) // Force readable text color
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accentColor(palette.accentPrimary) // Cursor color
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textContentType(.password)
            .padding()
            .background(palette.bgTertiary)
            .foregroundColor(palette.textPrimary) // Force readable text color
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accentColor(palette.accentPrimary) // Cursor color
    }

    private func linkSheet(challenge: AuthViewModel.SocialLinkChallenge) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("\(challenge.provider.displayName) já está vinculado")
                    .font(.headline)
                    .foregroundColor(palette.textPrimary)

                Text("Confirme sua conta \(challenge.emailMasked ?? "") para vincular o provedor social.")
                    .font(.subheadline)
                    .foregroundColor(palette.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    textField("Email", text: $viewModel.linkEmail, keyboard: .emailAddress)
                    secureField("Senha", text: $viewModel.linkPassword)
                }

                if let linkError = viewModel.linkError, !linkError.isEmpty {
                    Text(linkError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await viewModel.confirmLink()
                    }
                } label: {
                    HStack {
                        if viewModel.socialLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text("Confirmar vínculo")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [palette.accentPrimary, palette.accentSecondary],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.socialLoading)
            }
            .padding()
            .background(palette.bgPrimary)
            .presentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.socialLinkChallenge = nil
                    }
                }
            }
        }
    }

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        appleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                viewModel.errorMessage = "Não foi possível recuperar o token Apple."
                appleNonce = nil
                return
            }

            let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            let email = credential.email
            let givenName = credential.fullName?.givenName
            let familyName = credential.fullName?.familyName

            Task {
                await viewModel.handleSocialToken(
                    provider: .apple,
                    idToken: idToken,
                    authorizationCode: authorizationCode,
                    nonce: appleNonce,
                    emailHint: email,
                    givenName: givenName,
                    familyName: familyName,
                    avatarUrl: nil
                )
            }
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
        }

        appleNonce = nil
    }

    private func handleGoogleSignIn() {
        guard let clientID = AppEnvironment.googleClientID else {
            viewModel.errorMessage = "Configuração do Google Sign-In ausente."
            return
        }
        guard let controller = rootViewController() else {
            viewModel.errorMessage = "Não foi possível abrir o Google Sign-In."
            return
        }

        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration

        Task {
            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: controller)
                guard let idToken = result.user.idToken?.tokenString else {
                    throw URLError(.badServerResponse)
                }

                let avatar = result.user.profile?.imageURL(withDimension: 120)?.absoluteString
                let email = result.user.profile?.email
                let givenName = result.user.profile?.givenName
                let familyName = result.user.profile?.familyName

                await viewModel.handleSocialToken(
                    provider: .google,
                    idToken: idToken,
                    authorizationCode: nil,
                    nonce: nil,
                    emailHint: email,
                    givenName: givenName,
                    familyName: familyName,
                    avatarUrl: avatar
                )
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
        }
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Models

private struct Slide {
    let kicker: String
    let title: String
    let description: String
    let stat: String
    let statLabel: String
}

private struct Benefit {
    let title: String
    let description: String
}

private struct Palette {
    let bgPrimary = Color(hex: "#0A0A0F")
    let bgSecondary = Color(hex: "#12121A")
    let bgTertiary = Color(hex: "#1A1A24")
    let accentPrimary = Color(hex: "#6366F1")
    let accentSecondary = Color(hex: "#8B5CF6")
    let textPrimary = Color(hex: "#F8FAFC")
    let textSecondary = Color(hex: "#94A3B8")
    let textMuted = Color(hex: "#64748B")
    let border = Color.white.opacity(0.08)
    let success = Color(hex: "#22C55E")
}

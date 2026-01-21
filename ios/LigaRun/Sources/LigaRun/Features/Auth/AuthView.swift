import SwiftUI
import Combine

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var activeIndex = 0

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

    init(session: SessionStore) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroSection
                carouselSection
                benefitSection
                formSection
                finalCTA
            }
            .padding(.bottom, 32)
        }
        .background(appBackground)
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                activeIndex = activeIndex >= slides.count - 1 ? 0 : activeIndex + 1
            }
        }
    }

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 6, on: .main, in: .common).autoconnect()
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
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#6366F1").opacity(0.15))
                    .clipShape(Capsule())

                Text("O mapa da cidade virou o seu campo de treino.")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Capture áreas correndo, fortaleça sua bandeira e suba no ranking local em tempo real.")
                    .foregroundColor(.white.opacity(0.75))
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
                .foregroundColor(.white)
                .padding(.horizontal)

            TabView(selection: $activeIndex) {
                ForEach(slides.indices, id: \.self) { index in
                    let slide = slides[index]
                    VStack(alignment: .leading, spacing: 10) {
                        Text(slide.kicker.uppercased())
                            .font(.caption)
                            .foregroundColor(Color(hex: "#34D399"))
                        Text(slide.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text(slide.description)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.75))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slide.stat)
                                .font(.largeTitle.weight(.semibold))
                                .foregroundColor(Color(hex: "#A5B4FC"))
                            Text(slide.statLabel)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
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
                .foregroundColor(.white)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(benefits, id: \.title) { benefit in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(benefit.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Text(benefit.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
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
                .foregroundColor(.white)

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
                .background(Color(hex: "#6366F1"))
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
            .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }

    private var finalCTA: some View {
        VStack(spacing: 8) {
            Text("Pronto para correr com propósito?")
                .font(.headline)
                .foregroundColor(.white)
            Text("Entre no LigaRun e transforme suas rotas em território conquistado.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
            primaryCTA
        }
        .padding(.horizontal)
    }

    // MARK: - Components

    private var appBackground: some View {
        LinearGradient(
            colors: [Color(hex: "#0B0D14"), Color(hex: "#0F1627")],
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
                Color(hex: "#34D399").opacity(0.25),
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
                .background(Color(hex: "#6366F1"))
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
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }

    private func textField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboard)
            .textContentType(keyboard == .emailAddress ? .emailAddress : .username)
            .autocapitalization(.none)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textContentType(.password)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
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

import SwiftUI

struct ActiveRunHUD: View {
    @ObservedObject var runManager: RunManager
    
    // Design System
    private let tealColor = Color(red: 0/255, green: 200/255, blue: 150/255)
    private let accentColor = Color(red: 255/255, green: 107/255, blue: 107/255) // Salmon
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map Background (Simplified)
            Color.gray.opacity(0.1).ignoresSafeArea()
            
            // Notification Pill (Mock)
            VStack {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(tealColor)
                    Text("Approaching [Team Iron] territory - Shield 45%")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Stats Card
            VStack(spacing: 24) {
                // Drag Indicator
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                
                // Main Metrics
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(runManager.formattedDistance)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        Text("DISTANCE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(runManager.formattedPace)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                             .foregroundColor(.black)
                        Text("PACE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 40) {
                    // Loop Widget
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: runManager.loopProgress)
                                .stroke(tealColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: runManager.loopProgress)
                            
                            VStack(spacing: 0) {
                                Text("\(String(format: "%.1f", runManager.distanceBytes / 1000))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                Text("km")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("LOOP PROGRESS")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    // Controls
                    Button(action: {
                        withAnimation {
                            if runManager.state == .running {
                                runManager.pauseRun()
                            } else {
                                runManager.resumeRun()
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(runManager.state == .running ? Color.black : tealColor)
                                .frame(width: 72, height: 72)
                                .shadow(color: (runManager.state == .running ? Color.black : tealColor).opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: runManager.state == .running ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 36)
            }
            .background(Color.white)
            .cornerRadius(32, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

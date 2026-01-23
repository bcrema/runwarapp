import SwiftUI

struct ActiveRunHUD: View {
    @ObservedObject var runManager: RunManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map Background (Simplified)
            Color.gray.opacity(0.1).ignoresSafeArea()
            
            // Notification Pill (Mock)
            VStack {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                    Text("Approaching [Team Iron] territory - Shield 45%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(25)
                .shadow(radius: 5)
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Stats Card
            VStack(spacing: 20) {
                // Drag Indicator
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                
                // Main Metrics
                HStack(spacing: 40) {
                    VStack(alignment: .leading) {
                        Text(runManager.formattedDistance)
                            .font(.system(size: 42, weight: .bold))
                        Text("DISTANCE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(runManager.formattedPace)
                            .font(.system(size: 42, weight: .bold))
                        Text("PACE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 30) {
                    // Loop Widget
                    VStack {
                        Text("LOOP STATUS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: runManager.loopProgress)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: runManager.loopProgress)
                            
                            VStack(spacing: 0) {
                                Text("\(String(format: "%.1f", runManager.distanceBytes / 1000))")
                                    .font(.system(size: 14, weight: .bold))
                                Text("/ 1.2")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text("km")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Controls
                    Button(action: {
                        if runManager.state == .running {
                            runManager.pauseRun()
                        } else {
                            runManager.resumeRun()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                                .shadow(radius: 5)
                            
                            Image(systemName: runManager.state == .running ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color.white)
            .cornerRadius(30)
            .shadow(radius: 10)
        }
    }
}

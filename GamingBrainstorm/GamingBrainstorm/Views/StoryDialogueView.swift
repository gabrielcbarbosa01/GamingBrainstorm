//
//  StoryDialogueView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public struct StoryDialogueView: View {
    @Bindable var session: GameSession
    
    public init(session: GameSession) {
        self.session = session
    }
    
    public var body: some View {
        if session.storyEngine.isDialoguePresented,
           let dialog = session.storyEngine.activeDialogue,
           session.storyEngine.currentDialogueIndex < dialog.count {
            let line = dialog[session.storyEngine.currentDialogueIndex]
            
            ZStack {
                // Dimmed Backdrop
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        #if !TEST_RUNNER
                        SoundManager.shared.playDialogueBeep()
                        #endif
                        session.storyEngine.advanceDialogue()
                    }
                
                VStack {
                    Spacer()
                    
                    // Dialogue Card
                    HStack(alignment: .top, spacing: 18) {
                        // Speaker Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 68, height: 68)
                                .shadow(color: .orange.opacity(0.5), radius: 10)
                            
                            Image(systemName: line.speakerIcon)
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(line.speakerName)
                                    .font(.headline.bold())
                                    .foregroundStyle(.yellow)
                                
                                Text("• \(line.tone)")
                                    .font(.caption.italic())
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                Spacer()
                                
                                Text("\(session.storyEngine.currentDialogueIndex + 1)/\(dialog.count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.white.opacity(0.15)))
                                    .foregroundStyle(.white)
                            }
                            
                            Text(line.text)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(4)
                            
                            HStack {
                                Spacer()
                                Button {
                                    #if !TEST_RUNNER
                                    SoundManager.shared.playDialogueBeep()
                                    #endif
                                    session.storyEngine.advanceDialogue()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(session.storyEngine.currentDialogueIndex + 1 == dialog.count ? "Aceitar Missão" : "Continuar")
                                            .font(.caption.bold())
                                        Image(systemName: "chevron.right.circle.fill")
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Color.accentColor))
                                    .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThickMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.yellow.opacity(0.6), lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    )
                    .frame(maxWidth: 720)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.storyEngine.currentDialogueIndex)
        }
    }
}

// MARK: - Floating Story Quest HUD Overlay
public struct StoryQuestTrackerCard: View {
    @Bindable var session: GameSession
    
    public init(session: GameSession) {
        self.session = session
    }
    
    public var body: some View {
        if let quest = session.storyEngine.currentQuest {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                    Text(quest.title)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                ForEach(quest.objectives) { obj in
                    HStack(spacing: 6) {
                        Image(systemName: obj.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                            .font(.caption2)
                            .foregroundStyle(obj.isCompleted ? .green : .orange)
                        
                        Text(obj.title)
                            .font(.caption2)
                            .foregroundStyle(obj.isCompleted ? .white.opacity(0.6) : .white)
                            .strikethrough(obj.isCompleted)
                            .lineLimit(1)
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.4), lineWidth: 1))
            .frame(width: 260)
        }
    }
}

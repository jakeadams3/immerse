//
//  TermsView.swift
//  immerse
//
//  Created by Jake Adams on 2/8/24.
//

import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Clipzy Terms of Service")
                    .font(.title)
                    .bold()

                Text("Welcome to Clipzy, a leading platform for sharing and engaging with short-form content on the Apple Vision Pro, tailored to visionOS. These Terms of Service (\"Terms\") govern your access to and use of Clipzy's services. By accessing or using Clipzy, you agree to be bound by these Terms.")
                
                Group {
                    Text("1. Agreement to Terms")
                        .font(.headline)
                    
                    Text("By accessing or using Clipzy, you confirm that you accept these Terms and that you agree to comply with them. If you do not agree to these Terms, you must not use our services.")
                }
                
                Group {
                    Text("2. Your Account")
                        .font(.headline)
                    
                    Text("You need an account to use most features of Clipzy. Keep your password confidential, and notify us immediately of any unauthorized use of your account. You are responsible for all activities on your account.")
                }
                
                Group {
                    Text("3. Use of Our Services")
                        .font(.headline)
                    
                    Text("Clipzy allows users to post videos, comment on videos, and interact with other users. You agree to use Clipzy in compliance with all applicable laws, rules, and regulations.")
                }
                
                Group {
                    Text("4. Content on Clipzy")
                        .font(.headline)
                    
                    Text("You are responsible for your content. Do not post content that you do not have the right to post. You grant Clipzy a non-exclusive license to use the content you create.")
                }
                
                Group {
                    Text("5. Prohibited Conduct")
                        .font(.headline)
                    
                    Text("""
                        The following behaviors are prohibited on Clipzy:
                        
                        - Copyright Infringement: Posting content that infringes upon someone else's intellectual property rights is not allowed.
                        - Harassment and Bullying: We do not tolerate harassment, bullying, or intimidation of any kind. This includes posting content meant to degrade, shame, or harm another person.
                        - Hate Speech and Discrimination: Content promoting hate speech, discrimination, or any form of violence against individuals or groups based on race, ethnicity, religion, gender identity, sexual orientation, disability, or any other characteristic is strictly prohibited.
                        - Privacy Violations: Sharing private or confidential information about others without their explicit permission is not allowed. This includes personal data such as phone numbers, email addresses, and home addresses.
                        - Illegal Activities: Content promoting illegal activities is not allowed.
                        """)
                }
                
                Group {
                    Text("6. Intellectual Property")
                        .font(.headline)
                    
                    Text("Clipzy respects the intellectual property rights of others. If your content has been posted on Clipzy without your permission and you want it removed, contact us.")
                }
                
                Group {
                    Text("7. Changes to the Terms")
                        .font(.headline)
                    
                    Text("We reserve the right to modify these Terms at any time. We will notify users of any changes by posting the new Terms on Clipzy. By continuing to access or use our services after those changes become effective, you agree to be bound by the revised Terms.")
                }
                
                Group {
                    Text("8. Termination")
                        .font(.headline)
                    
                    Text("We may terminate or suspend your account if you violate any of these Terms or for any other reason at our sole discretion.")
                }
                
                Group {
                    Text("9. Disclaimers")
                        .font(.headline)
                    
                    Text("Clipzy is provided \"as is,\" and we make no warranties of any kind, express or implied, with respect to our services.")
                }
                
                Group {
                    Text("10. Limitation of Liability")
                        .font(.headline)
                    
                    Text("Clipzy shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of our services.")
                }
                
                Group {
                    Text("11. General Terms")
                        .font(.headline)
                    
                    Text("These Terms constitute the entire agreement between you and Clipzy regarding your use of our services and supersede any prior agreements.")
                }
                
                Group {
                    Text("12. Dispute Resolution")
                        .font(.headline)
                    
                    Text("Any disputes arising from these Terms will be resolved through final and binding arbitration.")
                }
                
                Group {
                    Text("13. Contact Us")
                        .font(.headline)
                    
                    Text("If you have any questions about these Terms, please contact us at ") +
                    Text("clipzyservice@gmail.com")
                        .fontWeight(.bold)
                }
                
                Text("By using Clipzy, you acknowledge that you have read, understood, and agreed to these Terms.")
                    .padding(.top, 20)
                
                Text("Last Updated: Feb. 8, 2024")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

#Preview {
    TermsView()
}

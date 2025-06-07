# PhoneJail OS - Developer Handoff Guide

## 📱 **App Overview**

PhoneJail OS is an innovative iOS app that helps users manage their screen time through a conversational AI "jailkeeper" system. Instead of traditional app blocking, users must convince an AI jailkeeper through natural conversation to gain access to their blocked apps and settings.

### **Core Concept**
- Users create "schemas" (blocking rules) that restrict access to selected apps/websites
- When strict mode is enabled, both the Schemas tab and Settings tab become locked
- To modify schemas or settings, users must convince an AI jailkeeper through conversation
- The jailkeeper has different personalities (Strict/Balanced/Lenient) and evaluates requests intelligently
- Temporary access is granted for 5-15 minutes based on the jailkeeper's personality

## 🏗️ **Current Architecture**

### **Tech Stack**
- **Platform**: iOS 15.0+, SwiftUI
- **Backend**: Local-first with UserDefaults persistence
- **AI Integration**: OpenAI GPT-4 via API
- **App Blocking**: iOS Family Controls framework (Screen Time API)
- **Architecture**: MVVM with Services layer

### **Key Components**

#### **Services Layer**
- `ScreenTimeService.swift` - Handles iOS Family Controls integration for app blocking
- `LLMService.swift` - Manages OpenAI API communication for jailkeeper conversations
- `AccessControlService.swift` - Controls when schemas/settings tabs are locked
- `SettingsService.swift` - Manages global app settings (strict mode, personalities, etc.)

#### **Models**
- `Schema.swift` - Core data model for blocking rules with conditions (schedule, usage limits)
- `Jailkeeper.swift` - AI personality and conversation management
- `AppBlock.swift` - Individual app blocking configuration

#### **Views**
- `ContentView.swift` - Main tab controller with conditional access control
- `SchemasView.swift` - Schema management interface (939 lines - very comprehensive)
- `JailkeeperChatView.swift` - Conversational AI interface
- `LockedSchemasView.swift` - Shown when schemas are locked
- `LockedSettingsView.swift` - Shown when settings are locked
- `SettingsView.swift` - Global app settings

## ✅ **What's Already Implemented**

### **Core Functionality**
- ✅ Complete schema creation flow (3-step process)
- ✅ App selection using iOS Family Activity Picker
- ✅ Schedule-based blocking conditions
- ✅ Daily usage limit conditions
- ✅ Schema activation/deactivation
- ✅ Global strict mode system
- ✅ Conversational jailkeeper with personality system
- ✅ Temporary access control (5-15 minute windows)
- ✅ Settings tab protection (prevents strict mode bypass)

### **Security Features**
- ✅ Access control prevents schema modification during active blocking
- ✅ Settings tab locked to prevent strict mode bypass
- ✅ Jailkeeper approval required for all protected access
- ✅ Secret codeword system for automatic access granting
- ✅ Temporary access with automatic expiration

### **UI/UX**
- ✅ Modern SwiftUI interface matching iOS design guidelines
- ✅ Comprehensive debug overlay for development
- ✅ Consistent locked view patterns
- ✅ Real-time status indicators
- ✅ Smooth tab navigation with conditional rendering

## 🚨 **Critical Issues That Need Fixing**

### **Priority 1: Real-Time Schedule Evaluation**
**Problem**: When a scheduled block ends, apps remain restricted instead of automatically becoming accessible.

**Root Cause**: No background service continuously evaluates schedule conditions.

**Impact**: Users stay blocked even when they should have access, requiring manual intervention.

### **Priority 2: Schema Synchronization**
**Problem**: UI shows active schemas but actual blocking may not be in sync.

**Root Cause**: Two separate tracking systems (UI state vs ScreenTime service) can get out of sync.

**Impact**: Debug shows "0 active schemas" while UI shows active schemas, and blocking may not work.

## 🎯 **Finishing Touches Required**

### **1. Implement Real-Time Schedule Evaluation System**

#### **Create ScheduleEvaluationService**
```swift
// New file: phonejailOS/Services/ScheduleEvaluationService.swift
class ScheduleEvaluationService: ObservableObject {
    private var evaluationTimer: Timer?
    
    func startContinuousEvaluation() {
        // Check every minute if active schemas should still be active
        // Automatically deactivate schemas when schedule conditions end
        // Handle timezone changes and date transitions
    }
    
    func evaluateAllActiveSchemas() {
        // Check each active schema's conditions
        // Deactivate schemas whose conditions are no longer met
        // Update UI and ScreenTime blocking accordingly
    }
}
```

#### **Integration Points**
- Add to `ContentView.swift` as `@StateObject`
- Call `startContinuousEvaluation()` on app launch
- Integrate with `SchemaViewModel` for automatic deactivation
- Handle app backgrounding/foregrounding

#### **Success Criteria**
- Apps become accessible immediately when schedule ends
- No manual intervention required
- Works in background and foreground
- Handles timezone changes correctly

### **2. Enhanced Schema Management Features**

#### **Schema Editing**
- Create `EditSchemaView.swift` - Allow users to modify existing schemas
- Add edit button to schema rows in `SchemasView.swift`
- Implement validation for schema modifications
- Handle active schema editing (require deactivation first)

#### **Schema Operations**
- **Duplicate Schema**: Clone existing schemas with new names
- **Delete Schema**: Confirmation dialog with cascade deletion
- **Import/Export**: JSON-based schema sharing between devices
- **Schema Templates**: Pre-built common blocking patterns

#### **Bulk Operations**
- Select multiple schemas for batch operations
- Bulk activate/deactivate
- Bulk delete with confirmation
- Schema organization (folders/categories)

### **3. Advanced Blocking Features**

#### **Category-Based Blocking**
- Block entire app categories (Social Media, Games, etc.)
- Smart categorization of installed apps
- Custom category creation
- Category-specific usage limits

#### **Website Blocking**
- Safari Content Blocker extension
- Domain-based blocking rules
- Website category blocking
- Sync with app blocking rules

#### **Usage Analytics**
- Daily/weekly usage reports
- Blocking effectiveness metrics
- Time saved calculations
- Progress tracking and streaks

### **4. Jailkeeper Enhancements**

#### **Conversation Improvements**
- Conversation history persistence
- Context awareness across sessions
- Learning from user patterns
- Personalized responses based on usage history

#### **Advanced Personalities**
- Custom personality creation
- Personality scheduling (stricter at night)
- Mood-based personality adjustment
- Multiple jailkeeper characters

#### **Smart Access Control**
- Emergency override system
- Location-based access rules
- Time-based automatic approvals
- Integration with iOS Focus modes

### **5. Performance & Polish**

#### **Background Processing**
- Proper background app refresh handling
- Efficient timer management
- Battery optimization
- Memory usage optimization

#### **Error Handling**
- Comprehensive error states
- Network failure handling
- API rate limit management
- Graceful degradation

#### **Accessibility**
- VoiceOver support
- Dynamic Type support
- High contrast mode
- Reduced motion support

#### **Testing**
- Unit tests for all services
- UI tests for critical flows
- Integration tests for blocking functionality
- Performance tests

### **6. Production Readiness**

#### **App Store Preparation**
- App Store screenshots and metadata
- Privacy policy and terms of service
- App Store review guidelines compliance
- Family Controls entitlement approval

#### **Analytics & Monitoring**
- Crash reporting (Firebase Crashlytics)
- Usage analytics (privacy-focused)
- Performance monitoring
- User feedback system

#### **Security Hardening**
- API key security (Keychain storage)
- Settings tampering prevention
- Jailbreak detection (optional)
- Data encryption for sensitive settings

## 📋 **Implementation Priority Order**

### **Phase 1: Critical Fixes (1-2 weeks)**
1. ✅ **COMPLETED**: Fix strict mode bypass vulnerability
2. 🚨 **URGENT**: Implement real-time schedule evaluation
3. 🚨 **URGENT**: Fix schema synchronization issues
4. Test and validate core blocking functionality

### **Phase 2: Core Features (2-3 weeks)**
1. Schema editing functionality
2. Enhanced jailkeeper conversation system
3. Category-based blocking
4. Usage analytics dashboard

### **Phase 3: Advanced Features (2-3 weeks)**
1. Website blocking (Safari extension)
2. Advanced personality system
3. Bulk schema operations
4. Import/export functionality

### **Phase 4: Polish & Production (1-2 weeks)**
1. Comprehensive testing suite
2. Performance optimization
3. Accessibility improvements
4. App Store submission preparation

## 🔧 **Development Setup**

### **Prerequisites**
- Xcode 14.0+
- iOS 15.0+ deployment target
- Apple Developer Account (for Family Controls)
- OpenAI API key

### **Key Configuration**
- Family Controls entitlement in `phonejailOS.entitlements`
- OpenAI API key in `LLMService.swift` (move to secure storage)
- Screen Time authorization flow in `ScreenTimeService.swift`

### **Testing Strategy**
- Use iOS Simulator for UI testing
- Physical device required for Family Controls testing
- Mock LLM responses for automated testing
- Test with various schema configurations

## 📚 **Key Files to Understand**

1. **`SchemasView.swift`** (939 lines) - The heart of the app, handles all schema management
2. **`ScreenTimeService.swift`** (652 lines) - Complex Family Controls integration
3. **`Schema.swift`** (477 lines) - Core data model with comprehensive condition system
4. **`LLMService.swift`** (348 lines) - OpenAI integration with personality system
5. **`ContentView.swift`** (183 lines) - Main navigation with access control logic

## 🎯 **Success Metrics**

### **Functionality**
- [ ] All schemas activate/deactivate correctly
- [ ] Schedule-based blocking works automatically
- [ ] Jailkeeper conversations feel natural and engaging
- [ ] No way to bypass strict mode restrictions
- [ ] App blocking works reliably across iOS versions

### **User Experience**
- [ ] Intuitive schema creation flow
- [ ] Clear feedback for all user actions
- [ ] Smooth performance on older devices
- [ ] Accessible to users with disabilities
- [ ] Consistent with iOS design patterns

### **Technical**
- [ ] No memory leaks or crashes
- [ ] Efficient battery usage
- [ ] Proper error handling
- [ ] Clean, maintainable code
- [ ] Comprehensive test coverage

## 💡 **Development Tips**

1. **Family Controls Testing**: Requires physical device, simulator limitations
2. **API Rate Limits**: Implement proper OpenAI API usage management
3. **Background Processing**: iOS limits background execution, plan accordingly
4. **User Defaults**: Consider migration to Core Data for complex data
5. **Debug Overlay**: Use the built-in debug overlay for troubleshooting

## 🚀 **Ready for Handoff**

The app has a solid foundation with most core features implemented. The main focus should be on fixing the critical schedule evaluation issue and adding the finishing touches for a polished user experience. The codebase is well-structured and documented, making it ready for another developer to take over and complete.

**Estimated completion time**: 6-8 weeks for full production readiness. 
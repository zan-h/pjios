import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    override func configuration(shielding applications: Set<ApplicationToken>) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.95),
            icon: UIImage(systemName: "lock.fill"),
            title: ShieldConfiguration.Label(text: "App in Phone Jail", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "This app is currently blocked. Speak to the jail keeper if you want access.",
                color: UIColor.white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Contact Jail Keeper",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white.withAlphaComponent(0.8)
            )
        )
    }
    
    override func configuration(shielding webDomains: Set<WebDomainToken>) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.95),
            icon: UIImage(systemName: "globe.slash"),
            title: ShieldConfiguration.Label(text: "Website in Phone Jail", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "This website is currently blocked. Speak to the jail keeper if you want access.",
                color: UIColor.white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Contact Jail Keeper",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white.withAlphaComponent(0.8)
            )
        )
    }
    
    override func configuration(shielding categories: Set<ActivityCategoryToken>) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.95),
            icon: UIImage(systemName: "folder.fill.badge.minus"),
            title: ShieldConfiguration.Label(text: "Category in Phone Jail", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "This app category is currently blocked. Speak to the jail keeper if you want access.",
                color: UIColor.white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Contact Jail Keeper",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white.withAlphaComponent(0.8)
            )
        )
    }
} 
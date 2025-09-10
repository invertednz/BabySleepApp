/**
 * Onboarding Flow Controller
 * Manages the onboarding process for new users
 */

// Onboarding state management
const OnboardingFlow = {
    // Onboarding steps in order
    steps: [
        'mobile-onboarding-baby.html',
        'mobile-onboarding-gender.html',
        'mobile-onboarding-milestones.html',
        'mobile-onboarding-measurements.html',
        'mobile-onboarding-sleep.html',
        'mobile-onboarding-feeding.html',
        'mobile-onboarding-diaper.html',
        'mobile-onboarding-notes.html'
    ],
    
    // Check if user has completed onboarding
    hasCompletedOnboarding() {
        return localStorage.getItem('onboardingCompleted') === 'true';
    },
    
    // Mark onboarding as completed
    completeOnboarding() {
        localStorage.setItem('onboardingCompleted', 'true');
    },
    
    // Get current step index
    getCurrentStepIndex() {
        const currentStep = localStorage.getItem('onboardingCurrentStep');
        return currentStep ? parseInt(currentStep) : 0;
    },
    
    // Save current step index
    saveCurrentStep(index) {
        localStorage.setItem('onboardingCurrentStep', index.toString());
    },
    
    // Get the URL for the next step
    getNextStepUrl() {
        const currentIndex = this.getCurrentStepIndex();
        if (currentIndex < this.steps.length - 1) {
            return this.steps[currentIndex + 1];
        }
        return 'index.html'; // Return to home page after completing all steps
    },
    
    // Get the URL for the previous step
    getPreviousStepUrl() {
        const currentIndex = this.getCurrentStepIndex();
        if (currentIndex > 0) {
            return this.steps[currentIndex - 1];
        }
        return this.steps[0]; // Stay on first step if already there
    },
    
    // Move to the next step
    goToNextStep() {
        const currentIndex = this.getCurrentStepIndex();
        if (currentIndex < this.steps.length - 1) {
            this.saveCurrentStep(currentIndex + 1);
            window.location.href = this.steps[currentIndex + 1];
        } else {
            // Complete onboarding if this is the last step
            this.completeOnboarding();
            window.location.href = 'index.html';
        }
    },
    
    // Move to the previous step
    goToPreviousStep() {
        const currentIndex = this.getCurrentStepIndex();
        if (currentIndex > 0) {
            this.saveCurrentStep(currentIndex - 1);
            window.location.href = this.steps[currentIndex - 1];
        }
    },
    
    // Initialize onboarding flow
    init() {
        // If user hasn't completed onboarding and is not on an onboarding page, redirect to first step
        if (!this.hasCompletedOnboarding()) {
            const currentPath = window.location.pathname;
            const isOnboardingPage = this.steps.some(step => currentPath.includes(step));
            
            if (!isOnboardingPage && !currentPath.includes('login.html') && !currentPath.includes('signup.html')) {
                window.location.href = this.steps[0];
            }
        }
        
        // Update progress bar if on an onboarding page
        this.updateProgressBar();
        
        // Setup navigation buttons
        this.setupNavigationButtons();
    },
    
    // Update the progress bar based on current step
    updateProgressBar() {
        const progressBar = document.querySelector('.progress-bar-fill');
        if (progressBar) {
            const currentIndex = this.getCurrentStepIndex();
            const progressPercentage = ((currentIndex + 1) / this.steps.length) * 100;
            progressBar.style.width = `${progressPercentage}%`;
        }
    },
    
    // Setup navigation button event listeners
    setupNavigationButtons() {
        const nextButton = document.querySelector('.next-button');
        const backButton = document.querySelector('.back-button');
        
        if (nextButton) {
            nextButton.addEventListener('click', () => {
                // Check if this is the last step
                const currentIndex = this.getCurrentStepIndex();
                if (currentIndex === this.steps.length - 1) {
                    this.completeOnboarding();
                }
                this.goToNextStep();
            });
        }
        
        if (backButton) {
            backButton.addEventListener('click', () => {
                this.goToPreviousStep();
            });
        }
    }
};

// Initialize onboarding flow when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    OnboardingFlow.init();
});

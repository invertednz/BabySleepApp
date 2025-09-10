/**
 * Common functionality for all onboarding pages
 */

document.addEventListener('DOMContentLoaded', () => {
    // Update navigation buttons to use the onboarding flow
    const setupNavigationButtons = () => {
        const nextButtons = document.querySelectorAll('.next-button, [onclick*="next"]');
        const backButtons = document.querySelectorAll('.back-button, [onclick*="back"]');
        
        nextButtons.forEach(button => {
            // Remove any existing onclick handlers
            const originalOnClick = button.getAttribute('onclick');
            button.removeAttribute('onclick');
            
            // Add new event listener
            button.addEventListener('click', () => {
                OnboardingFlow.goToNextStep();
            });
        });
        
        backButtons.forEach(button => {
            // Remove any existing onclick handlers
            const originalOnClick = button.getAttribute('onclick');
            button.removeAttribute('onclick');
            
            // Add new event listener
            button.addEventListener('click', () => {
                OnboardingFlow.goToPreviousStep();
            });
        });
    };
    
    // Update progress bar based on current step
    const updateProgressBar = () => {
        const progressBar = document.querySelector('.bg-gradient-to-r.from-\\[\\#E6D7F2\\].to-\\[\\#C8A2C8\\]');
        if (progressBar) {
            const currentIndex = OnboardingFlow.getCurrentStepIndex();
            const progressPercentage = ((currentIndex + 1) / OnboardingFlow.steps.length) * 100;
            progressBar.style.width = `${progressPercentage}%`;
        }
    };
    
    // Initialize
    if (typeof OnboardingFlow !== 'undefined') {
        setupNavigationButtons();
        updateProgressBar();
    }
});

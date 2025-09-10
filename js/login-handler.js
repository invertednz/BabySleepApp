/**
 * Login Handler
 * Manages user authentication and onboarding flow redirection
 */

const LoginHandler = {
    // Check if user is logged in
    isLoggedIn() {
        return localStorage.getItem('userLoggedIn') === 'true';
    },
    
    // Set user as logged in
    setLoggedIn(userData) {
        localStorage.setItem('userLoggedIn', 'true');
        localStorage.setItem('userData', JSON.stringify(userData));
    },
    
    // Handle login form submission
    handleLogin(event) {
        event.preventDefault();
        
        // In a real app, this would validate credentials with a server
        // For demo purposes, we'll just simulate a successful login
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        
        if (email && password) {
            // Simulate successful login
            const userData = {
                email: email,
                name: email.split('@')[0],
                firstLogin: !localStorage.getItem('hasLoggedInBefore')
            };
            
            // Mark that the user has logged in before
            localStorage.setItem('hasLoggedInBefore', 'true');
            
            // Set user as logged in
            this.setLoggedIn(userData);
            
            // Check if onboarding is needed
            if (userData.firstLogin && !OnboardingFlow.hasCompletedOnboarding()) {
                // Reset onboarding to first step
                OnboardingFlow.saveCurrentStep(0);
                // Redirect to first onboarding step
                window.location.href = OnboardingFlow.steps[0];
            } else {
                // Redirect to home page
                window.location.href = 'index.html';
            }
        } else {
            // Show error message
            alert('Please enter both email and password');
        }
    },
    
    // Handle signup form submission
    handleSignup(event) {
        event.preventDefault();
        
        // In a real app, this would create a new user account
        // For demo purposes, we'll just simulate a successful signup
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const confirmPassword = document.getElementById('confirm-password').value;
        
        if (email && password && confirmPassword) {
            if (password !== confirmPassword) {
                alert('Passwords do not match');
                return;
            }
            
            // Simulate successful signup
            const userData = {
                email: email,
                name: email.split('@')[0],
                firstLogin: true
            };
            
            // Set user as logged in
            this.setLoggedIn(userData);
            
            // Always start onboarding for new users
            OnboardingFlow.saveCurrentStep(0);
            
            // Redirect to first onboarding step
            window.location.href = OnboardingFlow.steps[0];
        } else {
            // Show error message
            alert('Please fill in all fields');
        }
    },
    
    // Initialize login/signup handlers
    init() {
        const loginForm = document.getElementById('login-form');
        const signupForm = document.getElementById('signup-form');
        
        if (loginForm) {
            loginForm.addEventListener('submit', (e) => this.handleLogin(e));
        }
        
        if (signupForm) {
            signupForm.addEventListener('submit', (e) => this.handleSignup(e));
        }
        
        // If user is already logged in and has completed onboarding, redirect to home page
        if (this.isLoggedIn() && OnboardingFlow.hasCompletedOnboarding()) {
            const currentPath = window.location.pathname;
            if (currentPath.includes('login.html') || currentPath.includes('signup.html')) {
                window.location.href = 'index.html';
            }
        }
        
        // If user is logged in but hasn't completed onboarding, redirect to current onboarding step
        if (this.isLoggedIn() && !OnboardingFlow.hasCompletedOnboarding()) {
            const currentPath = window.location.pathname;
            if (currentPath.includes('login.html') || currentPath.includes('signup.html')) {
                const currentStepIndex = OnboardingFlow.getCurrentStepIndex();
                window.location.href = OnboardingFlow.steps[currentStepIndex];
            }
        }
    }
};

// Initialize login handler when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    LoginHandler.init();
});

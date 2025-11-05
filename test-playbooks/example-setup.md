# Development Environment Setup

This playbook guides you through setting up the development environment for our project.

## Prerequisites

Before starting, ensure you have:
- Git installed and configured
- Node.js 18 or higher
- Docker Desktop installed
- Access to the repository

## Installation Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/org/repo.git
   cd repo
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Copy environment variables:
   ```bash
   cp .env.example .env
   ```

4. Configure your local environment:
   - Update DATABASE_URL in .env
   - Set API_KEY from the team secrets manager
   - Configure any required service credentials

5. Start the development server:
   ```bash
   npm run dev
   ```

6. Verify the setup:
   - Open http://localhost:3000
   - Run tests: `npm test`
   - Check linting: `npm run lint`

## Troubleshooting

If you encounter issues:
- Clear node_modules and reinstall: `rm -rf node_modules && npm install`
- Verify Docker is running: `docker ps`
- Check Node version: `node --version` (should be 18+)

## Next Steps

After setup:
- Read the CONTRIBUTING.md guide
- Join the team Slack channel
- Attend the onboarding session

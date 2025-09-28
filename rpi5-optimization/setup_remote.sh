#!/bin/bash

# Remote Repository Setup Helper
# Helps set up and push to various Git hosting services

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${WHITE}🚀 RPI5 Optimization Suite - Remote Repository Setup${NC}"
echo "===================================================="
echo ""

# Check if we're in the right directory
if [[ ! -f "VERSION" ]] || [[ ! -f "README.md" ]]; then
    echo -e "${RED}❌ Error: Please run this script from the rpi5-optimization directory${NC}"
    exit 1
fi

# Check current remote status
echo -e "${CYAN}📊 Current Repository Status:${NC}"
echo "• Branch: $(git branch --show-current)"
echo "• Commits: $(git rev-list --count HEAD)"
echo "• Tags: $(git tag | wc -l)"
echo "• Current remotes:"
if git remote -v | grep -q .; then
    git remote -v
else
    echo "  (No remotes configured)"
fi
echo ""

# Service selection
echo -e "${YELLOW}🌐 Select Git Hosting Service:${NC}"
echo "1) GitHub (github.com) - Most popular, free public repos"
echo "2) GitLab (gitlab.com) - Free private repos, CI/CD included"
echo "3) Codeberg (codeberg.org) - Privacy-focused, European"
echo "4) Bitbucket (bitbucket.org) - Atlassian ecosystem"
echo "5) Self-hosted/Local server"
echo "6) Custom URL"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        SERVICE="GitHub"
        BASE_URL="https://github.com"
        echo ""
        echo -e "${BLUE}📝 GitHub Setup Instructions:${NC}"
        echo "1. Go to https://github.com/new"
        echo "2. Repository name: rpi5-optimization"
        echo "3. Description: Ultimate Raspberry Pi 5 Optimization Suite"
        echo "4. Set to Public (recommended)"
        echo "5. DO NOT initialize with README/license (we have them)"
        echo ""
        read -p "Enter your GitHub username: " username
        REPO_URL="$BASE_URL/$username/rpi5-optimization.git"
        ;;
    2)
        SERVICE="GitLab"
        BASE_URL="https://gitlab.com"
        echo ""
        echo -e "${BLUE}📝 GitLab Setup Instructions:${NC}"
        echo "1. Go to https://gitlab.com/projects/new"
        echo "2. Project name: rpi5-optimization"
        echo "3. Description: Ultimate Raspberry Pi 5 Optimization Suite"
        echo "4. Visibility: Public (recommended)"
        echo "5. DO NOT initialize with README"
        echo ""
        read -p "Enter your GitLab username: " username
        REPO_URL="$BASE_URL/$username/rpi5-optimization.git"
        ;;
    3)
        SERVICE="Codeberg"
        BASE_URL="https://codeberg.org"
        echo ""
        echo -e "${BLUE}📝 Codeberg Setup Instructions:${NC}"
        echo "1. Go to https://codeberg.org/repo/create"
        echo "2. Repository name: rpi5-optimization"
        echo "3. Description: Ultimate Raspberry Pi 5 Optimization Suite"
        echo "4. Make it public"
        echo ""
        read -p "Enter your Codeberg username: " username
        REPO_URL="$BASE_URL/$username/rpi5-optimization.git"
        ;;
    4)
        SERVICE="Bitbucket"
        BASE_URL="https://bitbucket.org"
        echo ""
        echo -e "${BLUE}📝 Bitbucket Setup Instructions:${NC}"
        echo "1. Go to https://bitbucket.org/repo/create"
        echo "2. Repository name: rpi5-optimization"
        echo "3. Description: Ultimate Raspberry Pi 5 Optimization Suite"
        echo "4. Make it public"
        echo ""
        read -p "Enter your Bitbucket username: " username
        REPO_URL="https://$username@bitbucket.org/$username/rpi5-optimization.git"
        ;;
    5)
        SERVICE="Self-hosted"
        echo ""
        echo -e "${BLUE}📝 Self-hosted Setup:${NC}"
        echo "Format examples:"
        echo "• SSH: user@server:/path/to/repo.git"
        echo "• Local: /path/to/backup/repo.git"
        echo ""
        read -p "Enter full repository URL/path: " REPO_URL
        ;;
    6)
        SERVICE="Custom"
        echo ""
        read -p "Enter full repository URL: " REPO_URL
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Configuration Summary:${NC}"
echo "• Service: $SERVICE"
echo "• Repository URL: $REPO_URL"
echo ""

# Confirm before proceeding
read -p "Proceed with setup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo -e "${PURPLE}🔧 Setting up remote repository...${NC}"

# Remove existing origin if it exists
if git remote | grep -q "^origin$"; then
    echo "Removing existing origin remote..."
    git remote remove origin
fi

# Add new remote
echo "Adding remote origin..."
if git remote add origin "$REPO_URL"; then
    echo -e "${GREEN}✅ Remote origin added successfully${NC}"
else
    echo -e "${RED}❌ Failed to add remote${NC}"
    exit 1
fi

# Rename branch to main (modern convention)
echo "Setting default branch to main..."
git branch -M main

echo ""
echo -e "${PURPLE}🚀 Pushing to remote repository...${NC}"

# Push main branch
echo "Pushing main branch..."
if git push -u origin main; then
    echo -e "${GREEN}✅ Main branch pushed successfully${NC}"
else
    echo -e "${RED}❌ Failed to push main branch${NC}"
    echo "This might be due to authentication or network issues."
    exit 1
fi

# Push tags
echo "Pushing tags..."
if git push --tags; then
    echo -e "${GREEN}✅ Tags pushed successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Failed to push tags${NC}"
fi

echo ""
echo -e "${WHITE}🎉 SUCCESS! Repository pushed to remote${NC}"
echo "======================================"
echo ""
echo -e "${GREEN}✅ Repository URL: $REPO_URL${NC}"
echo -e "${GREEN}✅ Branch: main${NC}"
echo -e "${GREEN}✅ Tags: $(git tag | wc -l) tags pushed${NC}"
echo ""

echo -e "${CYAN}📋 Next Steps:${NC}"
echo "• Visit your repository online to verify"
echo "• Update repository description and topics"
echo "• Consider adding GitHub/GitLab Pages for documentation"
echo "• Set up issue templates and contributing guidelines"
echo ""

echo -e "${BLUE}🔧 Future Git Commands:${NC}"
echo "• Pull changes: git pull origin main"
echo "• Push changes: git push origin main"
echo "• View remotes: git remote -v"
echo ""

echo "Repository setup complete! 🚀"
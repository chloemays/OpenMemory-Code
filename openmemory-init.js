#!/usr/bin/env node
/**
 * OpenMemory Project Initialization Script
 *
 * Initializes a new project to work with OpenMemory.
 * Creates .openmemory link file and registers the project.
 *
 * Usage:
 *   node openmemory-init.js [project-directory]
 */

const fs = require('fs');
const path = require('path');
const { homedir } = require('os');
const { execSync } = require('child_process');

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function ensureGlobalDir() {
  const globalDir = path.join(homedir(), '.openmemory-global');

  if (!fs.existsSync(globalDir)) {
    log('Creating global OpenMemory directory...', colors.blue);
    fs.mkdirSync(globalDir, { recursive: true });
    fs.mkdirSync(path.join(globalDir, 'projects'), { recursive: true });

    // Create registry file
    const registryPath = path.join(globalDir, 'projects', 'registry.json');
    const registry = {
      version: '1.0',
      projects: {},
      created: new Date().toISOString(),
      updated: new Date().toISOString(),
    };
    fs.writeFileSync(registryPath, JSON.stringify(registry, null, 2));

    log('✅ Global directory created', colors.green);
  }

  return globalDir;
}

function loadRegistry(globalDir) {
  const registryPath = path.join(globalDir, 'projects', 'registry.json');

  if (!fs.existsSync(registryPath)) {
    return {
      version: '1.0',
      projects: {},
      created: new Date().toISOString(),
      updated: new Date().toISOString(),
    };
  }

  return JSON.parse(fs.readFileSync(registryPath, 'utf-8'));
}

function saveRegistry(globalDir, registry) {
  const registryPath = path.join(globalDir, 'projects', 'registry.json');
  registry.updated = new Date().toISOString();
  fs.writeFileSync(registryPath, JSON.stringify(registry, null, 2));
}

function copyDirectoryRecursive(source, target) {
  if (!fs.existsSync(target)) {
    fs.mkdirSync(target, { recursive: true });
  }

  const files = fs.readdirSync(source);

  for (const file of files) {
    const sourcePath = path.join(source, file);
    const targetPath = path.join(target, file);
    const stat = fs.statSync(sourcePath);

    if (stat.isDirectory()) {
      copyDirectoryRecursive(sourcePath, targetPath);
    } else {
      fs.copyFileSync(sourcePath, targetPath);
      // Preserve executable permissions for shell scripts
      if (file.endsWith('.sh')) {
        try {
          fs.chmodSync(targetPath, 0o755);
        } catch (e) {
          // Ignore chmod errors on Windows
        }
      }
    }
  }
}

function initializeProject(projectDir) {
  // Ensure absolute path
  projectDir = path.resolve(projectDir);

  log(`\nInitializing OpenMemory for: ${projectDir}`, colors.blue);

  // Get project name from directory
  const projectName = path.basename(projectDir);

  // Ensure global directory exists
  const globalDir = ensureGlobalDir();

  // Load registry
  const registry = loadRegistry(globalDir);

  // Check if already registered
  if (registry.projects[projectName]) {
    log(`⚠️  Project "${projectName}" is already registered`, colors.yellow);
    log(`   Path: ${registry.projects[projectName].path}`, colors.yellow);

    // Check if it's the same path
    if (registry.projects[projectName].path === projectDir) {
      log('   Skipping registration (same path)', colors.yellow);
    } else {
      log('   WARNING: Different path! Please use a unique project name.', colors.red);
      return false;
    }
  } else {
    // Register project
    registry.projects[projectName] = {
      name: projectName,
      path: projectDir,
      created: new Date().toISOString(),
      initialized: new Date().toISOString(),
    };
    saveRegistry(globalDir, registry);
    log(`✅ Project registered: ${projectName}`, colors.green);
  }

  // Create .openmemory link file
  const linkFilePath = path.join(projectDir, '.openmemory');
  const linkFileContent = `GLOBAL_DIR=${globalDir}
PROJECT_NAME=${projectName}
OPENMEMORY_URL=http://localhost:8080
`;

  if (fs.existsSync(linkFilePath)) {
    log('⚠️  .openmemory file already exists', colors.yellow);
  } else {
    fs.writeFileSync(linkFilePath, linkFileContent);
    log('✅ Created .openmemory link file', colors.green);
  }

  // Create .gitignore entry (if .gitignore exists)
  const gitignorePath = path.join(projectDir, '.gitignore');
  if (fs.existsSync(gitignorePath)) {
    const gitignore = fs.readFileSync(gitignorePath, 'utf-8');
    if (!gitignore.includes('.openmemory')) {
      fs.appendFileSync(gitignorePath, '\n# OpenMemory\n.openmemory\n');
      log('✅ Added .openmemory to .gitignore', colors.green);
    }
  }

  // Create .ai-agents directory structure
  const aiAgentsDir = path.join(projectDir, '.ai-agents');
  const enforcementDir = path.join(aiAgentsDir, 'enforcement');
  const gitHooksDir = path.join(enforcementDir, 'git-hooks');

  if (!fs.existsSync(aiAgentsDir)) {
    fs.mkdirSync(aiAgentsDir, { recursive: true });
    log('✅ Created .ai-agents directory', colors.green);
  }

  // Get OpenMemory-Code root (where this script is located)
  const openMemoryRoot = __dirname;
  const sourceAIAgentsDir = path.join(openMemoryRoot, '.ai-agents');

  // Copy essential files
  const filesToCopy = [
    'config.json',
    'enforcement-status.json',
    'TEMPLATE_agent-roles.json',
    'TEMPLATE_project-state.json',
    'TEMPLATE_workflow-tracker.json',
    'TEMPLATE_context-manager.json'
  ];

  for (const file of filesToCopy) {
    const sourcePath = path.join(sourceAIAgentsDir, file);
    const targetPath = path.join(aiAgentsDir, file.replace('TEMPLATE_', ''));

    if (fs.existsSync(sourcePath) && !fs.existsSync(targetPath)) {
      const content = fs.readFileSync(sourcePath, 'utf-8');

      // Replace template values
      const updatedContent = content
        .replace(/TEMPLATE_Your_Project_Name/g, projectName)
        .replace(/testagain/g, projectName)
        .replace(/YYYY-MM-DDTHH:MM:SSZ/g, new Date().toISOString());

      fs.writeFileSync(targetPath, updatedContent);
      log(`✅ Created ${file.replace('TEMPLATE_', '')}`, colors.green);
    }
  }

  // Copy enforcement directory
  if (fs.existsSync(path.join(sourceAIAgentsDir, 'enforcement'))) {
    if (!fs.existsSync(enforcementDir)) {
      copyDirectoryRecursive(path.join(sourceAIAgentsDir, 'enforcement'), enforcementDir);
      log('✅ Copied enforcement system', colors.green);
    }
  }

  // Install git hooks if this is a git repository
  const gitDir = path.join(projectDir, '.git');
  if (fs.existsSync(gitDir)) {
    try {
      log('Installing git hooks for enforcement...', colors.blue);

      const installScript = path.join(gitHooksDir, 'install-hooks.sh');

      if (fs.existsSync(installScript)) {
        // Make script executable
        fs.chmodSync(installScript, 0o755);

        // Run install script
        const result = execSync(`bash "${installScript}" "${projectDir}"`, {
          cwd: projectDir,
          encoding: 'utf-8'
        });

        log('✅ Git hooks installed successfully', colors.green);
      } else {
        log('⚠️  Git hook installation script not found', colors.yellow);
      }
    } catch (error) {
      log('⚠️  Failed to install git hooks (you can install manually later)', colors.yellow);
      log(`   Error: ${error.message}`, colors.red);
    }
  } else {
    log('⚠️  Not a git repository - git hooks not installed', colors.yellow);
    log('   Initialize git first: git init', colors.cyan);
  }

  // Success message
  console.log('');
  log('═'.repeat(70), colors.green);
  log('✅ Project initialized successfully!', colors.green);
  log('═'.repeat(70), colors.green);
  console.log('');
  log('Project Details:', colors.blue);
  log(`  Name: ${projectName}`, colors.cyan);
  log(`  Path: ${projectDir}`, colors.cyan);
  log(`  Global Dir: ${globalDir}`, colors.cyan);
  console.log('');
  log('Next Steps:', colors.blue);
  log('  1. Ensure OpenMemory backend is running:', colors.cyan);
  log('     npm start', colors.green);
  log('  2. Start coding in your project!', colors.cyan);
  log('  3. Your AI assistant will automatically use OpenMemory context', colors.cyan);
  console.log('');
  log('🔒 Enforcement Enabled:', colors.blue);
  log('  • Git hooks will validate all commits', colors.cyan);
  log('  • AI agents must record actions in OpenMemory', colors.cyan);
  log('  • Project state tracked automatically', colors.cyan);
  log('  • Cannot bypass without logging', colors.cyan);
  console.log('');

  return true;
}

function main() {
  // Get project directory from args or use current directory
  const projectDir = process.argv[2] || process.cwd();

  // Check if directory exists
  if (!fs.existsSync(projectDir)) {
    log(`❌ Directory does not exist: ${projectDir}`, colors.red);
    log('Creating directory...', colors.yellow);
    fs.mkdirSync(projectDir, { recursive: true });
  }

  // Initialize project
  const success = initializeProject(projectDir);

  if (!success) {
    process.exit(1);
  }
}

main();

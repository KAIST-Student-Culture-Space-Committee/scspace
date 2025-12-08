module.exports = {
  apps: [{
    name: 'scspace-server',
    script: 'pnpm',
    args: 'run start',
    watch: true,
    ignore_watch: ['node_modules', 'dist', '.git'],
    env_file: '.env'
  }],
};

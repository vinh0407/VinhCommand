import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import path from 'path';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@vinhcommand/shared': path.resolve(__dirname, '../../packages/shared/src'),
      '@vinhcommand/ui-core': path.resolve(__dirname, '../../packages/ui-core/src'),
      '@vinhcommand/api-client': path.resolve(__dirname, '../../packages/api-client/src'),
    },
  },
  build: {
    target: 'es2022',
    outDir: 'dist',
    sourcemap: true,
  },
  server: {
    port: 1420,
    strictPort: true,
  },
});
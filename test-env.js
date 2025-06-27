import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

console.log('Environment Variables Test:');
console.log('==========================');
console.log('TELEGRAM_BOT_TOKEN:', process.env.TELEGRAM_BOT_TOKEN ? '✅ Set' : '❌ Not set');
console.log('TELEGRAM_CHAT_ID:', process.env.TELEGRAM_CHAT_ID ? '✅ Set' : '❌ Not set');

if (process.env.TELEGRAM_BOT_TOKEN) {
  console.log('Bot Token (first 10 chars):', process.env.TELEGRAM_BOT_TOKEN.substring(0, 10) + '...');
}
if (process.env.TELEGRAM_CHAT_ID) {
  console.log('Chat ID:', process.env.TELEGRAM_CHAT_ID);
}

console.log('\nAll environment variables:');
console.log(process.env); 